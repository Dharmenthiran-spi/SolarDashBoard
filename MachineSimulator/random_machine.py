import asyncio
import json
import random
import time
import sys
from aiomqtt import Client, MqttError

if sys.platform == 'win32':
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

# === CONFIGURATION ===
# Use "localhost" if running on the same machine as Docker
# Use the Server IP if running from another computer
MQTT_BROKER = "localhost" 
MQTT_PORT = 1883

# These IDs should match what you see in your API/Dashboard
COMPANY_ID = 1
MACHINE_ID = "SOLAR-TEST-01"

# MQTT Credentials (from your Machine Detail UI)
USERNAME = "admin" 
PASSWORD = "public" 

async def run_simulator():
    print(f"🚀 Starting Machine Simulator: {MACHINE_ID}")
    
    try:
        async with Client(
            hostname=MQTT_BROKER, 
            port=MQTT_PORT,
            username=USERNAME,
            password=PASSWORD
        ) as client:
            print("✅ Connected to EMQX Broker!")

            while True:
                # 1. Create Random Telemetry Data
                telemetry = {
                    "battery": round(random.uniform(12.0, 14.8), 2),
                    "solar_v": round(random.uniform(18.0, 22.0), 2),
                    "solar_a": round(random.uniform(0.5, 8.5), 2),
                    "water": round(random.uniform(40.0, 95.0), 2),
                    "extra": {
                        "temp": round(random.uniform(25.0, 45.0), 1),
                        "load": round(random.uniform(1.0, 5.0), 2)
                    }
                }

                # 2. Create Random Status Data
                status = {
                    "status": random.choice(["Running", "Idle", "Charging"]),
                    "energy": round(random.uniform(10.5, 50.0), 2),
                    "water": round(random.uniform(5.0, 15.0), 2),
                    "area": round(random.uniform(100, 300), 0)
                }

                # 3. Publish to Topics
                telemetry_topic = f"company/{COMPANY_ID}/machine/{MACHINE_ID}/telemetry"
                status_topic = f"company/{COMPANY_ID}/machine/{MACHINE_ID}/status"

                await client.publish(telemetry_topic, json.dumps(telemetry))
                print(f"📡 Sent Telemetry: {telemetry['battery']}V")

                await client.publish(status_topic, json.dumps(status))
                print(f"📊 Sent Status: {status['status']}")

                print("-" * 30)
                await asyncio.sleep(5)  # Send data every 5 seconds

    except MqttError as e:
        print(f"❌ MQTT Error: {e}")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    # To run this, you need to install helper library:
    # pip install aiomqtt
    asyncio.run(run_simulator())
