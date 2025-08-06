#!/usr/bin/env python3
"""
Custom Spotcast Server for Home Assistant
Handles Spotify to Chromecast casting without external dependencies
"""

import asyncio
import json
import logging
import os
import time
from typing import Dict, List, Optional, Any
from urllib.parse import urlencode, parse_qs, urlparse

import spotipy
from spotipy.oauth2 import SpotifyOAuth
import pychromecast
from flask import Flask, request, jsonify, redirect, session
import requests

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SpotcastServer:
    """Main Spotcast Server class"""
    
    def __init__(self):
        self.app = Flask(__name__)
        self.app.secret_key = os.urandom(24)
        
        # Spotify configuration
        self.client_id = os.getenv('SPOTIFY_CLIENT_ID', '')
        self.client_secret = os.getenv('SPOTIFY_CLIENT_SECRET', '')
        self.redirect_uri = os.getenv('SPOTIFY_REDIRECT_URI', 'http://localhost:8000/callback')
        
        # Chromecast devices cache
        self.chromecasts: Dict[str, pychromecast.Chromecast] = {}
        self.last_scan = 0
        self.scan_interval = 300  # 5 minutes
        
        # Setup routes
        self._setup_routes()
        
        # Initialize Spotify
        self.sp_oauth = SpotifyOAuth(
            client_id=self.client_id,
            client_secret=self.client_secret,
            redirect_uri=self.redirect_uri,
            scope="user-read-playback-state,user-modify-playback-state,user-read-currently-playing,streaming"
        )
        
    def _setup_routes(self):
        """Setup Flask routes"""
        
        @self.app.route('/')
        def index():
            return jsonify({
                "name": "Spotcast Custom Server",
                "version": "1.0.0",
                "status": "running",
                "endpoints": [
                    "/auth",
                    "/callback", 
                    "/devices",
                    "/play",
                    "/pause",
                    "/stop",
                    "/status"
                ]
            })
        
        @self.app.route('/auth')
        def auth():
            """Start Spotify authentication flow"""
            auth_url = self.sp_oauth.get_authorize_url()
            return redirect(auth_url)
        
        @self.app.route('/callback')
        def callback():
            """Handle Spotify OAuth callback"""
            code = request.args.get('code')
            if code:
                try:
                    token_info = self.sp_oauth.get_access_token(code)
                    session['token_info'] = token_info
                    return jsonify({"status": "success", "message": "Authentication successful"})
                except Exception as e:
                    logger.error(f"Authentication error: {e}")
                    return jsonify({"status": "error", "message": str(e)}), 400
            
            return jsonify({"status": "error", "message": "No authorization code received"}), 400
        
        @self.app.route('/devices')
        def get_devices():
            """Get available Chromecast devices"""
            devices = self._discover_chromecasts()
            return jsonify({
                "chromecasts": [
                    {
                        "name": cc.device.friendly_name,
                        "uuid": str(cc.device.uuid),
                        "model": cc.device.model_name,
                        "status": cc.status.display_name if cc.status else "Unknown"
                    } for cc in devices
                ]
            })
        
        @self.app.route('/play', methods=['POST'])
        def play():
            """Start playback on specified device"""
            data = request.get_json()
            if not data:
                return jsonify({"status": "error", "message": "No data provided"}), 400
            
            device_name = data.get('device_name')
            uri = data.get('uri')  # spotify:track:xxx, spotify:playlist:xxx, etc.
            
            if not device_name or not uri:
                return jsonify({"status": "error", "message": "device_name and uri required"}), 400
            
            try:
                result = self._play_on_device(device_name, uri)
                return jsonify({"status": "success", "result": result})
            except Exception as e:
                logger.error(f"Play error: {e}")
                return jsonify({"status": "error", "message": str(e)}), 500
        
        @self.app.route('/pause', methods=['POST'])
        def pause():
            """Pause playback on specified device"""
            data = request.get_json()
            device_name = data.get('device_name') if data else None
            
            try:
                result = self._pause_device(device_name)
                return jsonify({"status": "success", "result": result})
            except Exception as e:
                logger.error(f"Pause error: {e}")
                return jsonify({"status": "error", "message": str(e)}), 500
        
        @self.app.route('/stop', methods=['POST'])
        def stop():
            """Stop playback on specified device"""
            data = request.get_json()
            device_name = data.get('device_name') if data else None
            
            try:
                result = self._stop_device(device_name)
                return jsonify({"status": "success", "result": result})
            except Exception as e:
                logger.error(f"Stop error: {e}")
                return jsonify({"status": "error", "message": str(e)}), 500
        
        @self.app.route('/status')
        def status():
            """Get server and devices status"""
            devices = self._discover_chromecasts()
            return jsonify({
                "server_status": "running",
                "authenticated": 'token_info' in session,
                "chromecasts_found": len(devices),
                "chromecasts": [
                    {
                        "name": cc.device.friendly_name,
                        "status": cc.status.display_name if cc.status else "Unknown",
                        "app": cc.app_display_name if hasattr(cc, 'app_display_name') else "Unknown"
                    } for cc in devices
                ]
            })
    
    def _get_spotify_client(self) -> Optional[spotipy.Spotify]:
        """Get authenticated Spotify client"""
        token_info = session.get('token_info')
        if not token_info:
            return None
        
        # Check if token needs refresh
        if self.sp_oauth.is_token_expired(token_info):
            token_info = self.sp_oauth.refresh_access_token(token_info['refresh_token'])
            session['token_info'] = token_info
        
        return spotipy.Spotify(auth=token_info['access_token'])
    
    def _discover_chromecasts(self) -> List[pychromecast.Chromecast]:
        """Discover available Chromecast devices"""
        current_time = time.time()
        
        # Cache results for scan_interval seconds
        if current_time - self.last_scan < self.scan_interval and self.chromecasts:
            return list(self.chromecasts.values())
        
        logger.info("Discovering Chromecast devices...")
        
        try:
            # Discover chromecasts
            chromecasts, browser = pychromecast.get_chromecasts()
            
            # Update cache
            self.chromecasts = {cc.device.friendly_name: cc for cc in chromecasts}
            self.last_scan = current_time
            
            logger.info(f"Found {len(chromecasts)} Chromecast devices")
            return chromecasts
            
        except Exception as e:
            logger.error(f"Error discovering chromecasts: {e}")
            return []
    
    def _get_chromecast_by_name(self, device_name: str) -> Optional[pychromecast.Chromecast]:
        """Get Chromecast device by name"""
        chromecasts = self._discover_chromecasts()
        
        for cc in chromecasts:
            if cc.device.friendly_name.lower() == device_name.lower():
                return cc
        
        return None
    
    def _play_on_device(self, device_name: str, uri: str) -> Dict[str, Any]:
        """Play Spotify content on Chromecast device"""
        # Get Spotify client
        sp = self._get_spotify_client()
        if not sp:
            raise Exception("Not authenticated with Spotify")
        
        # Get Chromecast device
        chromecast = self._get_chromecast_by_name(device_name)
        if not chromecast:
            raise Exception(f"Chromecast device '{device_name}' not found")
        
        # Wait for connection
        chromecast.wait()
        
        # Launch Spotify app
        sp_controller = pychromecast.controllers.spotify.SpotifyController()
        chromecast.register_handler(sp_controller)
        
        # Get current user's devices to find our Chromecast
        devices = sp.devices()
        spotify_device_id = None
        
        for device in devices['devices']:
            if device['name'].lower() == device_name.lower():
                spotify_device_id = device['id']
                break
        
        if not spotify_device_id:
            # Try to launch Spotify on Chromecast first
            sp_controller.launch_app()
            time.sleep(3)  # Wait for app to launch
            
            # Try again to find the device
            devices = sp.devices()
            for device in devices['devices']:
                if device['name'].lower() == device_name.lower():
                    spotify_device_id = device['id']
                    break
        
        if not spotify_device_id:
            raise Exception(f"Could not find Spotify device for '{device_name}'")
        
        # Start playback
        if uri.startswith('spotify:'):
            sp.start_playback(device_id=spotify_device_id, uris=[uri])
        else:
            # Assume it's a context URI (playlist, album, etc.)
            sp.start_playback(device_id=spotify_device_id, context_uri=uri)
        
        return {"device": device_name, "uri": uri, "status": "playing"}
    
    def _pause_device(self, device_name: str = None) -> Dict[str, Any]:
        """Pause playback"""
        sp = self._get_spotify_client()
        if not sp:
            raise Exception("Not authenticated with Spotify")
        
        device_id = None
        if device_name:
            devices = sp.devices()
            for device in devices['devices']:
                if device['name'].lower() == device_name.lower():
                    device_id = device['id']
                    break
        
        sp.pause_playback(device_id=device_id)
        return {"status": "paused", "device": device_name}
    
    def _stop_device(self, device_name: str = None) -> Dict[str, Any]:
        """Stop playback"""
        # Pause is effectively stop for Spotify
        return self._pause_device(device_name)
    
    def run(self, host='0.0.0.0', port=8000, debug=False):
        """Run the server"""
        logger.info(f"Starting Spotcast server on {host}:{port}")
        self.app.run(host=host, port=port, debug=debug)

def main():
    """Main entry point"""
    # Load environment variables from options (Home Assistant addon)
    if os.path.exists('/data/options.json'):
        with open('/data/options.json', 'r') as f:
            options = json.load(f)
            
        os.environ['SPOTIFY_CLIENT_ID'] = options.get('spotify_client_id', '')
        os.environ['SPOTIFY_CLIENT_SECRET'] = options.get('spotify_client_secret', '')
        os.environ['SPOTIFY_REDIRECT_URI'] = options.get('spotify_redirect_uri', 'http://localhost:8000/callback')
    
    # Create and run server
    server = SpotcastServer()
    server.run(debug=os.getenv('DEBUG', 'false').lower() == 'true')

if __name__ == '__main__':
    main()