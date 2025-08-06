# Standard Home Assistant add-on Dockerfile (following official tutorial)
ARG BUILD_FROM
FROM $BUILD_FROM

# Install requirements for add-on (including Python 3)
RUN apk add --no-cache \
    python3 \
    py3-pip \
    curl \
    jq

# Set working directory to app
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy all application files
COPY spotcast_server.py .
COPY run.sh /
RUN chmod a+x /run.sh

# Expose port
EXPOSE 8000

# Labels
LABEL \
    io.hass.name="Spotcast Custom" \
    io.hass.description="Custom Spotify Chromecast controller" \
    io.hass.type="addon" \
    io.hass.version="1.0.5"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s \
    CMD curl -f http://localhost:8000/ || exit 1

# Start script
CMD ["/run.sh"]