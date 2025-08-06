#!/usr/bin/env python3
"""
Local test script for Spotcast Custom
Use this to test the server locally before deploying as Home Assistant add-on
"""

import os
import sys
import time
import requests
import json
from spotcast_server import SpotcastServer

def test_server():
    """Test the Spotcast server functionality"""
    
    print("🧪 Testing Spotcast Custom Server")
    print("=" * 50)
    
    # Check if environment variables are set
    required_env = ['SPOTIFY_CLIENT_ID', 'SPOTIFY_CLIENT_SECRET']
    missing_env = [var for var in required_env if not os.getenv(var)]
    
    if missing_env:
        print("❌ Missing required environment variables:")
        for var in missing_env:
            print(f"   - {var}")
        print("\nSet them with:")
        print("export SPOTIFY_CLIENT_ID='your_client_id'")
        print("export SPOTIFY_CLIENT_SECRET='your_client_secret'")
        return False
    
    print("✅ Environment variables configured")
    
    # Start server in background
    print("🚀 Starting server...")
    server = SpotcastServer()
    
    # Test server endpoints
    base_url = "http://localhost:8000"
    
    print(f"🌐 Server running at {base_url}")
    print("\n📋 Available endpoints:")
    print(f"   - {base_url}/            (Server status)")
    print(f"   - {base_url}/auth        (Spotify authentication)")
    print(f"   - {base_url}/devices     (Chromecast devices)")
    print(f"   - {base_url}/status      (Server status)")
    
    print("\n🔧 Next steps:")
    print("1. Visit http://localhost:8000/auth to authenticate with Spotify")
    print("2. Check http://localhost:8000/devices to see your Chromecast devices")
    print("3. Use POST requests to /play, /pause, /stop for playback control")
    
    print("\n📖 Example play request:")
    print("curl -X POST http://localhost:8000/play \\")
    print("  -H 'Content-Type: application/json' \\")
    print("  -d '{\"device_name\": \"Your_Device\", \"uri\": \"spotify:track:4iV5W9uYEdYUVa79Axb7Rh\"}'")
    
    # Run server
    try:
        server.run(debug=True)
    except KeyboardInterrupt:
        print("\n\n👋 Server stopped")
        return True

def setup_environment():
    """Interactive setup for environment variables"""
    print("🔧 Environment Setup")
    print("=" * 30)
    
    # Check if .env file exists
    env_file = ".env"
    if os.path.exists(env_file):
        print(f"✅ Found {env_file} file")
        try:
            from dotenv import load_dotenv
            load_dotenv()
            print("✅ Environment variables loaded from .env")
        except ImportError:
            print("⚠️  python-dotenv not installed, loading manually...")
            with open(env_file, 'r') as f:
                for line in f:
                    if '=' in line and not line.startswith('#'):
                        key, value = line.strip().split('=', 1)
                        os.environ[key] = value.strip('"\'')
    else:
        print("📝 Creating .env file...")
        
        client_id = input("Enter your Spotify Client ID: ").strip()
        client_secret = input("Enter your Spotify Client Secret: ").strip()
        redirect_uri = input("Enter redirect URI (default: http://localhost:8000/callback): ").strip()
        
        if not redirect_uri:
            redirect_uri = "http://localhost:8000/callback"
        
        env_content = f"""# Spotify configuration for Spotcast Custom
SPOTIFY_CLIENT_ID="{client_id}"
SPOTIFY_CLIENT_SECRET="{client_secret}"
SPOTIFY_REDIRECT_URI="{redirect_uri}"
"""
        
        with open(env_file, 'w') as f:
            f.write(env_content)
        
        print(f"✅ Created {env_file}")
        
        # Load the variables
        os.environ['SPOTIFY_CLIENT_ID'] = client_id
        os.environ['SPOTIFY_CLIENT_SECRET'] = client_secret
        os.environ['SPOTIFY_REDIRECT_URI'] = redirect_uri

def main():
    """Main function"""
    if len(sys.argv) > 1 and sys.argv[1] == "setup":
        setup_environment()
    else:
        # Check if we need setup
        if not os.getenv('SPOTIFY_CLIENT_ID'):
            print("🔧 First time setup required...")
            setup_environment()
        
        test_server()

if __name__ == "__main__":
    main()