#!/usr/bin/with-contenv bashio

# ==============================================================================
# Home Assistant Add-on: Spotcast Custom
# Runs the custom Spotcast server
# ==============================================================================

bashio::log.info "Starting Spotcast Custom server..."

# Get configuration
export SPOTIFY_CLIENT_ID=$(bashio::config 'spotify_client_id')
export SPOTIFY_CLIENT_SECRET=$(bashio::config 'spotify_client_secret')
export SPOTIFY_REDIRECT_URI=$(bashio::config 'spotify_redirect_uri')

# Validate required config
if [[ -z "${SPOTIFY_CLIENT_ID}" ]]; then
    bashio::log.fatal "Spotify Client ID is required!"
    bashio::exit.nok
fi

if [[ -z "${SPOTIFY_CLIENT_SECRET}" ]]; then
    bashio::log.fatal "Spotify Client Secret is required!"
    bashio::exit.nok
fi

bashio::log.info "Configuration loaded successfully"
bashio::log.info "Client ID: ${SPOTIFY_CLIENT_ID:0:8}..."
bashio::log.info "Redirect URI: ${SPOTIFY_REDIRECT_URI}"

# Change to app directory
cd /app

# Install dependencies if needed
if [[ ! -f ".installed" ]]; then
    bashio::log.info "Installing Python dependencies..."
    pip3 install -r requirements.txt
    touch .installed
fi

# Start the server
bashio::log.info "Starting Spotcast server on port 8000..."
exec python3 spotcast_server.py