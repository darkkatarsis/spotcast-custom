# Use minimal Python image for fastest possible builds
FROM python:3.11-alpine

# Install minimal required packages for networking and compilation
RUN echo "🔧 Installing system packages..." && \
    apk add --no-cache \
    curl \
    jq \
    gcc \
    musl-dev \
    libffi-dev && \
    echo "✅ System packages installed!"

# Create app directory
WORKDIR /app

# Copy requirements first for better Docker layer caching
COPY requirements.txt .

# Install Python dependencies with verbose output and optimization
RUN echo "🔧 Installing Python packages..." && \
    pip3 install --no-cache-dir --verbose --timeout 300 \
    spotipy==2.22.1 \
    flask==2.3.3 \
    requests==2.31.0 && \
    echo "🔧 Installing pychromecast (may take longer)..." && \
    pip3 install --no-cache-dir --verbose --timeout 300 pychromecast==13.0.8 && \
    echo "✅ All packages installed successfully!"

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
    io.hass.version="1.0.3"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s \
    CMD curl -f http://localhost:8000/ || exit 1

# Start script
CMD ["/run.sh"]