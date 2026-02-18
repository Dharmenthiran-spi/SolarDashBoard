import sys
from pathlib import Path

# Ensure backend directory is in path
backend_dir = str(Path(__file__).resolve().parent.parent)
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from solar_backend.database import engine, Base
from solar_backend.routes import company, employee, customer, machine, report, dashboard, machine_status, auth

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield

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

@app.get("/")
def root():
    return {"message": "Welcome to SolarDashBoard API"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("solar_backend.main:app", host="0.0.0.0", port=8006, reload=True)
