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

            if (now - last_sent["telemetry"]) > 10:
                # 1. Status Update (Heartbeat)
                current_status = random.choice(["Running", "Idle", "Charging"])
                status_topic = f"company/{company_id}/machine/{machine_serial}/status"
                status_payload = {
                    "status": current_status,
                    "energy": round(random.uniform(10, 50), 2),
                    "water": round(random.uniform(5, 20), 2),
                    "area": round(random.uniform(100, 500), 2)
                }
                await client.publish(status_topic, json.dumps(status_payload))
                print(f"📊 [{machine_serial}] Status Published: {current_status}")

                # 2. Telemetry Update
                telemetry_payload = {}
                
                # Position
                telemetry_payload["position"] = {"lat": 12.92, "lng": 80.14}

                # Temperature & Stats
                curr_temp = round(random.uniform(20, 50), 1)
                telemetry_payload["extra"] = {"temp": curr_temp}
                
                # Motor & Sensor Stats
                telemetry_payload["brush_rpm"] = random.randint(1200, 3000)
                telemetry_payload["speed"] = round(random.uniform(0.5, 3.5), 1)
                
                # Additional fields
                telemetry_payload["mode"] = random.choice(["Auto", "Manual", "Spot", "Edge"])
                telemetry_payload["timer"] = random.randint(0, 120)
                telemetry_payload["is_charging"] = random.choice([True, False])
                telemetry_payload["pump_status"] = random.choice([True, False])
                telemetry_payload["is_brush_jam"] = False
                if random.random() < 0.05: telemetry_payload["is_brush_jam"] = True
                
                telemetry_payload["direction"] = round(random.uniform(0, 360), 1)
                telemetry_payload["emergency_stop"] = False
                if random.random() < 0.01: telemetry_payload["emergency_stop"] = True
                
                telemetry_payload["obstacle_detected"] = False
                if random.random() < 0.05: telemetry_payload["obstacle_detected"] = True
                
                telemetry_payload["cleaning_time"] = random.randint(10, 480)
                telemetry_payload["total_cycles"] = random.randint(50, 5000)

                # Battery
                telemetry_payload["battery"] = round(random.uniform(12.0, 14.8), 2)
                telemetry_payload["solar_v"] = round(random.uniform(18.0, 24.0), 2)
                telemetry_payload["solar_a"] = round(random.uniform(0.1, 10.0), 2)
                
                # Default Fields for consistency
                telemetry_payload["water"] = round(random.uniform(40, 90), 1)
                telemetry_payload["area"] = round(random.uniform(10, 500), 0)

                # Publish Telemetry
                telemetry_topic = f"company/{company_id}/machine/{machine_serial}/telemetry"
                
                # Remap to PascalCase for Frontend Model matching
                payload_to_send = telemetry_payload.copy()
                payload_to_send["Mode"] = telemetry_payload.pop("mode", "Auto")
                payload_to_send["Timer"] = telemetry_payload.pop("timer", 0)
                payload_to_send["IsCharging"] = telemetry_payload.pop("is_charging", False)
                payload_to_send["PumpStatus"] = telemetry_payload.pop("pump_status", False)
                payload_to_send["BrushRPM"] = telemetry_payload.pop("brush_rpm", 0)
                payload_to_send["IsBrushJam"] = telemetry_payload.pop("is_brush_jam", False)
                payload_to_send["Speed"] = telemetry_payload.pop("speed", 0.0)
                payload_to_send["Direction"] = telemetry_payload.pop("direction", 0.0)
                payload_to_send["EmergencyStop"] = telemetry_payload.pop("emergency_stop", False)
                payload_to_send["ObstacleDetected"] = telemetry_payload.pop("obstacle_detected", False)
                payload_to_send["CleaningTime"] = telemetry_payload.pop("cleaning_time", 0)
                payload_to_send["TotalCycles"] = telemetry_payload.pop("total_cycles", 0)
                
                await client.publish(telemetry_topic, json.dumps(payload_to_send))
                
                print(f"🚀 [{machine_serial}] Telemetry Sent (Speed: {payload_to_send.get('Speed')} m/s, RPM: {payload_to_send.get('BrushRPM')})")
                
                last_sent["telemetry"] = now
                last_values["temp"] = curr_temp

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
