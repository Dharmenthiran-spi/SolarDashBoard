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
        # Create tables (Handles new tables)
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        
        # Comprehensive Schema Synchronisation (Handles missing columns in existing tables)
        try:
            from sqlalchemy import text
            from sqlalchemy.dialects.mysql import LONGBLOB, TEXT as MYSQL_TEXT
            
            async with engine.connect() as conn:
                print("Starting schema synchronization...")
                for table_name, table in Base.metadata.tables.items():
                    # Get existing columns from DB
                    result = await conn.execute(text(f"SHOW COLUMNS FROM `{table_name}`"))
                    existing_columns = {row[0].lower() for row in result.fetchall()}
                    
                    for column in table.columns:
                        col_name = column.name.lower()
                        if col_name not in existing_columns:
                            print(f"SYNC: Adding missing column `{column.name}` to table `{table_name}`")
                            
                            # Determine column type for SQL
                            col_type = str(column.type).upper()
                            
                            # Custom mapping for specific types
                            if "VARCHAR" in col_type:
                                pass # Keep as is
                            elif "INTEGER" in col_type:
                                col_type = "INT"
                            elif "TEXT" in col_type:
                                col_type = "TEXT"
                            elif "FLOAT" in col_type:
                                col_type = "FLOAT"
                            elif "DATETIME" in col_type:
                                col_type = "DATETIME"
                            elif "JSON" in col_type:
                                col_type = "JSON"
                            elif "LONGBLOB" in col_type or "BLOB" in col_type:
                                col_type = "LONGBLOB"
                                
                            nullable = "NULL" if column.nullable else "NOT NULL"
                            unique = "UNIQUE" if column.unique else ""
                            
                            alter_query = f"ALTER TABLE `{table_name}` ADD COLUMN `{column.name}` {col_type} {nullable} {unique}"
                            try:
                                await conn.execute(text(alter_query))
                                await conn.commit()
                                print(f"SYNC: Column `{column.name}` added successfully.")
                            except Exception as alter_err:
                                print(f"SYNC ERROR: Failed to add column `{column.name}`: {alter_err}")
                print("Schema synchronization complete.")
        except Exception as sync_e:
            print(f"CRITICAL SYNC ERROR: {sync_e}")

        # Initialize Redis
        import redis.asyncio as redis
        redis_pool = redis.ConnectionPool(
            host=settings.REDIS_HOST,
            port=settings.REDIS_PORT,
            decode_responses=True
        )
        app.state.redis = redis.Redis(connection_pool=redis_pool)
        print("Redis connection pool initialized.")

        # Start MQTT Handler
        from .mqtt_handler import MQTTHandler
        
        mqtt_handler = MQTTHandler(
            broker=settings.MQTT_BROKER,
            port=settings.MQTT_PORT,
            username=settings.MQTT_USERNAME,
            password=settings.MQTT_PASSWORD,
            use_tls=settings.MQTT_USE_TLS,
            redis_client=app.state.redis
        )
        
        # Run MQTT handler as a background task
        mqtt_task = asyncio.create_task(mqtt_handler.start())
        app.state.mqtt_handler = mqtt_handler
        
        yield
        
        # Shutdown MQTT handler
        mqtt_task.cancel()
        await app.state.redis.close()
        print("Redis connection closed.")
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
