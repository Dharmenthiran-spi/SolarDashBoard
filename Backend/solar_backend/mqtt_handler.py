import json
import logging
import asyncio
from typing import Optional
from aiomqtt import Client, Message, MqttError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from .database import AsyncSessionLocal
from .models.machine import Machine
from .models.telemetry import Telemetry
from .models.machine_status import MachineStatus
from .routes.realtime import manager

logger = logging.getLogger(__name__)

class MQTTHandler:
    def __init__(self, broker: str, port: int, username: Optional[str] = None, password: Optional[str] = None, use_tls: bool = False):
        self.broker = broker
        self.port = port
        self.username = username
        self.password = password
        self.use_tls = use_tls
        self.client: Optional[Client] = None

    async def start(self):
        while True:
            try:
                async with Client(
                    hostname=self.broker,
                    port=self.port,
                    username=self.username,
                    password=self.password,
                    # tls_context=... (to be added with TLS guide)
                ) as client:
                    self.client = client
                    logger.info("Connected to MQTT Broker")
                    
                    # Subscribe to telemetry, status, and LWT
                    await client.subscribe("company/+/machine/+/telemetry")
                    await client.subscribe("company/+/machine/+/status")
                    
                    async for message in client.messages:
                        await self.handle_message(message)
            except MqttError as e:
                logger.error(f"MQTT Error: {e}. Retrying in 5 seconds...")
                await asyncio.sleep(5)
            except Exception as e:
                logger.error(f"Unexpected MQTT Error: {e}. Retrying in 5 seconds...")
                await asyncio.sleep(5)

    async def handle_message(self, message: Message):
        topic_parts = message.topic.value.split('/')
        if len(topic_parts) < 5:
            return

        company_id = topic_parts[1]
        machine_serial = topic_parts[3] # We'll use SerialNo as machine identifier in topics
        msg_type = topic_parts[4]

        try:
            payload = json.loads(message.payload.decode())
            async with AsyncSessionLocal() as db:
                # Find machine by SerialNo
                stmt = select(Machine).filter(Machine.SerialNo == machine_serial)
                result = await db.execute(stmt)
                machine = result.scalar_one_or_none()
                
                if not machine:
                    logger.warning(f"Machine with SerialNo {machine_serial} not found")
                    return

                if msg_type == "telemetry":
                    await self.process_telemetry(db, machine.TableID, company_id, payload)
                elif msg_type == "status":
                    await self.process_status(db, machine.TableID, company_id, payload)
                
                await db.commit()
        except Exception as e:
            logger.error(f"Error handling MQTT message: {e}")

    async def process_telemetry(self, db: AsyncSession, machine_id: int, company_id: str, payload: dict):
        new_telemetry = Telemetry(
            MachineID=machine_id,
            BatteryLevel=payload.get("battery"),
            SolarVoltage=payload.get("solar_v"),
            SolarCurrent=payload.get("solar_a"),
            WaterLevel=payload.get("water"),
            AdditionalData=payload.get("extra")
        )
        db.add(new_telemetry)
        
        # Broadcast to specific machine and entire company
        update_msg = {"type": "telemetry", "machine_id": machine_id, "data": payload}
        await manager.broadcast_to_machine(machine_id, update_msg)
        try:
            await manager.broadcast_to_company(int(company_id), update_msg)
        except Exception:
            pass
        
        logger.info(f"Stored telemetry for machine {machine_id}")

    async def process_status(self, db: AsyncSession, machine_id: int, company_id: str, payload: dict):
        # Update MachineStatus (Live state)
        stmt = select(MachineStatus).filter(MachineStatus.MachineID == machine_id)
        result = await db.execute(stmt)
        status_entry = result.scalar_one_or_none()

        status_str = payload.get("status", "Online")
        
        if status_entry:
            status_entry.Status = status_str
            status_entry.EnergyValue = payload.get("energy", status_entry.EnergyValue)
            status_entry.WaterValue = payload.get("water", status_entry.WaterValue)
            status_entry.AreaValue = payload.get("area", status_entry.AreaValue)
        else:
            status_entry = MachineStatus(
                MachineID=machine_id,
                Status=status_str,
                EnergyValue=payload.get("energy", 0.0),
                WaterValue=payload.get("water", 0.0),
                AreaValue=payload.get("area", 0.0)
            )
            db.add(status_entry)

        # Also update Machine.IsOnline
        stmt = select(Machine).filter(Machine.TableID == machine_id)
        res = await db.execute(stmt)
        machine = res.scalar_one_or_none()
        if machine:
            machine.IsOnline = 1 if status_str.lower() != "offline" else 0

        # Broadcast to specific machine and entire company
        update_msg = {"type": "status", "machine_id": machine_id, "data": payload}
        await manager.broadcast_to_machine(machine_id, update_msg)
        try:
            await manager.broadcast_to_company(int(company_id), update_msg)
        except Exception:
            pass
            
        logger.info(f"Updated status for machine {machine_id}")

    async def publish_command(self, company_id: int, machine_serial: str, command: dict):
        if not self.client:
            logger.error("MQTT client not connected")
            return
        
        topic = f"company/{company_id}/machine/{machine_serial}/command"
        await self.client.publish(topic, json.dumps(command))
        logger.info(f"Published command to {topic}")
