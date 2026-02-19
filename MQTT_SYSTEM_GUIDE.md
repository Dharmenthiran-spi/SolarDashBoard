# 🚜 SolarDashBoard: MQTT System Guide

This guide explains the technical architecture of the MQTT integration and how to use the simulation tools to verify the system.

## 🏗 System Architecture

The project consists of 4 main containers working together:

| Container | Name | Purpose |
| :--- | :--- | :--- |
| **Backend** | `solar_backend` | FastAPI app. Manages logic, DB storage, and WebSockets for the UI. |
| **Broker** | `solar_emqx` | The MQTT "Switchboard". Handles all machine communication. |
| **Database** | `solar_db` | MySQL 8.0. Stores machine info, telemetry history, and users. |
| **Cache** | `solar_redis` | Stores live machine state for fast real-time access. |

---

## 📡 MQTT Topic Structure

We use a professional **Multi-Tenant** structure to ensure performance and security:

`company/{company_id}/machine/{machine_no}/{type}`

- **`company_id`**: Isolates data between different customers.
- **`machine_no`**: The Serial Number (e.g., `S1`, `SOLAR-999`).
- **`type`**: The kind of data being sent (`telemetry`, `status`, or `command`).

---

## 🚀 Simulation & Testing

Since you might not have 1,000 physical machines yet, we use the `simulate_machine.py` script to test the system.

### 1. Prerequisites
Install the required library on your local computer:
```bash
pip install aiomqtt
```

### 2. Running the Simulator
The script is located at `Backend/tests/simulate_machine.py`. It is dynamic and supports both single and bulk simulation.

#### A. Simulate one specific machine:
```powershell
# Format: python <path> <CompanyID> <SerialNo>
python Backend/tests/simulate_machine.py 1 S1
```

#### B. Simulate multiple machines at once:
Useful for testing the "Real-time Dashboard" with multiple moving machines.
```powershell
# Format: python <path> <CompanyID> <Serial1> <Serial2> <Serial3> ...
python Backend/tests/simulate_machine.py 1 S1 S2 S3 S4
```

### 3. What the Simulator Does
- **Telemetry**: Sends battery, solar voltage, and temp data every 5-15 seconds.
- **Status**: Sends the machine's state (Running, Idle, Charging).
- **Command Listener**: Stays active to receive "Start" or "Stop" commands from your Flutter Dashboard.

---

## 🛠 Troubleshooting
- **Cannot Connect?**: Ensure `BROKER` inside `simulate_machine.py` is set to your server's IP.
- **Port 1883**: Ensure this port is open in your server's firewall.
- **EMQX Dashboard**: Visit `http://YOUR_IP:18083` to see live connections and message counts.
