#!/bin/bash

VM_NAME="Inception_Debian"
ISO_URL="[https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.3.0-amd64-netinst.iso](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.3.0-amd64-netinst.iso)"
ISO_PATH="./debian-netinst.iso"

# 1. Descargar ISO si no existe
if [ ! -f "$ISO_PATH" ]; then
    echo "Downloading Debian ISO..."
    curl -L "$ISO_URL" -o "$ISO_PATH"
fi

# 2. Crear VM básica
VBoxManage createvm --name "$VM_NAME" --ostype "Debian_64" --register
VBoxManage modifyvm "$VM_NAME" --memory 4096 --cpus 1 --vram 16

# 3. Configurar Red y Port Forwarding
VBoxManage modifyvm "$VM_NAME" --nic1 nat
VBoxManage modifyvm "$VM_NAME" --natpf1 "ssh,tcp,,4242,,4242"
VBoxManage modifyvm "$VM_NAME" --natpf1 "http,tcp,,8080,,80"
VBoxManage modifyvm "$VM_NAME" --natpf1 "https,tcp,,443,,443"
VBoxManage modifyvm "$VM_NAME" --natpf1 "db,tcp,,3306,,3306"

# 4. Almacenamiento
VBoxManage storagectl "$VM_NAME" --name "SATA" --add sata
VBoxManage createmedium disk --filename "./$VM_NAME.vdi" --size 20480
VBoxManage storageattach "$VM_NAME" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "./$VM_NAME.vdi"
VBoxManage storagectl "$VM_NAME" --name "IDE" --add ide
VBoxManage storageattach "$VM_NAME" --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium "$ISO_PATH"

echo "VM '$VM_NAME' created with Port Forwarding (SSH: 4242)."