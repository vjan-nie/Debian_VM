#!/bin/bash

VM_NAME="Inception_Debian"

# --- 1. Storage & Cluster Portability Logic ---
# Check if we are in the 42 Madrid cluster (using /sgoinfre for persistent local storage)
# If true, it saves the 20GB disk on the physical Mac, avoiding NFS quota limits.
if [ -d "/sgoinfre/$USER" ]; then
    echo "Cluster 42 environment detected. Using /sgoinfre for storage."
    BASE_DIR="/sgoinfre/$USER/inception_vm"
else
    echo "Local environment detected. Using current directory."
    BASE_DIR="."
fi

# Ensure the working directory exists
mkdir -p "$BASE_DIR"

# Define absolute paths for heavy files so VirtualBox knows exactly where they are
ISO_PATH="$BASE_DIR/debian-13.3.0-amd64-netinst.iso"
DISK_PATH="$BASE_DIR/${VM_NAME}.vdi"

# --- 2. ISO Download Logic ---
# Download the Debian ISO only if it's not already in our target directory
if [ ! -f "$ISO_PATH" ]; then
    echo "Downloading Debian ISO to $BASE_DIR..."
    curl -L "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.3.0-amd64-netinst.iso" -o "$ISO_PATH"
else
    echo "Found local ISO: $ISO_PATH"
fi

echo "Creating Virtual Machine: $VM_NAME..."

# --- 3. VirtualBox Hardware Creation ---
# Create the VM and register it in VirtualBox
VBoxManage createvm --name "$VM_NAME" --ostype "Debian_64" --register

# Modify basic system settings (4GB RAM, 1 CPU, 16MB Video RAM)
VBoxManage modifyvm "$VM_NAME" --memory 4096 --cpus 1 --vram 16
VBoxManage modifyvm "$VM_NAME" --boot1 dvd --boot2 disk --boot3 none --boot4 none
VBoxManage modifyvm "$VM_NAME" --pae on

# Configure Network and Port Forwarding (NAT mode is default but explicitly set)
VBoxManage modifyvm "$VM_NAME" --nic1 nat
VBoxManage modifyvm "$VM_NAME" --natpf1 "ssh,tcp,,4242,,4242"
VBoxManage modifyvm "$VM_NAME" --natpf1 "http,tcp,,8080,,80"
VBoxManage modifyvm "$VM_NAME" --natpf1 "https,tcp,,443,,443"
VBoxManage modifyvm "$VM_NAME" --natpf1 "db,tcp,,3306,,3306"
# Force the virtual network cable to be 'plugged in'
VBoxManage modifyvm "$VM_NAME" --cableconnected1 on
# Use the highly compatible Intel PRO/1000 MT Desktop adapter
VBoxManage modifyvm "$VM_NAME" --nictype1 82543GC

# Create Storage Controllers (SATA for Hard Disk, IDE for CD/DVD drive)
VBoxManage storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAhci
VBoxManage storagectl "$VM_NAME" --name "IDE Controller" --add ide

# Create Virtual Hard Disk (dynamically allocated VDI) and Attach it
# We silently remove the old disk if it exists to avoid UUID conflicts during creation
if [ -f "$DISK_PATH" ]; then
    rm -f "$DISK_PATH"
fi
VBoxManage createmedium disk --filename "$DISK_PATH" --size 20480 --format VDI
VBoxManage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$DISK_PATH"

# Attach the Debian ISO to the virtual CD/DVD drive
VBoxManage storageattach "$VM_NAME" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "$ISO_PATH"

echo "VM '$VM_NAME' created successfully!"