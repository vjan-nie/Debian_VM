#!/bin/bash

source "$(dirname "$0")/config.sh"

# 1. Host SSH Config with KeepAlives
mkdir -p ~/.ssh
if ! grep -q "Host inception" ~/.ssh/config; then
    cat <<EOF >> ~/.ssh/config

Host inception
    HostName 127.0.0.1
    User $VM_USER
    Port $SSH_PORT
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
    echo "Copy your SSH key into your VM: ssh-copy-id -p $SSH_PORT $VM_USER@127.0.0.1"
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

ssh-copy-id -p "$SSH_PORT" "$VM_USER@127.0.0.1"

# Eject the installation ISO to ensure we boot from the HDD next time
VBoxManage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 1 --device 0 --medium none

# Add host-only DNS entry (remove stale entry if IP is wrong, then append correct one)
if ! grep -q "^${HOSTONLY_VM_IP}[[:space:]].*${DOMAIN}" /etc/hosts; then
    sudo sed -i "/${DOMAIN}/d" /etc/hosts
    echo "${HOSTONLY_VM_IP} ${DOMAIN}" | sudo tee -a /etc/hosts > /dev/null
    echo "✓ Added ${HOSTONLY_VM_IP} ${DOMAIN} to /etc/hosts"
fi
