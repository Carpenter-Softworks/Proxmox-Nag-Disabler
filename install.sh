#!/bin/bash

set -e

INSTALL_DIR="/root/scripts"
GITHUB_RAW_URL="https://raw.githubusercontent.com/Carpenter-Softworks/Proxmox-Nag-Disabler/main"

echo "Installing Proxmox Subscription Nag Disabler..."

# Function to download a file
download_file() {
    local url="$1"
    local output="$2"
    
    if command -v curl &> /dev/null; then
        curl -fsSL "$url" -o "$output"
        return $?
    elif command -v wget &> /dev/null; then
        wget -qO "$output" "$url"
        return $?
    else
        return 1
    fi
}

# Function to install a package
install_package() {
    local tool="$1"
    
    if [ "$EUID" -eq 0 ]; then
        # Running as root
        apt update && apt install -y "$tool"
    elif command -v sudo &> /dev/null; then
        # Not root but sudo is available
        sudo apt update && sudo apt install -y "$tool"
    else
        return 1
    fi
}

# Check if disable-nag.sh exists in current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_DISABLE_NAG="$SCRIPT_DIR/disable-nag.sh"

if [ ! -f "$LOCAL_DISABLE_NAG" ]; then
    echo "disable-nag.sh not found locally. Attempting to download..."
    
    # Try to download with curl or wget
    if ! download_file "$GITHUB_RAW_URL/disable-nag.sh" "$LOCAL_DISABLE_NAG" 2>/dev/null; then
        echo "Warning: curl/wget not available. Attempting to install curl..."
        
        if ! install_package curl; then
            echo "Warning: Failed to install curl. Attempting to install wget..."
            
            if ! install_package wget; then
                echo "Error: Failed to install curl or wget."
                echo "Please install curl or wget manually, then try again."
                exit 1
            else
                echo "✓ Installed wget"
            fi
        else
            echo "✓ Installed curl"
        fi
        
        # Try download again after installing a tool
        if ! download_file "$GITHUB_RAW_URL/disable-nag.sh" "$LOCAL_DISABLE_NAG"; then
            echo "Error: Failed to download disable-nag.sh from GitHub"
            exit 1
        fi
    fi
    
    echo "✓ Downloaded disable-nag.sh"
fi

# Check if python3 is installed
if ! command -v python3 &> /dev/null; then
    echo "Python3 not found. Attempting to install..."
    
    if ! install_package python3; then
        echo "Error: Failed to install Python3."
        echo "Please run this script as root or install sudo, then try again."
        exit 1
    fi

    if ! command -v python3 &> /dev/null; then
        echo "Error: Failed to install Python3."
        echo "Please install Python3 manually, then try again."
        exit 1
    fi
    
    echo "✓ Installed Python3"
fi

# Copy the script to install directory
mkdir -p "$INSTALL_DIR"
cp "$LOCAL_DISABLE_NAG" "$INSTALL_DIR/"

# Check if disable-nag.sh exists
DISABLE_NAG_SCRIPT="$INSTALL_DIR/disable-nag.sh"
if [ ! -f "$DISABLE_NAG_SCRIPT" ]; then
    echo "Error: Failed to copy disable-nag.sh to $INSTALL_DIR"
    exit 1
fi

# Make the script executable
chmod +x "$DISABLE_NAG_SCRIPT"

echo "✓ Installed disable-nag.sh"

# Create systemd service file
tee /etc/systemd/system/disable-nag.service > /dev/null << EOF
[Unit]
Description=Disable Proxmox Subscription Nag
After=network.target

[Service]
Type=oneshot
ExecStart=$DISABLE_NAG_SCRIPT
User=root

[Install]
WantedBy=multi-user.target
EOF

echo "✓ Systemd service installed"

# Create systemd timer file
tee /etc/systemd/system/disable-nag.timer > /dev/null << EOF
[Unit]
Description=Run Disable Nag Script on Boot and Periodically

[Timer]
OnBootSec=30sec
OnUnitActiveSec=24h

[Install]
WantedBy=timers.target
EOF

echo "✓ Systemd timer installed"

# Create APT hook
tee /etc/apt/apt.conf.d/99disable-nag > /dev/null << EOF
APT::Update::Post-Invoke {"$DISABLE_NAG_SCRIPT";};
DPkg::Post-Invoke {"$DISABLE_NAG_SCRIPT";};
EOF

echo "✓ APT hook installed"

# Reload systemd daemon and enable timer
systemctl daemon-reload
systemctl enable disable-nag.timer
systemctl start disable-nag.timer

echo "✓ Installation complete!"
echo ""
echo "The script will run:"
echo "  - 30 seconds after boot"
echo "  - Every 24 hours"
echo "  - After package updates/upgrades"
echo ""
echo "Check status: systemctl list-timers"
