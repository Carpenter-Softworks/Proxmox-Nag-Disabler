#!/bin/bash

set -e

INSTALL_DIR="/root/scripts"

echo "Installing Proxmox Subscription Nag Disabler..."

# Check if python3 is installed
if ! command -v python3 &> /dev/null; then
    echo "Python3 not found. Attempting to install..."
    
    if [ "$EUID" -eq 0 ]; then
        # Running as root
        apt update && apt install -y python3
    elif command -v sudo &> /dev/null; then
        # Not root but sudo is available
        sudo apt update && sudo apt install -y python3
    else
        echo "Error: Failed to install Python3."
        echo "Please run this script as root or install sudo, then try again."
        exit 1
    fi

    if ! command -v python3 &> /dev/null; then
        echo "Error: Failed to install Python3."
        echo "Please install Python3 manually, then try again."
        exit 1
    fi
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy the script
mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/disable-nag.sh" "$INSTALL_DIR/"

# Check if disable-nag.sh exists
DISABLE_NAG_SCRIPT="$INSTALL_DIR/disable-nag.sh"
if [ ! -f "$DISABLE_NAG_SCRIPT" ]; then
    echo "Error: disable-nag.sh not found in $SCRIPT_DIR"
    exit 1
fi

# Make the script executable
chmod +x "$DISABLE_NAG_SCRIPT"

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

# Create APT hook
tee /etc/apt/apt.conf.d/99disable-nag > /dev/null << EOF
APT::Update::Post-Invoke {"$DISABLE_NAG_SCRIPT";};
DPkg::Post-Invoke {"$DISABLE_NAG_SCRIPT";};
EOF

# Reload systemd daemon and enable timer
systemctl daemon-reload
systemctl enable disable-nag.timer
systemctl start disable-nag.timer

echo "✓ Installation complete!"
echo "✓ Systemd service and timer installed"
echo "✓ APT hook installed"
echo ""
echo "The script will run:"
echo "  - 30 seconds after boot"
echo "  - Every 24 hours"
echo "  - After package updates/upgrades"
echo ""
echo "Check status: systemctl list-timers"
