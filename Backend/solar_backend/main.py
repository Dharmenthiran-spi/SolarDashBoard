import sys
import asyncio
from pathlib import Path

# Ensure backend directory is in path
backend_dir = str(Path(__file__).resolve().parent.parent)
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from solar_backend.database import engine, Base
from solar_backend.routes import company, employee, customer, machine, report, dashboard, machine_status, auth, realtime

@asynccontextmanager
async def lifespan(app: FastAPI):
    import traceback
    try:
        # Create tables
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        
        # Robust Migration: Add missing MQTT columns to Machine table
        try:
            from sqlalchemy import text
            async with engine.connect() as conn:
                # We use a separate connection to avoid transaction issues during ALTER
                result = await conn.execute(text("SHOW COLUMNS FROM Machine"))
                columns = [row[0].lower() for row in result.fetchall()]
                
                # Check for MqttUsername (case-insensitive check)
                if "mqttusername" not in columns:
                    print("MIGRATION: Adding MqttUsername column to Machine table")
                    try:
                        await conn.execute(text("ALTER TABLE Machine ADD COLUMN MqttUsername VARCHAR(255) UNIQUE AFTER image"))
                        await conn.commit()
                        print("MIGRATION: MqttUsername added successfully")
                    except Exception as alter_e:
                        print(f"MIGRATION ERROR (MqttUsername): {alter_e}")

                # Check for MqttPassword
                if "mqttpassword" not in columns:
                    print("MIGRATION: Adding MqttPassword column to Machine table")
                    try:
                        await conn.execute(text("ALTER TABLE Machine ADD COLUMN MqttPassword VARCHAR(255) AFTER MqttUsername"))
                        await conn.commit()
                        print("MIGRATION: MqttPassword added successfully")
                    except Exception as alter_e:
                        print(f"MIGRATION ERROR (MqttPassword): {alter_e}")
        except Exception as e:
            print(f"CRITICAL MIGRATION ERROR: {e}")

        # Start MQTT Handler
        from .mqtt_handler import MQTTHandler
        from .config import settings
        
        mqtt_handler = MQTTHandler(
            broker=settings.MQTT_BROKER,
            port=settings.MQTT_PORT,
            username=settings.MQTT_USERNAME,
            password=settings.MQTT_PASSWORD,
            use_tls=settings.MQTT_USE_TLS
        )
        
        # Run MQTT handler as a background task
        mqtt_task = asyncio.create_task(mqtt_handler.start())
        app.state.mqtt_handler = mqtt_handler
        
        yield
        
        # Shutdown MQTT handler
        mqtt_task.cancel()
        try:
            await mqtt_task
        except asyncio.CancelledError:
            pass
    except Exception as e:
        print(f"FATAL STARTUP ERROR: {e}")
        traceback.print_exc()
        raise

app = FastAPI(
    title="SolarDashBoard API",
    description="Backend for SolarDashBoard Project",
    version="1.0.0",
    lifespan=lifespan
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(auth.router)
app.include_router(company.router)
app.include_router(employee.router)
app.include_router(customer.router)
app.include_router(machine.router)
app.include_router(report.router)
app.include_router(dashboard.router)
app.include_router(machine_status.router)
app.include_router(realtime.router)

@app.get("/")
def root():
    return {"message": "Welcome to SolarDashBoard API"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("solar_backend.main:app", host="0.0.0.0", port=8006, reload=True)
