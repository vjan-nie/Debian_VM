#!/bin/bash

VM_NAME="Inception_Debian"
# Cambiamos a 8080 para evitar conflictos
PRESEED_URL="http://10.0.2.2:8080/preseed.cfg"

echo "Ensuring port 8080 is free..."
# Matamos cualquier proceso en el puerto 8080
fuser -k 8080/tcp 2>/dev/null || true
pkill -f "[p]ython3 -m http.server 8080" 2>/dev/null || true

echo "Starting temporary HTTP server on port 8080..."
# El flag --bind 0.0.0.0 es la CLAVE
python3 -m http.server 8080 --bind 0.0.0.0 > server.log 2>&1 &
SERVER_PID=$!

echo "Starting VM: $VM_NAME..."
VBoxManage startvm "$VM_NAME" --type gui

echo "Waiting 10 seconds for the Debian boot menu..."
sleep 10

# --- GHOST TYPING ---
VBoxManage controlvm "$VM_NAME" keyboardputscancode 0f 8f
sleep 1

echo "Clearing default boot line..."
for i in {1..110}; do
    VBoxManage controlvm "$VM_NAME" keyboardputscancode 0e 8e
done
sleep 1

VBoxManage controlvm "$VM_NAME" keyboardputstring "/install.amd/vmlinuz vga=788 initrd=/install.amd/initrd.gz auto=true url=$PRESEED_URL priority=critical netcfg/choose_interface=auto --- "
sleep 1

# VBoxManage controlvm "$VM_NAME" keyboardputscancode 1c 9c

echo -e "\n\033[33m[REVISIÓN VISUAL]\033[0m"
echo "URL actual: $PRESEED_URL"
echo "Si es correcto, pulsa ENTER en VirtualBox."

read -p ""
kill $SERVER_PID
echo "HTTP server stopped."