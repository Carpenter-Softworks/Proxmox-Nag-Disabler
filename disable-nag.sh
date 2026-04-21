#!/bin/bash

set -e

if ! grep -q "/\* Ext\.Msg\.show" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && grep -q "No valid subscription" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; then
    # Create backup
    cp /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js.bak

    # Comment out the subscription nag message using Python for robust multiline handling
    python3 << 'EOF'
import re

with open('/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js', 'r') as f:
    content = f.read()

# Match Ext.Msg.show({ ... }); containing 'No valid subscription' with nested braces
pattern = r'Ext\.Msg\.show\s*\(\s*\{[\s\S]*?No valid subscription[\s\S]*?\}\s*\)\s*;'
replacement = lambda m: '/* ' + m.group(0) + ' */'
result = re.sub(pattern, replacement, content)

with open('/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js', 'w') as f:
    f.write(result)
EOF

    systemctl restart pveproxy.service
elif grep -q "/\* Ext\.Msg\.show" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; then
    echo "Info: Subscription nag message already commented out"
else
    echo "Warning: 'No valid subscription' string not found in proxmoxlib.js"
fi
