# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: vjan-nie <vjan-nie@student.42madrid.com    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/03/16 14:48:00 by vjan-nie          #+#    #+#              #
#    Updated: 2026/03/16 15:08:59 by vjan-nie         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

# VM Configuration variables
VM_NAME     := Inception_Debian
CREATE_CMD  := ./create_vm.sh

C_RESET     := \033[0m
C_GREEN     := \033[32m
C_YELLOW    := \033[33m
C_RED       := \033[31m
C_BLUE      := \033[34m

.PHONY: all setup start config_host fix_vscode fclean re

# Default target
all: setup

ll: setup config_host

setup:
	@bash create_vm.sh

config_host:
	@bash setup_host.sh

start:
	@VBoxManage startvm "$(VM_NAME)" --type gui

fix_vscode:
	@ssh inception "pkill -f vscode-server" || true
	@printf "VS Code server killed on VM. Reconnect now.\n"

fclean:
	@VBoxManage controlvm "$(VM_NAME)" poweroff 2>/dev/null || true
	@sleep 2
	@VBoxManage unregistervm "$(VM_NAME)" --delete 2>/dev/null || true
	@rm -f *.vdi debian-netinst.iso

re: fclean all
