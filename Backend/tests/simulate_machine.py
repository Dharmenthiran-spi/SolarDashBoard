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
            
            # --- TELEMETRY TIERED ---
            telemetry_payload = {}
            
            # Position (Every 5s)
            if (now - last_sent["position"]) > 5:
                telemetry_payload["position"] = {"lat": 12.92, "lng": 80.14}
                last_sent["position"] = now

            # Temperature & Motor Stats (Every 10s)
            curr_temp = round(random.uniform(20, 50), 1)
            if (now - last_sent["temp"]) > 10 or abs(curr_temp - (last_values["temp"] or 0)) > 5:
                telemetry_payload["extra"] = {"temp": curr_temp}
                # Add Motor & Sensor Stats
                telemetry_payload["brush_rpm"] = random.randint(1200, 3000)
                telemetry_payload["speed"] = round(random.uniform(0.5, 3.5), 1)
                
                # Additional fields from MachineStatus model
                telemetry_payload["mode"] = random.choice(["Auto", "Manual", "Spot", "Edge"])
                telemetry_payload["timer"] = random.randint(0, 120) # Minutes remaining
                telemetry_payload["is_charging"] = random.choice([True, False])
                telemetry_payload["pump_status"] = random.choice([True, False])
                telemetry_payload["is_brush_jam"] = False # Rarely true
                if random.random() < 0.05: telemetry_payload["is_brush_jam"] = True
                
                telemetry_payload["direction"] = round(random.uniform(0, 360), 1)
                telemetry_payload["emergency_stop"] = False
                if random.random() < 0.01: telemetry_payload["emergency_stop"] = True
                
                telemetry_payload["obstacle_detected"] = False
                if random.random() < 0.05: telemetry_payload["obstacle_detected"] = True
                
                telemetry_payload["cleaning_time"] = random.randint(10, 480) # Minutes worked today
                telemetry_payload["total_cycles"] = random.randint(50, 5000) # Total lifetime cycles

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
                # Always include water/area for consistent model mapping in this demo
                telemetry_payload["water"] = round(random.uniform(40, 90), 1) # Water Level %
                telemetry_payload["area"] = round(random.uniform(10, 500), 0) # Area Today
                
                # Ensure keys match frontend model expectations (camelCase vs snake_case handling in fromJson)
                # The Dart model handles both, but let's be consistent or verify.
                # MachineStatus.fromJson handles:
                # 'Mode'/'mode', 'Timer'/'timer', 'IsCharging'/'isCharging' (Model wrapper handles mapping if needed, let's check)
                # Model checks: json['IsCharging'] ?? false. Doesn't check lowercase 'is_charging'?
                # Wait, let's re-verify model:
                # isCharging: json['IsCharging'] ?? false, 
                # It does NOT check lowercase for IsCharging! It only checks Uppercase.
                # Let's add upper case keys for those missing double-checks in model, OR fix model.
                # Since I am editing simulator, I will send keys that match the Model's logic or add duplicates.
                # The model *does* check lowercase for some: status, energy, water, area, battery, solar_v (mapped to BatteryVoltage).
                # But for new fields, it looks like it only checks Uppercase in some lines? 
                # Lines 56-86:
                # mode: json['Mode'] ?? 'Auto' -> Only capitalized Mode? 
                # timer: json['Timer'] ?? 0 -> Only capitalized Timer?
                # isCharging: json['IsCharging'] ?? false -> Only capitalized?
                # pumpStatus: json['PumpStatus'] ?? false -> Only capitalized?
                # brushRPM: json['BrushRPM'] ?? 0 -> Only capitalized?
                
                # To be safe and ensure it works without redeploying backend logic (which passes payload through),
                # I will send Capitalized keys for those specific fields to match the Flutter model exactly.
                
                # Remap simulation keys to match Flutter Model defaults (PascalCase) where necessary
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
                
                # battery, solar_v, extra, water, area are handled by existing logic or have fallback
                
                await client.publish(telemetry_topic, json.dumps(payload_to_send))
                
                print(f"\n🚀 [{machine_serial}] SENT TELEMETRY (All Fields):")
                if "battery" in payload_to_send:
                    print(f"   🔋 Power: {payload_to_send['battery']}V | Solar: {payload_to_send.get('solar_v',0)}V")
                if "extra" in payload_to_send:
                    print(f"   🌡️ Temp: {payload_to_send['extra']['temp']}°C")
                
                # Print the new fields
                print(f"   ⚙️ Motor: {payload_to_send.get('BrushRPM')} RPM | Speed: {payload_to_send.get('Speed')} m/s")
                print(f"   🕹️ Mode: {payload_to_send.get('Mode')} | Timer: {payload_to_send.get('Timer')}m")
                print(f"   ⚡ Charging: {payload_to_send.get('IsCharging')} | Pump: {payload_to_send.get('PumpStatus')}")
                print(f"   🚨 Alerts: Stop={payload_to_send.get('EmergencyStop')} | OBS={payload_to_send.get('ObstacleDetected')} | Jam={payload_to_send.get('IsBrushJam')}")
                print(f"   📊 Stats: Time={payload_to_send.get('CleaningTime')}m | Cycles={payload_to_send.get('TotalCycles')}")
                print(f"   💧 Water: {payload_to_send.get('water')}%")
                print(f"   📐 Area: {payload_to_send.get('area')} m²")

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
