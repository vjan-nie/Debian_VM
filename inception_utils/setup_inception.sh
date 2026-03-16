#!/bin/bash

USER_LOGIN="vjan-nie"
DOMAIN="${USER_LOGIN}.42.fr"

echo "=== 1. Local domain conf ==="
# Domain points at localhost
if ! grep -q "$DOMAIN" /etc/hosts; then
    echo "127.0.0.1 $DOMAIN" | sudo tee -a /etc/hosts
    echo "Domain $DOMAIN configured."
fi

echo "=== 2. Installing Docker and Docker Compose ==="
sudo apt-get update -qq
sudo apt-get install -y ca-certificates curl gnupg

# Official Docker key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL [https://download.docker.com/linux/debian/gpg](https://download.docker.com/linux/debian/gpg) | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] [https://download.docker.com/linux/debian](https://download.docker.com/linux/debian) \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine and Compose
sudo apt-get update -qq
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "=== 3. Configure Docker permissions ==="
sudo usermod -aG docker $USER_LOGIN

echo "Instalation complete. Reopen SSH to update."