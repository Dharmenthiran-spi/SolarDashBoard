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
USERNAME = "admin"  # Set to None if no auth
PASSWORD = "public" # Set to None if no auth

async def simulate_single_machine(client, company_id, machine_serial):
    """Simulates a single machine's activity with tiered frequency."""
    print(f"🟢 Starting optimized simulation for: Company {company_id}, Machine {machine_serial}")
    
    command_topic = f"company/{company_id}/machine/{machine_serial}/command"
    await client.subscribe(command_topic)

    # State tracking for tiered frequency
    last_sent = {
        "status": 0,
        "telemetry": 0,
        "position": 0,
        "temp": 0,
        "battery": 0,
        "heartbeat": 0
    }
    
    last_values = {
        "status_str": None,
        "battery": None,
        "temp": None
    }

    while True:
        try:
            now = asyncio.get_event_loop().time()


            if (now - last_sent["telemetry"]) > 10:
                # 1. Status Update (Minimal)
                current_status = random.choice(["Running", "Idle", "Charging"])
                status_topic = f"company/{company_id}/machine/{machine_serial}/status"
                status_payload = {
                    "Status": current_status
                }
                await client.publish(status_topic, json.dumps(status_payload))
                print(f"📊 [{machine_serial}] Status Published: {json.dumps(status_payload, indent=2)}")

                # 2. Telemetry Update (Minimal)
                telemetry_payload = {
                    "BatteryLevel": round(random.uniform(12.0, 14.8), 2),
                    "BatteryVoltage": round(random.uniform(18.0, 24.0), 2),
                    "WaterLevel": round(random.uniform(40, 90), 1),
                    "BrushRPM": random.randint(1200, 3000),
                    "BrushTemp": round(random.uniform(20, 50), 1),
                    "Speed": round(random.uniform(0.5, 3.5), 1),
                    "AreaToday": round(random.uniform(10, 500), 0),
                    "TotalCycles": random.randint(50, 5000),
                    "Mode": random.choice(["Auto", "Manual", "Spot", "Edge"])
                }

                # Publish Telemetry
                telemetry_topic = f"company/{company_id}/machine/{machine_serial}/telemetry"
                
                await client.publish(telemetry_topic, json.dumps(telemetry_payload))
                
                print(f"🚀 [{machine_serial}] Telemetry Sent: {json.dumps(telemetry_payload, indent=2)}")
                
                last_sent["telemetry"] = now
                last_values["temp"] = telemetry_payload["BrushTemp"]

            await asyncio.sleep(0.1) # High precision tick
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
        async with Client(
            hostname=BROKER, 
            port=PORT,
            username=USERNAME,
            password=PASSWORD
        ) as client:
            print(f"✅ Connected to MQTT Broker at {BROKER}:{PORT} as {USERNAME or 'Anonymous'}")
            
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
