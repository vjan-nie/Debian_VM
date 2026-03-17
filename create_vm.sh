#!/bin/bash

VM_NAME="Inception_Debian"

# Check storage environment (Local vs Cluster)
if [ -d "/sgoinfre/$USER" ]; then
    echo "Cluster 42 environment detected. Using /sgoinfre for storage."
    BASE_DIR="/sgoinfre/$USER/inception_vm"
else
    echo "Local environment detected. Using current directory."
    BASE_DIR="."
fi

mkdir -p "$BASE_DIR"
ISO_PATH="$BASE_DIR/debian-13.3.0-amd64-netinst.iso"
DISK_PATH="$BASE_DIR/${VM_NAME}.vdi"

# Download ISO if missing
if [ ! -f "$ISO_PATH" ]; then
    echo "Downloading Debian ISO..."
    curl -L "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.3.0-amd64-netinst.iso" -o "$ISO_PATH"
fi

echo "Creating Virtual Machine: $VM_NAME..."
VBoxManage createvm --name "$VM_NAME" --ostype "Debian_64" --register

# System settings
VBoxManage modifyvm "$VM_NAME" --memory 4096 --cpus 1 --vram 16
VBoxManage modifyvm "$VM_NAME" --boot1 dvd --boot2 disk --boot3 none --boot4 none

# Network configuration
VBoxManage modifyvm "$VM_NAME" --nic1 nat
# Standard Inception ports
VBoxManage modifyvm "$VM_NAME" --natpf1 "ssh,tcp,,4242,,22"
VBoxManage modifyvm "$VM_NAME" --natpf1 "http,tcp,,8080,,80"
VBoxManage modifyvm "$VM_NAME" --natpf1 "https,tcp,,443,,443"
VBoxManage modifyvm "$VM_NAME" --natpf1 "db,tcp,,3306,,3306"

VBoxManage modifyvm "$VM_NAME" --cableconnected1 on
VBoxManage modifyvm "$VM_NAME" --nictype1 82543GC

# Storage controllers
VBoxManage storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAhci
VBoxManage storagectl "$VM_NAME" --name "IDE Controller" --add ide

# Disk attachment
if [ -f "$DISK_PATH" ]; then rm -f "$DISK_PATH"; fi
VBoxManage createmedium disk --filename "$DISK_PATH" --size 20480 --format VDI
VBoxManage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$DISK_PATH"
VBoxManage storageattach "$VM_NAME" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "$ISO_PATH"

echo "VM '$VM_NAME' created successfully!"