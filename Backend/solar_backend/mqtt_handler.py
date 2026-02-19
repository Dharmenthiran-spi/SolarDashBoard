import json
import logging
import asyncio
from typing import Optional, List, Dict
from aiomqtt import Client, Message, MqttError
from sqlalchemy import select, update
from redis.asyncio import Redis

from .database import AsyncSessionLocal
from .models.machine import Machine
from .models.machine_status import MachineStatus
from .routes.realtime import manager

logger = logging.getLogger(__name__)

class MQTTHandler:
    def __init__(self, broker: str, port: int, username: Optional[str] = None, 
                 password: Optional[str] = None, use_tls: bool = False,
                 redis_client: Optional[Redis] = None):
        self.broker = broker
        self.port = port
        self.username = username
        self.password = password
        self.use_tls = use_tls
        self.client: Optional[Client] = None
        self.redis = redis_client

    async def start(self):
        while True:
            try:
                async with Client(
                    hostname=self.broker,
                    port=self.port,
                    username=self.username,
                    password=self.password,
                ) as client:
                    self.client = client
                    logger.info("Connected to MQTT Broker (Optimized)")
                    await client.subscribe("company/+/machine/+/telemetry")
                    await client.subscribe("company/+/machine/+/status")
                    async for message in client.messages:
                        await self.handle_message(message)
            except MqttError as e:
                logger.error(f"MQTT Error: {e}. Retrying in 5 seconds...")
                await asyncio.sleep(5)
            except Exception as e:
                logger.error(f"Unexpected MQTT Error: {e}")
                await asyncio.sleep(5)

    async def handle_message(self, message: Message):
        topic_parts = message.topic.value.split('/')
        if len(topic_parts) < 5: return

        cid, serial, msg_type = topic_parts[1], topic_parts[3], topic_parts[4]

        try:
            payload = json.loads(message.payload.decode())
            
            # Find MachineID from Redis or DB
            machine_id = await self.get_machine_id(serial)
            if not machine_id: return

            if msg_type == "telemetry":
                await self.process_telemetry(machine_id, int(cid), payload)
            elif msg_type == "status":
                await self.process_status(machine_id, int(cid), payload)
                
        except Exception as e:
            logger.error(f"Error handling message on {message.topic}: {e}")

    async def get_machine_id(self, serial: str) -> Optional[int]:
        """Get Machine TableID from Redis Cache or MySQL."""
        cache_key = f"machine:serial:{serial}"
        if self.redis:
            cached = await self.redis.get(cache_key)
            if cached: return int(cached)

        async with AsyncSessionLocal() as db:
            stmt = select(Machine.TableID).filter(Machine.SerialNo == serial)
            result = await db.execute(stmt)
            tid = result.scalar_one_or_none()
            if tid and self.redis:
                await self.redis.set(cache_key, tid, ex=3600) # Cache for 1 hour
            return tid

    async def process_telemetry(self, machine_id: int, company_id: int, payload: dict):
        # 1. Delta Detection via Redis
        changed_fields = {}
        if self.redis:
            state_key = f"machine:state:{machine_id}"
            old_state = await self.redis.hgetall(state_key) or {}
            
            for k, v in payload.items():
                if str(v) != old_state.get(k):
                    changed_fields[k] = v
            
            if changed_fields:
                await self.redis.hset(state_key, mapping={k: str(v) for k, v in payload.items()})
        else:
            changed_fields = payload # Fallback if Redis is down

        # 2. Targeted Broadcast (Only changed fields)
        if changed_fields:
            update_msg = {"type": "telemetry", "machine_id": machine_id, "data": changed_fields}
            asyncio.create_task(manager.broadcast_to_machine(machine_id, update_msg))
            asyncio.create_task(manager.broadcast_to_company(company_id, update_msg))

    async def process_status(self, machine_id: int, company_id: int, payload: dict):
        status_str = payload.get("status", "Online")
        
        # In-memory/Redis update first
        if self.redis:
            await self.redis.hset(f"machine:state:{machine_id}", "status", status_str)

        # Batch update machine status in DB (Non-blocking)
        async def update_db():
            async with AsyncSessionLocal() as db:
                await db.execute(
                    update(MachineStatus)
                    .where(MachineStatus.MachineID == machine_id)
                    .values(
                        Status=status_str,
                        EnergyValue=payload.get("energy", 0.0),
                        WaterValue=payload.get("water", 0.0),
                        AreaValue=payload.get("area", 0.0)
                    )
                )
                await db.execute(
                    update(Machine)
                    .where(Machine.TableID == machine_id)
                    .values(IsOnline=1 if status_str.lower() != "offline" else 0)
                )
                await db.commit()
        
        asyncio.create_task(update_db())

        # Broadcast always for status changes
        update_msg = {"type": "status", "machine_id": machine_id, "data": payload}
        asyncio.create_task(manager.broadcast_to_machine(machine_id, update_msg))
        asyncio.create_task(manager.broadcast_to_company(company_id, update_msg))

    async def publish_command(self, company_id: int, machine_serial: str, command: dict):
        if not self.client: return
        topic = f"company/{company_id}/machine/{machine_serial}/command"
        await self.client.publish(topic, json.dumps(command))
