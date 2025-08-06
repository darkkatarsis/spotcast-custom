#!/bin/bash

# ==============================================================================
# Home Assistant Add-on: Spotcast Custom
# Runs the custom Spotcast server
# ==============================================================================

echo "Starting Spotcast Custom server..."

# Load configuration from options.json (standard HA addon method)
if [ -f "/data/options.json" ]; then
    export SPOTIFY_CLIENT_ID=$(jq -r '.spotify_client_id' /data/options.json)
    export SPOTIFY_CLIENT_SECRET=$(jq -r '.spotify_client_secret' /data/options.json)
    export SPOTIFY_REDIRECT_URI=$(jq -r '.spotify_redirect_uri' /data/options.json)
else
    echo "ERROR: Configuration file not found!"
    exit 1
fi

# Validate required config
if [[ -z "${SPOTIFY_CLIENT_ID}" || "${SPOTIFY_CLIENT_ID}" == "null" ]]; then
    echo "ERROR: Spotify Client ID is required!"
    exit 1
fi

if [[ -z "${SPOTIFY_CLIENT_SECRET}" || "${SPOTIFY_CLIENT_SECRET}" == "null" ]]; then
    echo "ERROR: Spotify Client Secret is required!"
    exit 1
fi

echo "Configuration loaded successfully"
echo "Client ID: ${SPOTIFY_CLIENT_ID:0:8}..."
echo "Redirect URI: ${SPOTIFY_REDIRECT_URI}"

# Change to app directory
cd /app

# Start the server
echo "Starting Spotcast server on port 8000..."
exec python3 spotcast_server.py