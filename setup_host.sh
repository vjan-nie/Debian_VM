#!/bin/bash

# 1. Host SSH Config with KeepAlives
mkdir -p ~/.ssh
if ! grep -q "Host inception" ~/.ssh/config; then
    cat <<EOF >> ~/.ssh/config

Host inception
    HostName 127.0.0.1
    User login
    Port 4242
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    # --- Keepalive signal to VirtualBox ---
    ServerAliveInterval 15
    ServerAliveCountMax 4
    TCPKeepAlive yes
EOF
fi

# 2. Inject SSH key
if [ -f ~/.ssh/id_rsa.pub ] || [ -f ~/.ssh/id_ed25519.pub ]; then
    echo "Copy your SSH key into your VM: ssh-copy-id -p 4242 login@127.0.0.1"
fi

# 3. VS Code Patch (Python)
python3 -c "
import json, os
p = os.path.expanduser('~/.config/Code/User/settings.json')
try:
    with open(p, 'r') as f: s = json.load(f)
except:
    s = {}
s['remote.SSH.useLocalServer'] = False
s['remote.SSH.enableDynamicForwarding'] = False
s['remote.SSH.useExecServer'] = False
s['remote.SSH.connectTimeout'] = 60
with open(p, 'w') as f: json.dump(s, f, indent=4)
" 2>/dev/null
echo "✓ Host configuration succeed: SSH keepalive and VS Code patch ready."
