# Optimized Home Assistant add-on Dockerfile for fast builds
ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM $BUILD_FROM

# Install requirements for add-on (including Python 3)
RUN apk add --no-cache \
    python3 \
    py3-pip \
    curl \
    jq \
    gcc \
    musl-dev \
    libffi-dev \
    python3-dev

# Set working directory to app
WORKDIR /app

# Copy requirements and install Python dependencies with optimizations
COPY requirements.txt .

# Install lightweight packages first, then heavy ones separately with limited processes
RUN pip3 install --no-cache-dir --break-system-packages spotipy>=2.22.1 flask>=2.3.3 requests>=2.31.0

# Install pychromecast separately with single process to avoid memory issues 
# Use --only-binary to prefer wheels over source compilation (faster)
RUN pip3 install --no-cache-dir --break-system-packages --prefer-binary pychromecast>=13.0.8

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
    io.hass.version="2.0.2"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s \
    CMD curl -f http://localhost:8000/ || exit 1

# Start script
CMD ["/run.sh"]