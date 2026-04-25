# Proxmox Nag Disabler

This project provides an automated solution to suppress the Proxmox subscription nag message that appears in the web interface on systems without a valid subscription license. It works by commenting out the `Ext.Msg.show` call in the `proxmoxlib.js` file, preventing the warning dialog from being displayed.

> **Note:** In a hurry? Go to [Quick Install](#quick-install).

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [How It Works](#how-it-works)
  - [Notes](#notes)
- [Installation](#installation)
  - [Quick Install](#quick-install)
  - [No Install](#no-install)
- [Usage](#usage)
  - [Manual Execution](#manual-execution)
  - [Check Timer Status](#check-timer-status)
- [Uninstallation](#uninstallation)
  - [Quick Uninstall](#quick-uninstall)
- [License](#license)

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
   - Enables the systemd timer and ensures the disable action is reapplied automatically

3. **uninstall.sh**: The uninstallation script that:
   - Stops and disables the systemd service and timer
   - Removes systemd unit files and the APT hook
   - Deletes the staged `/root/scripts/disable-nag.sh`
   - Optionally restores the original `proxmoxlib.js` backup

### Notes

- A backup of the original `proxmoxlib.js` is created as `proxmoxlib.js.bak` before any modifications
  - This file may be overwritten on subsequent executions if the nag code reappears in `proxmoxlib.js`
- The `pveproxy` service is restarted to apply changes (this may briefly interrupt web interface access)
- The nag message may reappear after Proxmox updates; the script handles this automatically via the APT hook
- This script is safe to run multiple times; it checks if modifications have already been applied

## Installation

The installation script sets up the disable action persistently by staging `disable-nag.sh`, enabling a systemd timer/service, and installing an APT hook.

```bash
git clone https://github.com/yourusername/proxmox-nag-disabler.git
cd proxmox-nag-disabler
./install.sh
```

### Quick Install

**Using curl:**

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Carpenter-Softworks/Proxmox-Nag-Disabler/main/install.sh)"
```

**Using wget:**

```bash
bash -c "$(wget -qO- https://raw.githubusercontent.com/Carpenter-Softworks/Proxmox-Nag-Disabler/main/install.sh)"
```

### No Install

**NOT** recommended: If you only want to run the disable action without installation, simply use `disable-nag.sh` directly.

> **Note:** Running the disable script directly will suppress the nag message immediately, but Proxmox updates may still restore the original code and break the disable. The installer path is more resilient.

**Using curl:**

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Carpenter-Softworks/Proxmox-Nag-Disabler/main/disable-nag.sh)"
```

**Using wget:**

```bash
bash -c "$(wget -qO- https://raw.githubusercontent.com/Carpenter-Softworks/Proxmox-Nag-Disabler/main/disable-nag.sh)"
```

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

The uninstallation script removes the timer/service, APT hook, and staged script, and can optionally restore the original `proxmoxlib.js` backup.

After uninstallation, the subscription nag message will reappear on your next login, unless you choose not to restore the backup. It may still reappear after updating Proxmox regardless.

> **Note:** The uninstall script does not remove any APT packages.

**As root user:**

```bash
./uninstall.sh
```

**As non-root user:**

```bash
sudo ./uninstall.sh
```

### Quick Uninstall

> **Note:** As non-root user, you have to use `sudo bash -c "$(...)"` rather than `bash -c "$(...)"`

**Using curl:**

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Carpenter-Softworks/Proxmox-Nag-Disabler/main/uninstall.sh)"
```

**Using wget:**

```bash
bash -c "$(wget -qO- https://raw.githubusercontent.com/Carpenter-Softworks/Proxmox-Nag-Disabler/main/uninstall.sh)"
```

## License

See [LICENSE.md](LICENSE.md) file for details.
