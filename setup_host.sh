#!/bin/bash

# 1. Configurar SSH Config del Host
mkdir -p ~/.ssh
if ! grep -q "Host inception" ~/.ssh/config; then
    cat <<EOF >> ~/.ssh/config

Host inception
    HostName 127.0.0.1
    User login
    Port 4242
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
fi

# 2. Inyectar llave SSH (si tienes una)
if [ -f ~/.ssh/id_rsa.pub ]; then
    echo "Recuerda copiar tu llave a la VM una vez arranque: ssh-copy-id -p 4242 login@127.0.0.1"
fi

# 3. Parche VS Code (Python)
python3 -c "
import json, os, glob
p = os.path.expanduser('~/.config/Code/User/settings.json')
try:
    with open(p, 'r') as f: s = json.load(f)
except:
    s = {}
s['remote.SSH.useLocalServer'] = False
s['remote.SSH.enableDynamicForwarding'] = False
s['remote.SSH.useExecServer'] = False
s['remote.SSH.connectTimeout'] = 60
s['remote.SSH.showLoginTerminal'] = True
with open(p, 'w') as f: json.dump(s, f, indent=4)
"
echo "Host configured and VS Code patch applied."