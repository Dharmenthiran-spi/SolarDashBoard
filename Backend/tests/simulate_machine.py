import asyncio
import json
import random
import sys
from aiomqtt import Client, MqttError

if sys.platform == 'win32':
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

# === CONFIGURATION ===
BROKER = "157.173.222.91"
PORT = 1883

async def simulate_single_machine(client, company_id, machine_serial):
    """Simulates a single machine's activity with adaptive frequencies."""
    print(f"🟢 Starting optimized simulation for: Company {company_id}, Machine {machine_serial}")
    
    command_topic = f"company/{company_id}/machine/{machine_serial}/command"
    await client.subscribe(command_topic)

    # Local state for delta detection
    last_state = {"status": None, "battery": None, "water": None, "temp": None}
    
    last_status_sent = 0
    last_telemetry_sent = 0
    last_heartbeat_sent = 0
    
    # Adaptive intervals (seconds)
    POS_INTERVAL = 5
    TEMP_INTERVAL = 10
    BATT_INTERVAL = 15
    HEARTBEAT_INTERVAL = 30

    while True:
        try:
            now = asyncio.get_event_loop().time()
            
            # 1. Emergency/Status Changes (Immediate if changed)
            status_val = random.choice(["Running", "Idle", "Charging"])
            if status_val != last_state["status"]:
                status_topic = f"company/{company_id}/machine/{machine_serial}/status"
                status_payload = {
                    "status": status_val,
                    "energy": round(random.uniform(10, 50), 2),
                    "water": round(random.uniform(5, 20), 2),
                    "area": round(random.uniform(100, 500), 2)
                }
                await client.publish(status_topic, json.dumps(status_payload))
                last_state["status"] = status_val
                print(f"🚨 [{machine_serial}] Status ALERT: {status_val}")

            # 2. Adaptive Telemetry
            telemetry_payload = {}
            
            # Position/Area (5s)
            if now - last_status_sent >= POS_INTERVAL:
                telemetry_payload["area"] = round(random.uniform(100, 500), 2)
                last_status_sent = now

            # Temperature (10s)
            if now - last_telemetry_sent >= TEMP_INTERVAL:
                telemetry_payload["temp"] = round(random.uniform(20, 50), 1)
                last_telemetry_sent = now

            # Battery (15s)
            if now - last_telemetry_sent >= BATT_INTERVAL:
                telemetry_payload["battery"] = round(random.uniform(12.0, 14.8), 2)
                telemetry_payload["solar_v"] = round(random.uniform(18.0, 24.0), 2)
            
            if telemetry_payload:
                telemetry_topic = f"company/{company_id}/machine/{machine_serial}/telemetry"
                await client.publish(telemetry_topic, json.dumps(telemetry_payload))
                print(f"📈 [{machine_serial}] Adaptive Telemetry: {list(telemetry_payload.keys())}")

            # 3. Heartbeat (30s)
            if now - last_heartbeat_sent >= HEARTBEAT_INTERVAL:
                hb_topic = f"company/{company_id}/machine/{machine_serial}/heartbeat"
                await client.publish(hb_topic, json.dumps({"ts": now, "v": "1.0.2"}))
                last_heartbeat_sent = now
                print(f"💗 [{machine_serial}] Heartbeat sent")

            await asyncio.sleep(1) # Check intervals every second
        except Exception as e:
            print(f"❌ Error in machine {machine_serial}: {e}")
            break

async def listen_all_commands(client):
    """Global listener for commands from the broker."""
    async for message in client.messages:
        payload = json.loads(message.payload.decode())
        print(f"📥 RECEIVED COMMAND on {message.topic}: {payload}")

async def main():
    # Use arguments if provided: python simulate_machine.py <company_id> <serial_no1> <serial_no2> ...
    if len(sys.argv) >= 3:
        target_company = sys.argv[1]
        serials = sys.argv[2:]
        machines = [(target_company, s_no) for s_no in serials]
    else:
        # Default fallback for testing
        print("💡 Tip: Use 'python simulate_machine.py <CompanyID> <SerialNo1> <SerialNo2> ...' for bulk simulation.")
        machines = [(1, "SOLAR-001"), (1, "SOLAR-002")]

    try:
        async with Client(hostname=BROKER, port=PORT) as client:
            print(f"✅ Connected to MQTT Broker at {BROKER}:{PORT}")
            
            # Start global command listener
            asyncio.create_task(listen_all_commands(client))

            # Start all machine simulations
            tasks = [simulate_single_machine(client, c_id, s_no) for c_id, s_no in machines]
            await asyncio.gather(*tasks)

    except MqttError as e:
        print(f"❌ MQTT Connection Error: {e}")
    except KeyboardInterrupt:
        print("\n👋 Simulation stopped by user.")

if __name__ == "__main__":
    asyncio.run(main())
