import asyncio
import websockets
import json

async def test_websocket():
    # TEST PARAMS - Change if needed
    host = "157.173.222.91"
    port = 8006
    company_id = 1
    
    uri = f"ws://{host}:{port}/realtime/company/{company_id}"
    http_url = f"http://{host}:{port}/realtime/company/{company_id}"
    
    print(f"📡 Testing HTTP Reachability: {http_url}")
    import requests
    try:
        r = requests.get(http_url)
        print(f"📥 HTTP Response ({r.status_code}): {r.json()}")
        if r.status_code == 200:
            print("🚀 HTTP is REACHABLE. If WebSocket fails below, it's 100% a PROXY/UPGRADE issue.")
    except Exception as e:
        print(f"⚠️ HTTP Check failed (might be expected if GET is not allowed): {e}")

    print(f"\n📡 Testing WebSocket Handshake: {uri}")
    
    try:
        async with websockets.connect(uri) as websocket:
            print("✅ CONNECTION SUCCESSFUL!")
            print("🧘 Waiting for heartbeat...")
            
            # Wait for the 5-second heartbeat I implemented
            try:
                message = await asyncio.wait_for(websocket.recv(), timeout=10)
                data = json.loads(message)
                print(f"📥 Received from server: {data}")
                if data.get("type") == "heartbeat":
                    print("💓 Heartbeat verified!")
            except asyncio.TimeoutError:
                print("⚠️ Connected, but no message received within 10s.")
            
    except Exception as e:
        print(f"❌ CONNECTION FAILED: {e}")
        print("\nPossible Causes:")
        print("1. Firewall/Security Group is blocking port 8006.")
        print("2. The backend is not running with the latest code (check /realtime/health).")
        print("3. There is an Nginx/Proxy in front of the server that doesn't support WebSockets.")

if __name__ == "__main__":
    asyncio.run(test_websocket())
