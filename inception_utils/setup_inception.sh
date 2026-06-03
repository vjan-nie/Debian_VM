#!/bin/bash
# Provisioning is now handled automatically by firstboot-inception.service,
# which runs on the first VM boot after installation.
# Check status : systemctl status firstboot-inception
# Full log     : /var/log/firstboot-inception.log
echo "Auto-provisioning via firstboot-inception.service — nothing to do here."
