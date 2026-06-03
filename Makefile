# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: vjan-nie <vjan-nie@student.42madrid.com    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/03/16 14:48:00 by vjan-nie          #+#    #+#              #
#    Updated: 2026/03/17 01:07:13 by vjan-nie         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

# --- Variables (sourced from config.sh) ---
VM_NAME     := $(shell . ./config.sh && echo $$VM_NAME)
DOMAIN      := $(shell . ./config.sh && echo $$DOMAIN)
CREATE_CMD  := ./create_vm.sh
INJECT_CMD  := ./inject_keys.sh
SETUP_CMD   := ./setup_host.sh
# Determine sgoinfre path for cleanup logic
SGOINFRE    := /sgoinfre/$(USER)/inception_vm

# --- Colors ---
C_RESET     := \033[0m
C_GREEN     := \033[32m
C_YELLOW    := \033[33m
C_RED       := \033[31m
C_BLUE      := \033[34m

.PHONY: all install up down clean fclean re info

all: install

# Create and run the automated installation
install:
	@printf "$(C_YELLOW)▶ Setting execution permissions for all scripts...$(C_RESET)\n"
	# Grant execute permissions to all shell scripts in the current directory
	@chmod +x *.sh
	@printf "$(C_BLUE)▶ Building and installing VM: $(VM_NAME)...$(C_RESET)\n"
	@$(CREATE_CMD)
	@$(INJECT_CMD)
# This line will only execute AFTER you press ENTER in the previous script
	@printf "$(C_BLUE)▶ Configuring Host (SSH & VS Code)...$(C_RESET)\n"
	@$(SETUP_CMD)
	@printf "\n$(C_GREEN)✔ Installation and setup complete!$(C_RESET)\n"
	@make info

# Start the VM
up:
	@printf "$(C_BLUE)▶ Starting VM...$(C_RESET)\n"
	@VBoxManage startvm "$(VM_NAME)" --type gui 2>/dev/null

# Graceful stop
down:
	@printf "$(C_BLUE)▶ Stopping VM...$(C_RESET)\n"
	@VBoxManage controlvm "$(VM_NAME)" acpipowerbutton 2>/dev/null

# Clean temporary files and kill server
clean:
	@printf "$(C_YELLOW)▶ Cleaning temporary files and freeing ports...$(C_RESET)\n"
	@VBoxManage controlvm "$(VM_NAME)" poweroff 2>/dev/null || true
	@pkill -f "[p]ython3 -m http.server" 2>/dev/null || true
	@rm -f server.pid server.log

# Full destroy: registry, discs and sgoinfre storage
fclean: clean
	@printf "$(C_RED)▶ Destroying VM and wiping storage...$(C_RESET)\n"
	@sleep 1
	# Unregister and delete VM registry
	@VBoxManage unregistervm "$(VM_NAME)" --delete 2>/dev/null || true
	# Close medium to prevent UUID "already exists" errors
	@VBoxManage list hdds | grep "$(VM_NAME)" | awk '{print $$2}' | xargs -I {} VBoxManage closemedium disk {} --delete 2>/dev/null || true
	# Wipe potential sgoinfre data and local disks
	@rm -rf "$(SGOINFRE)" 2>/dev/null || true
	@rm -f *.vdi

re: fclean all

info:
	@printf "\n$(C_BLUE)=== Inception Info Map ===$(C_RESET)\n"
	@printf "$(C_YELLOW)SSH Connection:$(C_RESET) ssh inception\n"
	@printf "$(C_YELLOW)Website (NGINX):$(C_RESET) https://$(DOMAIN)\n"
	@printf "$(C_BLUE)==========================$(C_RESET)\n\n"