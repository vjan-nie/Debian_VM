# 🚀 Inception Debian VM Automator

A fully automated, zero-touch deployment script for a Debian 13 Virtual Machine using VirtualBox. This project was built to serve as the foundational infrastructure for the **42 School Inception project**, providing a reproducible, robust, and headless installation process.

## 🌟 Acknowledgements & Inspiration

This project was heavily inspired by the comprehensive work of LESdylan. You can check out his awesome repository here:
👉 **[[Link to LESdylan's Repository](https://github.com/LESdylan/setup_arch_linux)]**

---

## 🏗️ How It Works (Architecture)

The deployment relies on a `Makefile` that orchestrates several bash scripts. It creates the VM, downloads the Debian ISO, spins up a temporary HTTP server to host a `preseed.cfg` file, and uses a "Ghost Typist" mechanism to inject the boot parameters into the VirtualBox console.

~~~mermaid
sequenceDiagram
    participant U as User
    participant M as Makefile
    participant V as create_vm.sh
    participant I as inject_keys.sh
    participant H as setup_host.sh
    participant VB as VirtualBox (Debian)
    
    U->>M: make install
    M->>V: Build Virtual Hardware
    V-->>M: VM Created
    M->>I: Start HTTP Server & Boot VM
    I->>VB: Send Keyboard Scancodes (TAB, Backspace...)
    I->>VB: Type: url=http://<HOST_IP>:8000/preseed.cfg
    VB->>I: GET /preseed.cfg
    I-->>VB: 200 OK (Serves Preseed)
    VB->>VB: Automated OS Installation
    VB-->>U: Reboot & Login Screen
    U->>I: Press ENTER (Kills HTTP Server)
    M->>H: Configure SSH & VS Code
    H-->>U: Setup Complete!
~~~

---

## 🛠️ Quick Start

Deploying your environment is as simple as running a single command:

~~~bash
# 1. Clean any previous conflicting VMs or disks
make fclean

# 2. Build, install, and configure everything automatically
make
~~~

Once the installation finishes and you see the Debian login screen, just press `ENTER` in your terminal. You can then access your machine instantly without typing passwords:

~~~bash
ssh inception
~~~

---

## 🧠 The Journey: Challenges & Solutions

Building a completely unattended installation in VirtualBox is tricky. Here are the main roadblocks we hit and how we solved them:

### 1. The "Ghost Typist" Collision
**Problem:** Sending the boot parameters via `VBoxManage controlvm keyboardputstring` was colliding with the default Debian boot string (e.g., `/install.amd/vmlinuz`), creating corrupted commands that halted the bootloader.
**Solution:** We implemented a "Deep Clean" loop that sends 110 `Backspace` scancodes (`0e 8e`) before typing our custom boot path from scratch.

~~~bash
# Snippet from inject_keys.sh: Clearing the boot line safely
for i in {1..110}; do
    VBoxManage controlvm "$VM_NAME" keyboardputscancode 0e 8e
done
~~~

### 2. The Silent Blue Screen (NAT Loopback Block)
**Problem:** The Debian installer successfully configured the network via DHCP but hung silently on a blue screen. The Python HTTP server logs were empty. VirtualBox NAT was blocking guest-to-host loopback traffic (`10.0.2.2`) due to Ubuntu's `systemd-resolved` DNS proxying rules.
**Solution:** Instead of forcing the internal VirtualBox gateway, we dynamically grabbed the Host's real local IP (e.g., `192.168.x.x`) and bound the Python server to `0.0.0.0`. The VM simply routes out to the physical network and back in.

~~~bash
# Snippet from inject_keys.sh: Bypassing the NAT loopback block
HOST_IP=$(hostname -I | awk '{print $1}')
PRESEED_URL="http://$HOST_IP:8000/preseed.cfg"
python3 -m http.server 8000 --bind 0.0.0.0 > server.log 2>&1 &
~~~

### 3. The `Connection reset by peer` SSH Error
**Problem:** After installation, running `ssh inception` resulted in a connection reset. The NAT Port Forwarding rule was configured as `4242,,4242`, but a fresh Debian install listens on port `22`.
**Solution:** We mapped the Host's port `4242` directly to the Guest's default SSH port `22` during VM creation.

~~~bash
# Corrected Port Forwarding Rule
VBoxManage modifyvm "$VM_NAME" --natpf1 "ssh,tcp,,4242,,22"
~~~

### 4. Lingering Disks & UUID Conflicts
**Problem:** Running the creation script multiple times caused VirtualBox to throw UUID "already exists" errors, even if the `.vdi` file was deleted.
**Solution:** A robust `fclean` target in the `Makefile` that forces VirtualBox to unregister the specific disk using `closemedium` before attempting deletion.

---

## ⚙️ Features

* **Cluster-Aware Storage:** Automatically detects if it's running in the 42 cluster (`/sgoinfre/$USER`) to avoid NFS quota limits, falling back to local storage otherwise.
* **Passwordless SSH:** Automatically sets up `~/.ssh/config` with KeepAlive parameters and injects your public key into the VM.
* **VS Code Ready:** Patches the local VS Code settings to prevent timeout drops during remote SSH sessions.
* **Fully Preseeded:** Answers all Debian installation prompts, including partitioning (`/dev/sda`), root passwords, and `sudo` group assignment.

---
*Built with grit, bash scripting, and a lot of debugging.*