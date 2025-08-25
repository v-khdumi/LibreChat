#!/bin/bash

# Azure App Service startup script for LibreChat
echo "Starting LibreChat on Azure App Service..."

# Set environment variables
export NODE_ENV=production
export HOST=0.0.0.0
export PORT=${PORT:-8080}

# Print important environment info
echo "NODE_ENV: $NODE_ENV"
echo "HOST: $HOST"
echo "PORT: $PORT"
echo "MONGO_URI: ${MONGO_URI:-'Not Set'}"

# Check if required environment variables are set
if [ -z "$MONGO_URI" ]; then
    echo "Warning: MONGO_URI environment variable is not set"
    echo "Please configure MongoDB connection string in Azure App Service settings"
fi

# Build the application if not already built
echo "Building LibreChat packages..."
npm run build:data-provider
npm run build:data-schemas
npm run build:api

# Build the frontend
echo "Building frontend..."
npm run frontend

# Start the application
echo "Starting LibreChat backend server..."
exec npm run backend