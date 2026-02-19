import asyncio
import json
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from typing import List, Dict

router = APIRouter(
    prefix="/realtime",
    tags=["Realtime"]
)

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[int, List[WebSocket]] = {} # machine_id -> list of websockets
        self.company_connections: Dict[int, List[WebSocket]] = {} # company_id -> list of websockets

    async def connect(self, websocket: WebSocket, machine_id: int):
        await websocket.accept()
        if machine_id not in self.active_connections:
            self.active_connections[machine_id] = []
        self.active_connections[machine_id].append(websocket)

    async def connect_company(self, websocket: WebSocket, company_id: int):
        await websocket.accept()
        if company_id not in self.company_connections:
            self.company_connections[company_id] = []
        self.company_connections[company_id].append(websocket)

    def disconnect(self, websocket: WebSocket, machine_id: int):
        if machine_id in self.active_connections:
            if websocket in self.active_connections[machine_id]:
                self.active_connections[machine_id].remove(websocket)
            if not self.active_connections[machine_id]:
                self.active_connections.pop(machine_id, None)

    def disconnect_company(self, websocket: WebSocket, company_id: int):
        if company_id in self.company_connections:
            if websocket in self.company_connections[company_id]:
                self.company_connections[company_id].remove(websocket)
            if not self.company_connections[company_id]:
                self.company_connections.pop(company_id, None)

    async def broadcast_to_machine(self, machine_id: int, message: dict):
        if machine_id in self.active_connections:
            message_str = json.dumps(message)
            for connection in self.active_connections[machine_id]:
                try:
                    await connection.send_text(message_str)
                except Exception:
                    pass

    async def broadcast_to_company(self, company_id: int, message: dict):
        if company_id in self.company_connections:
            message_str = json.dumps(message)
            for connection in self.company_connections[company_id]:
                try:
                    await connection.send_text(message_str)
                except Exception:
                    pass

manager = ConnectionManager()

@router.websocket("/company/{company_id}")
async def websocket_company_endpoint(websocket: WebSocket, company_id: int):
    await manager.connect_company(websocket, company_id)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect_company(websocket, company_id)

@router.websocket("/{machine_id}")
async def websocket_endpoint(websocket: WebSocket, machine_id: int):
    await manager.connect(websocket, machine_id)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket, machine_id)
