# Spotcast Custom - Home Assistant Add-on

A custom Spotify to Chromecast casting solution for Home Assistant, designed specifically for installations that can't run the standard spotcast integration.

## Features

- Cast Spotify music to any Chromecast device
- Control playback (play, pause, stop)
- Support for playlists, albums, tracks, and artists
- Web-based authentication with Spotify
- RESTful API for Home Assistant integration
- Automatic Chromecast device discovery

## Installation

1. Add this repository to your Home Assistant add-on store
2. Install the "Spotcast Custom" add-on
3. Configure your Spotify credentials (see Configuration section)
4. Start the add-on

## Configuration

### Spotify Application Setup

1. Go to https://developer.spotify.com/dashboard
2. Create a new application
3. Note down your Client ID and Client Secret
4. Add redirect URI: `http://YOUR_HA_IP:8000/callback`

### Add-on Configuration

```yaml
spotify_client_id: "your_spotify_client_id"
spotify_client_secret: "your_spotify_client_secret"
spotify_redirect_uri: "http://YOUR_HA_IP:8000/callback"
device_name: "Your_Chromecast_Name"  # Optional
```

## Usage

### Authentication

1. After starting the add-on, visit: `http://YOUR_HA_IP:8000/auth`
2. Login with your Spotify account
3. Grant permissions to the application

### API Endpoints

- `GET /` - Server status and available endpoints
- `GET /auth` - Start Spotify authentication
- `GET /callback` - OAuth callback (automatic)
- `GET /devices` - List available Chromecast devices
- `GET /status` - Server and device status
- `POST /play` - Start playback
- `POST /pause` - Pause playback
- `POST /stop` - Stop playback

### Playing Music

#### Play a track:
```bash
curl -X POST http://YOUR_HA_IP:8000/play \
  -H "Content-Type: application/json" \
  -d '{
    "device_name": "Living Room TV",
    "uri": "spotify:track:4iV5W9uYEdYUVa79Axb7Rh"
  }'
```

#### Play a playlist:
```bash
curl -X POST http://YOUR_HA_IP:8000/play \
  -H "Content-Type: application/json" \
  -d '{
    "device_name": "Living Room TV", 
    "uri": "spotify:playlist:37i9dQZF1DXcBWIGoYBM5M"
  }'
```

### Home Assistant Integration

Add to your `configuration.yaml`:

```yaml
rest_command:
  spotcast_play:
    url: "http://localhost:8000/play"
    method: POST
    headers:
      Content-Type: "application/json"
    payload: >
      {
        "device_name": "{{ device_name }}",
        "uri": "{{ uri }}"
      }
  
  spotcast_pause:
    url: "http://localhost:8000/pause"
    method: POST
    headers:
      Content-Type: "application/json"
    payload: >
      {
        "device_name": "{{ device_name }}"
      }
```

Then use in automations:

```yaml
automation:
  - alias: "Play morning playlist"
    trigger:
      platform: time
      at: "07:00:00"
    action:
      service: rest_command.spotcast_play
      data:
        device_name: "Kitchen Speaker"
        uri: "spotify:playlist:37i9dQZF1DXcBWIGoYBM5M"
```

## Troubleshooting

### Device Not Found
- Ensure your Chromecast is on the same network as Home Assistant
- Check that the device name matches exactly (case sensitive)
- Try the `/devices` endpoint to see available devices

### Authentication Issues
- Verify your Spotify Client ID and Secret are correct
- Ensure the redirect URI matches exactly in both Spotify app and add-on config
- Check that port 8000 is accessible from your browser

### Playback Issues
- Ensure you have a Spotify Premium account
- Check that the URI format is correct (spotify:track:xxx, spotify:playlist:xxx)
- Verify the device is not already in use by another application

## Support

This is a custom implementation designed for specific use cases where the standard spotcast integration cannot be used. 

## License

MIT License - see LICENSE file for details