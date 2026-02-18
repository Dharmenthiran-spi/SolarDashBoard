import asyncio
import json
import random
from aiomqtt import Client, MqttError

# Configuration - adjust if running outside docker
BROKER = "localhost"
PORT = 1883
COMPANY_ID = 1
MACHINE_SERIAL = "SOLAR-999"

async def simulate_machine():
    print(f"Starting simulation for machine {MACHINE_SERIAL}...")
    try:
        async with Client(hostname=BROKER, port=PORT) as client:
            print("Connected to MQTT Broker")
            
            # Subscribe to command topic
            command_topic = f"company/{COMPANY_ID}/machine/{MACHINE_SERIAL}/command"
            await client.subscribe(command_topic)
            print(f"Subscribed to {command_topic}")

            async def listen_commands():
                async for message in client.messages:
                    payload = json.loads(message.payload.decode())
                    print(f"Received COMMAND: {payload}")

            asyncio.create_task(listen_commands())

            while True:
                # Send Status
                status_topic = f"company/{COMPANY_ID}/machine/{MACHINE_SERIAL}/status"
                status_payload = {
                    "status": "Running",
                    "energy": round(random.uniform(10, 50), 2),
                    "water": round(random.uniform(5, 20), 2),
                    "area": round(random.uniform(100, 500), 2)
                }
                await client.publish(status_topic, json.dumps(status_payload))
                print(f"Published STATUS to {status_topic}")

                # Send Telemetry
                telemetry_topic = f"company/{COMPANY_ID}/machine/{MACHINE_SERIAL}/telemetry"
                telemetry_payload = {
                    "battery": round(random.uniform(12.0, 14.4), 2),
                    "solar_v": round(random.uniform(18.0, 24.0), 2),
                    "solar_a": round(random.uniform(0.0, 10.0), 2),
                    "water": round(random.uniform(0, 100), 2),
                    "extra": {"temp": 45.5}
                }
                await client.publish(telemetry_topic, json.dumps(telemetry_payload))
                print(f"Published TELEMETRY to {telemetry_topic}")

                await asyncio.sleep(10)

    except MqttError as e:
        print(f"MQTT Error: {e}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(simulate_machine())
