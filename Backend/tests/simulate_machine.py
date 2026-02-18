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
    """Simulates a single machine's activity."""
    print(f"🟢 Starting simulation for: Company {company_id}, Machine {machine_serial}")
    
    # Subscribe to command topic
    command_topic = f"company/{company_id}/machine/{machine_serial}/command"
    await client.subscribe(command_topic)
    print(f"📡 Subscribed to commands: {command_topic}")

    while True:
        try:
            # 1. Send Random Status
            status_topic = f"company/{company_id}/machine/{machine_serial}/status"
            status_payload = {
                "status": random.choice(["Running", "Idle", "Charging"]),
                "energy": round(random.uniform(10, 50), 2),
                "water": round(random.uniform(5, 20), 2),
                "area": round(random.uniform(100, 500), 2)
            }
            await client.publish(status_topic, json.dumps(status_payload))
            print(f"📊 [{machine_serial}] Status Published: {status_payload['status']}")

            # 2. Send Random Telemetry
            telemetry_topic = f"company/{company_id}/machine/{machine_serial}/telemetry"
            telemetry_payload = {
                "battery": round(random.uniform(12.0, 14.8), 2),
                "solar_v": round(random.uniform(18.0, 24.0), 2),
                "solar_a": round(random.uniform(0.1, 10.0), 2),
                "water": round(random.uniform(0, 100), 2),
                "extra": {"temp": round(random.uniform(20, 50), 1)}
            }
            await client.publish(telemetry_topic, json.dumps(telemetry_payload))
            print(f"📈 [{machine_serial}] Telemetry Published: {telemetry_payload['battery']}V")

            await asyncio.sleep(random.randint(5, 15)) # Random interval
        except Exception as e:
            print(f"❌ Error in machine {machine_serial}: {e}")
            break

async def listen_all_commands(client):
    """Global listener for commands from the broker."""
    async for message in client.messages:
        payload = json.loads(message.payload.decode())
        print(f"📥 RECEIVED COMMAND on {message.topic}: {payload}")

async def main():
    # Use arguments if provided: python simulate_machine.py <company_id> <serial_no>
    if len(sys.argv) == 3:
        target_company = sys.argv[1]
        target_serial = sys.argv[2]
        machines = [(target_company, target_serial)]
    else:
        # Default fallback for testing
        print("💡 Tip: Use 'python simulate_machine.py <CompanyID> <SerialNo>' to target a specific machine.")
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
