#!/bin/bash

set -e

echo "Uninstalling Proxmox Subscription Nag Disabler..."

# Stop and disable the timer
systemctl stop disable-nag.timer 2>/dev/null || true
systemctl disable disable-nag.timer 2>/dev/null || true

# Stop and disable the service
systemctl stop disable-nag.service 2>/dev/null || true
systemctl disable disable-nag.service 2>/dev/null || true

# Remove systemd files
rm -f /etc/systemd/system/disable-nag.service
rm -f /etc/systemd/system/disable-nag.timer

# Remove APT hook
rm -f /etc/apt/apt.conf.d/99disable-nag

# Remove the copied script
rm -f /root/scripts/disable-nag.sh

# Remove /root/scripts directory if it's now empty
rmdir /root/scripts 2>/dev/null || true

# Reload systemd daemon
systemctl daemon-reload

# Restore backup if it exists
PROXMOX_LIB_FILE="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"
BACKUP_FILE="$PROXMOX_LIB_FILE.bak"

if [ -f "$BACKUP_FILE" ]; then
    read -p "Found backup of proxmoxlib.js. Restore it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp "$BACKUP_FILE" "$PROXMOX_LIB_FILE"
        systemctl restart pveproxy.service
        echo "✓ Backup restored and pveproxy restarted"
    else
        echo "Note: Backup file kept at $BACKUP_FILE"
    fi
fi

echo "✓ Uninstallation complete!"
echo "✓ Systemd service and timer removed"
echo "✓ APT hook removed"
