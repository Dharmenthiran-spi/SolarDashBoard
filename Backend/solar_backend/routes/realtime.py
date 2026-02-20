import asyncio
import json
import logging
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from typing import List, Dict

router = APIRouter(
    prefix="/realtime",
    tags=["Realtime"]
)

logger = logging.getLogger(__name__)

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[int, List[WebSocket]] = {} # machine_id -> list of websockets
        self.company_connections: Dict[int, List[WebSocket]] = {} # company_id -> list of websockets

    async def connect(self, websocket: WebSocket, machine_id: int):
        try:
            logger.info(f"WS: Received connection request for machine {machine_id}")
            await websocket.accept()
            if machine_id not in self.active_connections:
                self.active_connections[machine_id] = []
            self.active_connections[machine_id].append(websocket)
            logger.info(f"WS: Handshake successful for machine {machine_id}")
        except Exception as e:
            logger.error(f"WS ERROR: Handshake failed for machine {machine_id}: {e}")

    async def connect_company(self, websocket: WebSocket, company_id: int):
        try:
            logger.info(f"WS: Received connection request for company {company_id}")
            await websocket.accept()
            if company_id not in self.company_connections:
                self.company_connections[company_id] = []
            self.company_connections[company_id].append(websocket)
            logger.info(f"WS: Handshake successful for company {company_id}")
        except Exception as e:
            logger.error(f"WS ERROR: Handshake failed for company {company_id}: {e}")

    def disconnect(self, websocket: WebSocket, machine_id: int):
        if machine_id in self.active_connections:
            if websocket in self.active_connections[machine_id]:
                self.active_connections[machine_id].remove(websocket)
            if not self.active_connections[machine_id]:
                self.active_connections.pop(machine_id, None)
        logger.info(f"WS: Disconnected machine {machine_id}")

    def disconnect_company(self, websocket: WebSocket, company_id: int):
        if company_id in self.company_connections:
            if websocket in self.company_connections[company_id]:
                self.company_connections[company_id].remove(websocket)
            if not self.company_connections[company_id]:
                self.company_connections.pop(company_id, None)
        logger.info(f"WS: Disconnected company {company_id}")

    async def _send_with_cleanup(self, websocket: WebSocket, message_str: str, target_id: int, is_company: bool):
        try:
            await websocket.send_text(message_str)
        except Exception:
            # Proactively remove dead connections
            if is_company:
                self.disconnect_company(websocket, target_id)
            else:
                self.disconnect(websocket, target_id)

    async def broadcast_to_machine(self, machine_id: int, message: dict):
        if machine_id in self.active_connections:
            message_str = json.dumps(message)
            tasks = [self._send_with_cleanup(conn, message_str, machine_id, False) for conn in self.active_connections[machine_id]]
            if tasks:
                await asyncio.gather(*tasks, return_exceptions=True)

    async def broadcast_to_company(self, company_id: int, message: dict):
        if company_id in self.company_connections:
            message_str = json.dumps(message)
            tasks = [self._send_with_cleanup(conn, message_str, company_id, True) for conn in self.company_connections[company_id]]
            if tasks:
                await asyncio.gather(*tasks, return_exceptions=True)

manager = ConnectionManager()

@router.websocket("/company/{company_id}")
async def websocket_company_endpoint(websocket: WebSocket, company_id: int):
    await manager.connect_company(websocket, company_id)
    
    # Start Heartbeat
    heartbeat_task = asyncio.create_task(keep_alive(websocket))
    
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect_company(websocket, company_id)
        heartbeat_task.cancel()

@router.websocket("/{machine_id}")
async def websocket_endpoint(websocket: WebSocket, machine_id: int):
    await manager.connect(websocket, machine_id)
    
    # Start Heartbeat
    heartbeat_task = asyncio.create_task(keep_alive(websocket))
    
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket, machine_id)
        heartbeat_task.cancel()

async def keep_alive(websocket: WebSocket):
    """Sends a ping every 5 seconds to keep the connection alive."""
    try:
        while True:
            await asyncio.sleep(5)
            await websocket.send_text(json.dumps({"type": "heartbeat"}))
    except Exception:
        pass
