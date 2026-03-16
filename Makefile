# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: vjan-nie <vjan-nie@student.42madrid.com    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/03/16 14:48:00 by vjan-nie          #+#    #+#              #
#    Updated: 2026/03/16 18:12:19 by vjan-nie         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

# --- Variables ---
VM_NAME     := Inception_Debian
CREATE_CMD  := ./create_vm.sh
INJECT_CMD  := ./inject_keys.sh

# --- Colors ---
C_RESET     := \033[0m
C_GREEN     := \033[32m
C_YELLOW    := \033[33m
C_RED       := \033[31m
C_BLUE      := \033[34m

# Phony targets to prevent conflicts with files of the same name
.PHONY: all install up down clean fclean re info

# Default target
all: install

# Create the VM and run the automated installation process
install:
	@printf "$(C_BLUE)▶ Building and installing VM: $(VM_NAME)...$(C_RESET)\n"
	@bash $(CREATE_CMD)
	@bash $(INJECT_CMD)

# Start the VM normally (similar to 'docker-compose up')
up:
	@printf "$(C_BLUE)▶ Starting VM...$(C_RESET)\n"
	@VBoxManage startvm "$(VM_NAME)" --type gui 2>/dev/null

# Gracefully stop the VM (similar to 'docker-compose down')
down:
	@printf "$(C_BLUE)▶ Stopping VM...$(C_RESET)\n"
	@VBoxManage controlvm "$(VM_NAME)" acpipowerbutton 2>/dev/null

# Clean temporary files, stop the VM, and free ports
clean:
	@printf "$(C_YELLOW)▶ Cleaning temporary files and freeing ports...$(C_RESET)\n"
	@VBoxManage controlvm "$(VM_NAME)" poweroff 2>/dev/null || true
	# Added brackets to prevent the pkill command from matching its own shell process
	@pkill -f "[p]ython3 -m http.server" 2>/dev/null || true
	@rm -f server.pid server.log

# Full clean: runs 'clean', then completely destroys the VM, registry, and disks
fclean: clean
	@printf "$(C_RED)▶ Destroying VM, wiping VirtualBox registry and disks...$(C_RESET)\n"
	@sleep 1
	# Unregister and delete the Virtual Machine
	@VBoxManage unregistervm "$(VM_NAME)" --delete 2>/dev/null || true
	# Force VirtualBox to forget the specific .vdi file using its absolute path
	@VBoxManage closemedium disk "$(CURDIR)/$(VM_NAME).vdi" --delete 2>/dev/null || true
	# Remove any residual folders left in VirtualBox's default directory
	@rm -rf "$$HOME/VirtualBox VMs/$(VM_NAME)" 2>/dev/null || true
	# Finally, delete the physical .vdi file from our project folder
	@rm -f *.vdi

# Rebuild everything from scratch
re: fclean all

# Display useful connection information
info:
	@printf "\n$(C_BLUE)=== Inception Info Map ===$(C_RESET)\n"
	@printf "$(C_YELLOW)SSH Connection:$(C_RESET) ssh inception\n"
	@printf "$(C_YELLOW)Website (NGINX):$(C_RESET) https://localhost (Port 443)\n"
	@printf "$(C_YELLOW)Data Directory:$(C_RESET) /home/login/data\n"
	@printf "$(C_BLUE)==========================$(C_RESET)\n\n"