# MQTT Architecture & Topic Documentation

This document describes how the real-time communication system works between the Solar Cleaning Machines, EMQX Broker, and the FastAPI Backend.

## 🏗 Architecture Overview

1.  **Machines (Raspberry Pi)**: Connect to EMQX via MQTT. They publish telemetry/status and subscribe to commands.
2.  **EMQX (MQTT Broker)**: The central hub for all MQTT messages. Handles authentication, ACLs, and message routing.
3.  **FastAPI Backend**:
    -   Runs an **MQTT Client** as a background task.
    -   Subscribes to all telemetry/status topics.
    -   Stores data in **MySQL**.
    -   Publishes commands to machines via MQTT.
    -   Provides **WebSockets** for the Flutter frontend to receive real-time updates.
4.  **Flutter Frontend**: Connects via WebSockets to the Backend for live updates and uses REST APIs to send commands.

---

## 📡 Topic Structure

The system uses a multi-tenant hierarchy: `company/{company_id}/machine/{machine_id}/{type}`

| Topic | Description | Direction |
| :--- | :--- | :--- |
| `company/{c_id}/machine/{m_id}/telemetry` | Raw sensor data (battery, solar) | Machine ➡ Backend |
| `company/{c_id}/machine/{m_id}/status` | Connection/Operating state | Machine ➡ Backend |
| `company/{c_id}/machine/{m_id}/command` | Control instructions | Backend ➡ Machine |

---

## 📩 Message Formats (JSON)

### 1. Telemetry
Machines should publish sensor data periodically (e.g., every 30-60 seconds).
```json
{
  "battery": 13.5,
  "solar_v": 21.2,
  "solar_a": 4.5,
  "water": 80,
  "extra": {
    "temp": 32.5,
    "vibration": 0.01
  }
}
```

### 2. Status
Used for heartbeat and current state. Implement **Last Will and Testament (LWT)** to this topic with payload `{"status": "offline"}`.
```json
{
  "status": "Running",
  "energy": 150.5,
  "water": 25.0,
  "area": 450.0
}
```

### 3. Command
Sent from the dashboard to trigger actions on the machine.
```json
{
  "command": "start_cleaning",
  "params": {
    "speed": 5,
    "mode": "auto"
  }
}
```

---

## 🛠 How It Works

### Backend Logic (`mqtt_handler.py`)
- **Subscription**: The backend subscribes to `company/+/machine/+/telemetry` and `company/+/machine/+/status`. The `+` is a wildcard for any ID.
- **Parsing**: When a message arrives, the handler extracts the `machine_id` (SerialNo) from the topic.
- **Storage**: Telemetry is historical (inserted as new rows), while Status is live (updates current state).
- **Broadcasting**: Upon receiving a message, the backend immediately broadcasts it to any Flutter client connected via WebSocket for that specific machine.

### Frontend Integration
- **WebSocket**: Flutter connects to `ws://api.yoursite.com/realtime/{machine_id}`.
- **Live Feed**: As soon as the machine publishes to MQTT, the backend pushes it through the WebSocket to the UI.

---

## 🏗 Deployment & Infrastructure

### Docker Details
- **Container Name**: `solar_emqx`
- **Image**: `emqx/emqx:5.3.0`
- **Dashboard URL**: `http://localhost:18083` (or server IP on port 18083)
- **Default Credentials**: 
  - Username: `admin`
  - Password: `public` (unless changed via `MQTT_PASSWORD` in `.env`)

### Network Ports
| Port | Protocol | Description |
| :--- | :--- | :--- |
| `1883` | MQTT | Standard unencrypted MQTT (Machines) |
| `8883` | MQTTS | Secure MQTT via TLS/SSL (Recommended for Prod) |
| `18083` | HTTP | EMQX Dashboard / Management UI |
| `8083` | Webhooks | WebSocket connection (Alternative for machine) |
| `8084` | WSS | Secure WebSocket connection |

---

## 🔒 Security & Scaling

1.  **Authentication**: Each machine has a unique `MqttUsername` and `MqttPassword` stored in the database.
2.  **ACL Rules**: EMQX is configured so `Machine A` can only publish/subscribe to its own topics (`company/1/machine/A/#`).
3.  **TLS (Port 8883)**: All production communication must use MQTTS (TLS) to encrypt the data.
4.  **Scaling**: EMQX can handle 10k+ concurrent connections easily. For 100k+, EMQX can be clustered.
