#!/bin/bash

# Wait for database to be ready
echo "Waiting for database..."
while ! nc -z $DB_HOST $DB_PORT; do
  sleep 1
done
echo "Database is up!"

# Run migrations if any (Add command here if using Alembic)
# alembic upgrade head

# Start the application
echo "Starting Uvicorn..."
exec uvicorn solar_backend.main:app --host 0.0.0.0 --port 8006
