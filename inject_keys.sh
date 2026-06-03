#!/bin/bash

source "$(dirname "$0")/config.sh"

# Get real host IP in local network
HOST_IP=$(hostname -I | awk '{print $1}')
PRESEED_URL="http://$HOST_IP:8000/preseed.cfg"

echo "Using Host IP for preseed: $HOST_IP"

echo "Generating preseed and firstboot script from templates..."
set -a; . "$(dirname "$0")/config.sh"; set +a
envsubst '${VM_USER} ${VM_PASSWORD}' \
    < preseed.cfg.template > preseed.cfg
envsubst '${HOSTONLY_VM_IP} ${VM_USER} ${DOMAIN}' \
    < firstboot-inception.sh.template > firstboot-inception.sh
chmod +x firstboot-inception.sh

echo "Ensuring port 8000 is free..."
fuser -k 8000/tcp 2>/dev/null || true
pkill -f "[p]ython3 -m http.server 8000" 2>/dev/null || true

echo "Starting temporary HTTP server on port 8000..."
python3 -m http.server 8000 --bind 0.0.0.0 > server.log 2>&1 &
SERVER_PID=$!

echo "Starting VM: $VM_NAME..."
VBoxManage startvm "$VM_NAME" --type gui

echo "Waiting for boot menu..."
sleep 10

# Open boot editor
VBoxManage controlvm "$VM_NAME" keyboardputscancode 0f 8f
sleep 1

# Clear line with 110 backspaces
echo "Clearing default boot line..."
for i in {1..110}; do
    VBoxManage controlvm "$VM_NAME" keyboardputscancode 0e 8e
done
sleep 1

# Type full clean command
VBoxManage controlvm "$VM_NAME" keyboardputstring "/install.amd/vmlinuz vga=788 initrd=/install.amd/initrd.gz auto=true url=$PRESEED_URL priority=critical netcfg/choose_interface=auto --- "
sleep 1
# Send the 'ENTER' key to start the automated installation
VBoxManage controlvm "$VM_NAME" keyboardputscancode 1c 9c

echo -e "\n\033[32m[SUCCESS]\033[0m Ghost typing complete! The installation has started automatically."
echo -e "\033[33m⚠ VERY IMPORTANT: Leave this terminal open.\033[0m"
echo "The Python HTTP server needs to stay alive while Debian downloads the preseed file."
echo "Wait for the VM to reboot and show the login screen."
read -p "Press ENTER here ONLY AFTER the installation is fully complete to stop the server..."

kill $SERVER_PID
echo "HTTP server stopped. You are ready to go!"