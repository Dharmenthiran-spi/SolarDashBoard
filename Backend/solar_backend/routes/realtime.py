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

    async def connect(self, websocket: WebSocket, machine_id: int):
        await websocket.accept()
        if machine_id not in self.active_connections:
            self.active_connections[machine_id] = []
        self.active_connections[machine_id].append(websocket)

    def disconnect(self, websocket: WebSocket, machine_id: int):
        if machine_id in self.active_connections:
            self.active_connections[machine_id].remove(websocket)
            if not self.active_connections[machine_id]:
                del self.active_connections[machine_id]

    async def send_personal_message(self, message: str, websocket: WebSocket):
        await websocket.send_text(message)

    async def broadcast_to_machine(self, machine_id: int, message: dict):
        if machine_id in self.active_connections:
            message_str = json.dumps(message)
            for connection in self.active_connections[machine_id]:
                try:
                    await connection.send_text(message_str)
                except Exception:
                    # Connection might be closed, clean up later or on next broadcast
                    pass

manager = ConnectionManager()

@router.websocket("/{machine_id}")
async def websocket_endpoint(websocket: WebSocket, machine_id: int):
    await manager.connect(websocket, machine_id)
    try:
        while True:
            # Keep connection alive, can receive client pings if needed
            data = await websocket.receive_text()
            # client doesn't need to send anything for now
    except WebSocketDisconnect:
        manager.disconnect(websocket, machine_id)
