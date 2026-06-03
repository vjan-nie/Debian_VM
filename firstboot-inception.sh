#!/bin/bash
set -e
exec >> /var/log/firstboot-inception.log 2>&1
echo "[$(date)] Starting firstboot-inception..."

# --- a) Detect host-only interface, assign IP, persist via ifupdown ---
PRIMARY=$(ip route show default | awk '{print $5; exit}')
HOIF=$(ls /sys/class/net | grep -vE "^lo$|^${PRIMARY}$" | head -1)

if [ -n "$HOIF" ]; then
    ip addr add 192.168.56.10/24 dev "$HOIF" 2>/dev/null || true
    ip link set "$HOIF" up
    cat > /etc/network/interfaces.d/host-only <<EOF
auto ${HOIF}
iface ${HOIF} inet static
    address 192.168.56.10
    netmask 255.255.255.0
EOF
fi

# --- b) Install Docker via official repo (plain URLs — no Markdown wrapping) ---
apt-get update -qq
apt-get install -y ca-certificates curl gnupg make git

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

. /etc/os-release
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian ${VERSION_CODENAME} stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -qq
apt-get install -y \
    docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

usermod -aG docker vjan-nie
systemctl enable --now docker

# --- c) Local domain resolution inside VM ---
grep -q "vjan-nie.42.fr" /etc/hosts \
    || echo "127.0.0.1 vjan-nie.42.fr" >> /etc/hosts

# --- d) Disable so it only ever runs once ---
systemctl disable firstboot-inception.service

echo "[$(date)] firstboot-inception complete."
