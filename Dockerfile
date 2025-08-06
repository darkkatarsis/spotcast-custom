# Use minimal Python image for fastest possible builds
FROM python:3.11-alpine

# Install minimal required packages
RUN apk add --no-cache curl jq

# Create app directory
WORKDIR /app

# Copy requirements first for better Docker layer caching
COPY requirements.txt .

# Install Python dependencies
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy application files
COPY spotcast_server.py .
COPY run.sh /

# Make run script executable
RUN chmod a+x /run.sh

# Set working directory
WORKDIR /app

# Expose port
EXPOSE 8000

# Labels
LABEL \
    io.hass.name="Spotcast Custom" \
    io.hass.description="Custom Spotify Chromecast controller" \
    io.hass.type="addon" \
    io.hass.version="1.0.0"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s \
    CMD curl -f http://localhost:8000/ || exit 1

# Start script
CMD ["/run.sh"]