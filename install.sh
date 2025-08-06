#!/bin/bash

# Spotcast Custom - Installation script for Home Assistant
# This script helps install the custom add-on

set -e

echo "🏠 Spotcast Custom - Home Assistant Add-on Installer"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if running on Home Assistant OS
check_ha_environment() {
    if [ -d "/config" ] && [ -d "/addons" ]; then
        print_status "Running on Home Assistant OS"
        HA_ROOT="/addons"
    elif [ -d "/usr/share/hassio/addons" ]; then
        print_status "Running on Supervised Home Assistant"
        HA_ROOT="/usr/share/hassio/addons"
    else
        print_warning "Home Assistant directory structure not detected"
        echo "Please specify the add-ons directory manually:"
        read -p "Enter path to addons directory: " HA_ROOT
        
        if [ ! -d "$HA_ROOT" ]; then
            print_error "Directory does not exist: $HA_ROOT"
            exit 1
        fi
    fi
}

# Create addon directory
create_addon_directory() {
    ADDON_DIR="$HA_ROOT/spotcast_custom"
    
    print_info "Creating add-on directory: $ADDON_DIR"
    
    if [ -d "$ADDON_DIR" ]; then
        print_warning "Add-on directory already exists"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$ADDON_DIR"
            print_status "Removed existing directory"
        else
            print_error "Installation cancelled"
            exit 1
        fi
    fi
    
    mkdir -p "$ADDON_DIR"
    print_status "Created add-on directory"
}

# Copy files
copy_addon_files() {
    print_info "Copying add-on files..."
    
    # Copy all necessary files
    cp config.yaml "$ADDON_DIR/"
    cp requirements.txt "$ADDON_DIR/"
    cp spotcast_server.py "$ADDON_DIR/"
    cp run.sh "$ADDON_DIR/"
    cp Dockerfile "$ADDON_DIR/"
    cp build.yaml "$ADDON_DIR/"
    cp README.md "$ADDON_DIR/"
    
    # Make run script executable
    chmod +x "$ADDON_DIR/run.sh"
    
    print_status "Files copied successfully"
}

# Create repository.yaml if needed
create_repository_config() {
    REPO_FILE="$HA_ROOT/repository.yaml"
    
    if [ ! -f "$REPO_FILE" ]; then
        print_info "Creating repository configuration..."
        
        cat > "$REPO_FILE" << EOF
name: "Custom Add-ons Repository"
url: "https://github.com/custom/addons"
maintainer: "Custom Add-ons"
EOF
        print_status "Created repository.yaml"
    else
        print_info "Repository configuration already exists"
    fi
}

# Set permissions
set_permissions() {
    print_info "Setting correct permissions..."
    
    # Set directory permissions
    chmod -R 755 "$ADDON_DIR"
    
    # Set file permissions
    chmod 644 "$ADDON_DIR"/*.yaml
    chmod 644 "$ADDON_DIR"/*.txt
    chmod 644 "$ADDON_DIR"/*.py
    chmod 644 "$ADDON_DIR"/*.md
    chmod 755 "$ADDON_DIR/run.sh"
    
    print_status "Permissions set correctly"
}

# Display next steps
show_next_steps() {
    echo
    echo "🎉 Installation completed successfully!"
    echo "======================================"
    echo
    print_info "Next steps:"
    echo "1. Restart Home Assistant"
    echo "2. Go to Settings → Add-ons → Add-on Store"
    echo "3. Find 'Spotcast Custom' in the local add-ons"
    echo "4. Install and configure with your Spotify credentials"
    echo
    print_info "Required Spotify setup:"
    echo "1. Go to https://developer.spotify.com/dashboard"
    echo "2. Create a new app"
    echo "3. Get your Client ID and Client Secret"
    echo "4. Add redirect URI: http://YOUR_HA_IP:8000/callback"
    echo
    print_info "Configuration example:"
    echo "  spotify_client_id: 'your_client_id'"
    echo "  spotify_client_secret: 'your_client_secret'"
    echo "  spotify_redirect_uri: 'http://192.168.1.100:8000/callback'"
    echo
    print_warning "Remember to replace YOUR_HA_IP with your actual Home Assistant IP address!"
}

# Main installation process
main() {
    echo
    print_info "Starting installation process..."
    echo
    
    check_ha_environment
    create_addon_directory
    copy_addon_files
    create_repository_config
    set_permissions
    show_next_steps
    
    echo
    print_status "Installation completed! 🚀"
}

# Check if we're in the right directory
if [ ! -f "config.yaml" ] || [ ! -f "spotcast_server.py" ]; then
    print_error "Installation files not found in current directory"
    print_info "Please run this script from the spotcast_custom directory"
    exit 1
fi

# Run main function
main