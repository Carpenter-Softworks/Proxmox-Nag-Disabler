# Proxmox Nag Disabler

Automatically disable the Proxmox "No valid subscription" warning message that appears after logging in.

> **Note:** In a hurry? Go to [Quick Install](#quick-install).

## Description

This project provides an automated solution to suppress the Proxmox subscription nag message that appears in the web interface on systems without a valid subscription license. It works by commenting out the `Ext.Msg.show` call in the `proxmoxlib.js` file, preventing the warning dialog from being displayed.

## Features

- ✓ Automatically disables the subscription nag message
- ✓ Creates a backup of the original `proxmoxlib.js` file before modification
- ✓ Runs automatically on system boot (30 seconds after startup)
- ✓ Runs periodically every 24 hours to reapply if updated
- ✓ Integrates with APT to reapply after package updates/upgrades
- ✓ Uses systemd service and timer for reliable scheduling
- ✓ Minimal dependencies (requires Python3)

## Prerequisites

- Proxmox VE installed and running
- Root or sudo access
- Python3
  - will be installed automatically if missing
- `curl` or `wget` for downloading `disable-nag.sh` (unless present in the working directory)
  - will be installed automatically if missing
- Systemd (standard on modern Proxmox installations)

## How It Works

1. **disable-nag.sh**: The main script that:
   - Checks if the subscription message has already been disabled
   - Creates a backup of `proxmoxlib.js` to `proxmoxlib.js.bak`
   - Uses Python3 regex to find and comment out the `Ext.Msg.show()` call containing "No valid subscription"
   - Restarts the `pveproxy` service to apply changes

2. **install.sh**: The installation script that:
   - Ensures `curl` or `wget` is available to download `disable-nag.sh` if it is not already present locally
   - Attempts to install `curl` or `wget` automatically if needed
   - Ensures Python3 is installed
   - Stages the main script in a persistent location
   - Sets up systemd integration for automatic execution
   - Configures APT hooks for persistence across updates

### Notes

- A backup of the original `proxmoxlib.js` is created as `proxmoxlib.js.bak` before any modifications
  - This file may be overwritten on subsequent executions if the nag code reappears in `proxmoxlib.js`
- The `pveproxy` service is restarted to apply changes (this may briefly interrupt web interface access)
- The nag message may reappear after Proxmox updates; the script handles this automatically via the APT hook
- This script is safe to run multiple times; it checks if modifications have already been applied

## Installation

The installation script will:

- Ensure `curl` or `wget` is available and use it to download `disable-nag.sh` if needed
- Verify Python3 is installed (installs if necessary)
- Copy `disable-nag.sh` to `/root/scripts/`
- Create a systemd service file (`disable-nag.service`)
- Create a systemd timer file (`disable-nag.timer`)
- Install an APT hook to reapply after package updates
- Enable and start the timer

### Quick Install

```bash
# Using curl:
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Carpenter-Softworks/Proxmox-Nag-Disabler/main/install.sh)"

# Using wget:
bash -c "$(wget -qO- https://raw.githubusercontent.com/Carpenter-Softworks/Proxmox-Nag-Disabler/main/install.sh)"
```

### Clone & Install

```bash
git clone https://github.com/yourusername/proxmox-nag-disabler.git
cd proxmox-nag-disabler
./install.sh
```

### No Install

If you only want to run the disable action without installation, you can do that directly with:

```bash
# Using curl:
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Carpenter-Softworks/Proxmox-Nag-Disabler/main/disable-nag.sh)"

# Using wget:
bash -c "$(wget -qO- disable-nag.sh https://raw.githubusercontent.com/Carpenter-Softworks/Proxmox-Nag-Disabler/main/disable-nag.sh)"
```

> **Note:** Running the disable script directly will suppress the nag message immediately, but Proxmox updates may still restore the original code and break the disable. The installer path is more resilient because it also adds periodic and APT-triggered reapplication.

## Usage

After installation, the script runs automatically:

- **On boot**: 30 seconds after system startup
- **Every 24 hours**: Via the systemd timer
- **After package updates**: Via the APT hook

### Manual Execution

To manually run the disable script:

```bash
./disable-nag.sh
```

### Check Timer Status

View the status of the systemd timer:

```bash
systemctl list-timers disable-nag.timer
```

View logs:

```bash
journalctl -u disable-nag.service
```

## Uninstallation

To remove the Proxmox Nag Disabler from your system:

```bash
# As non-root user:
sudo bash uninstall.sh

# As root user:
bash uninstall.sh
```

### Quick Uninstall

```bash
# Using curl:
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Carpenter-Softworks/Proxmox-Nag-Disabler/main/uninstall.sh)"

# Using wget:
bash -c "$(wget -qO- https://raw.githubusercontent.com/Carpenter-Softworks/Proxmox-Nag-Disabler/main/uninstall.sh)"
```

The uninstallation script will:

- Stop and disable the systemd timer and service
- Remove systemd files (`disable-nag.service` and `disable-nag.timer`)
- Remove the APT hook
- Remove the copied script from `/root/scripts/`
- Optionally restore the backup of `proxmoxlib.js` (you'll be prompted)

After uninstallation, the subscription nag message will reappear on your next login, unless you choose not to restore the backup. It may still reappear after updating Proxmox regardless.

> **Note:** The uninstall script does not remove any APT packages, even if the install script installed Python3, `curl` or `wget`.

## License

See [LICENSE.md](LICENSE.md) file for details.
