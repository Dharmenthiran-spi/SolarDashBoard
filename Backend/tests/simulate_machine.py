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
            
            # --- STATUS & HEARTBEAT (30s heartbeat or immediate on change) ---
            current_status = random.choice(["Running", "Idle", "Charging"])
            if current_status != last_values["status_str"] or (now - last_sent["heartbeat"]) > 30:
                status_topic = f"company/{company_id}/machine/{machine_serial}/status"
                status_payload = {
                    "status": current_status,
                    "energy": round(random.uniform(10, 50), 2),
                    "water": round(random.uniform(5, 20), 2),
                    "area": round(random.uniform(100, 500), 2)
                }
                await client.publish(status_topic, json.dumps(status_payload))
                last_sent["heartbeat"] = now
                last_values["status_str"] = current_status
                print(f"📊 [{machine_serial}] Status/Heartbeat Published: {current_status}")

            # --- TELEMETRY TIERED ---
            telemetry_payload = {}
            
            # Position (Every 5s) - Simulated via 'area' updates in status usually, 
            # but we'll simulate 'extra' updates here
            if (now - last_sent["position"]) > 5:
                telemetry_payload["position"] = {"lat": 12.92, "lng": 80.14} # Stationary for demo
                last_sent["position"] = now

            # Temperature (Every 10s)
            curr_temp = round(random.uniform(20, 50), 1)
            if (now - last_sent["temp"]) > 10 or abs(curr_temp - (last_values["temp"] or 0)) > 5:
                telemetry_payload["extra"] = {"temp": curr_temp}
                last_sent["temp"] = now
                last_values["temp"] = curr_temp

            # Battery (Every 15s)
            curr_batt = round(random.uniform(12.0, 14.8), 2)
            if (now - last_sent["battery"]) > 15:
                telemetry_payload["battery"] = curr_batt
                telemetry_payload["solar_v"] = round(random.uniform(18.0, 24.0), 2)
                telemetry_payload["solar_a"] = round(random.uniform(0.1, 10.0), 2)
                last_sent["battery"] = now

            if telemetry_payload:
                telemetry_topic = f"company/{company_id}/machine/{machine_serial}/telemetry"
                # Always include water for consistent model mapping in this demo
                telemetry_payload["water"] = round(random.uniform(0, 100), 2)
                await client.publish(telemetry_topic, json.dumps(telemetry_payload))
                print(f"📈 [{machine_serial}] Tiered Telemetry Published: {list(telemetry_payload.keys())}")

            await asyncio.sleep(1) # Check every second
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
