import json
import logging
import asyncio
from typing import Optional, List, Dict
from aiomqtt import Client, Message, MqttError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import redis.asyncio as redis

from .database import AsyncSessionLocal
from .models.machine import Machine
from .models.telemetry import Telemetry
from .models.machine_status import MachineStatus
from .routes.realtime import manager
from .config import settings

logger = logging.getLogger(__name__)

class MQTTHandler:
    def __init__(self, broker: str, port: int, username: Optional[str] = None, password: Optional[str] = None, use_tls: bool = False):
        self.broker = broker
        self.port = port
        self.username = username
        self.password = password
        self.use_tls = use_tls
        self.client: Optional[Client] = None
        self.redis_client = redis.Redis(host=settings.REDIS_HOST, port=settings.REDIS_PORT, decode_responses=True)
        
        # Batching state
        self.telemetry_buffer: List[Telemetry] = []
        self.buffer_lock = asyncio.Lock()
        self.flush_interval = 5  # seconds

    async def start(self):
        # Start the telemetry batch flusher
        asyncio.create_task(self.telemetry_flusher())
        
        while True:
            try:
                async with Client(
                    hostname=self.broker,
                    port=self.port,
                    username=self.username,
                    password=self.password,
                ) as client:
                    self.client = client
                    logger.info("Connected to MQTT Broker")
                    
                    # Subscribe to telemetry and status
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

    async def telemetry_flusher(self):
        """Periodically flushes the telemetry buffer to MySQL in batches."""
        while True:
            await asyncio.sleep(self.flush_interval)
            try:
                async with self.buffer_lock:
                    if not self.telemetry_buffer:
                        continue
                    to_save = self.telemetry_buffer
                    self.telemetry_buffer = []

                async with AsyncSessionLocal() as db:
                    db.add_all(to_save)
                    await db.commit()
                    logger.info(f"💾 Batched {len(to_save)} telemetry records to DB")
            except Exception as e:
                logger.error(f"Batch insert error: {e}")

    async def handle_message(self, message: Message):
        topic_parts = message.topic.value.split('/')
        if len(topic_parts) < 5:
            return

        try:
            company_id = int(topic_parts[1])
            machine_serial = topic_parts[3]
            msg_type = topic_parts[4]
            
            payload = json.loads(message.payload.decode())
            
            # Use Redis to find MachineID by SerialNo (Caching to avoid redundant DB lookups)
            redis_machine_key = f"machine_map:{machine_serial}"
            machine_id_str = await self.redis_client.get(redis_machine_key)
            
            if machine_id_str:
                machine_id = int(machine_id_str)
            else:
                # Fallback to DB if not in Redis
                async with AsyncSessionLocal() as db:
                    stmt = select(Machine).filter(Machine.SerialNo == machine_serial)
                    result = await db.execute(stmt)
                    machine = result.scalar_one_or_none()
                    if not machine:
                        logger.warning(f"Machine with SerialNo {machine_serial} not found")
                        return
                    machine_id = machine.TableID
                    # Cache the mapping for 1 hour
                    await self.redis_client.setex(redis_machine_key, 3600, str(machine_id))

            # Cache latest state in Redis and identify diff for WebSocket
            redis_state_key = f"machine_state:{machine_id}"
            cached_state_raw = await self.redis_client.get(redis_state_key)
            cached_state = json.loads(cached_state_raw) if cached_state_raw else {}

            # Calculate change (Delta) - Only broadcast what changed
            delta = {}
            for k, v in payload.items():
                if isinstance(v, dict): # Handle 'extra' or 'position'
                    cached_v = cached_state.get(k, {})
                    sub_delta = {sk: sv for sk, sv in v.items() if sv != cached_v.get(sk)}
                    if sub_delta:
                        delta[k] = sub_delta
                elif v != cached_state.get(k):
                    delta[k] = v

            # Update Redis with merged state
            cached_state.update(payload)
            await self.redis_client.set(redis_state_key, json.dumps(cached_state))

            # Broadcast ONLY the delta if there's a change
            if delta:
                update_msg = {"type": msg_type, "machine_id": machine_id, "data": delta}
                asyncio.create_task(manager.broadcast_to_machine(machine_id, update_msg))
                asyncio.create_task(manager.broadcast_to_company(company_id, update_msg))

            if msg_type == "telemetry":
                await self.queue_telemetry(machine_id, payload)
            elif msg_type == "status":
                # Asynchronously update status in DB to maintain dashboard persistence
                asyncio.create_task(self.update_status_db(machine_id, payload))

        except Exception as e:
            logger.error(f"Error handling MQTT message: {e}")

    async def queue_telemetry(self, machine_id: int, payload: dict):
        """Queues telemetry to memory buffer for batch processing."""
        telemetry = Telemetry(
            MachineID=machine_id,
            BatteryLevel=payload.get("battery"),
            SolarVoltage=payload.get("solar_v"),
            SolarCurrent=payload.get("solar_a"),
            WaterLevel=payload.get("water"),
            AdditionalData=payload.get("extra")
        )
        async with self.buffer_lock:
            self.telemetry_buffer.append(telemetry)

    async def update_status_db(self, machine_id: int, payload: dict):
        """Asynchronously update the status record in MySQL."""
        try:
            async with AsyncSessionLocal() as db:
                stmt = select(MachineStatus).filter(MachineStatus.MachineID == machine_id)
                res = await db.execute(stmt)
                status_entry = res.scalar_one_or_none()
                
                status_str = payload.get("status")
                if status_entry:
                    if status_str: status_entry.Status = status_str
                    status_entry.EnergyValue = payload.get("energy", status_entry.EnergyValue)
                    status_entry.WaterValue = payload.get("water", status_entry.WaterValue)
                    status_entry.AreaValue = payload.get("area", status_entry.AreaValue)
                else:
                    db.add(MachineStatus(
                        MachineID=machine_id,
                        Status=status_str or "Online",
                        EnergyValue=payload.get("energy", 0.0),
                        WaterValue=payload.get("water", 0.0),
                        AreaValue=payload.get("area", 0.0)
                    ))
                
                # Update Machine.IsOnline
                if status_str:
                    m_stmt = select(Machine).filter(Machine.TableID == machine_id)
                    m_res = await db.execute(m_stmt)
                    machine = m_res.scalar_one_or_none()
                    if machine:
                        machine.IsOnline = 1 if status_str.lower() != "offline" else 0
                
                await db.commit()
        except Exception as e:
            logger.error(f"Failed to update status in DB: {e}")

    async def publish_command(self, company_id: int, machine_serial: str, command: dict):
        if not self.client:
            logger.error("MQTT client not connected")
            return
        topic = f"company/{company_id}/machine/{machine_serial}/command"
        await self.client.publish(topic, json.dumps(command))
        logger.info(f"Published command to {topic}")
