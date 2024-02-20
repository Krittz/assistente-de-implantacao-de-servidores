#!/bin/bash 

RESET="\e[0m"
RED="\e[91m"
GREEN="\e[92m"
YELLOW="\e[93m"
CYAN="\e[96m"
BOLD="\e[1m"
BLUE="\e[34m"
MAGENTA="\e[35m"
PISCAR="\e[5m"

if [ "$(id -u)" -ne 0 ]; then
	echo "Por favor, execute este script como root"
	exit 1
fi

echo "{$CYAN}╔═══════════════════════════╗"
echo "║{$RESET}              MENU PRINCIPAL         {$CYAN}║"
echo "╠═══════════════════════════╣"
echo "║{$RESET} [1] - Docker                        {$CYAN}║"
echo "║{$RESET} [2] - Serviços                      {$CYAN}║"
echo "║{$RESET} [0] - Sair                          {$CYAN}║"
echo "╚═══════════════════════════╝{$RESET}"