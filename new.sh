#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

show_menu(){

while true; do

echo -e "${CYAN}"
echo -e "╔════════════════════════════════════════╗"
echo -e "║                                        ║"
echo -e "║            ${YELLOW}MENU PRINCIPAL${CYAN}              ║"
echo -e "║                                        ║"
echo -e "╚════════════════════════════════════════╝"
sleep 0.5
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ ${WHITE}1. ${GREEN}Criar                               ${BLUE}║${NC}"
    echo -e "${BLUE}║ ${WHITE}2. ${GREEN}Ver                                 ${BLUE}║${NC}"
    echo -e "${BLUE}║ ${WHITE}3. ${RED}Sair                                ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo -ne "Escolha uma opção: "


read -r option

case $option in
	1)
		echo "Criar"
		sleep 1
		;;
	2)
		echo "Ver"
		sleep 1
		;;
	3)
		echo "saindo..."
		sleep 1
		exit 0
		;;
	*)
		echo "${RED}Opção inválida!${NC}"
		sleep 1
		;;
esac

done

}

print_welcome() {
    prefix="Bem-vindo(a) "
    username="$USER"
    suffix=" ao Gerenciador de Servidores Linux! Escolha uma opção:"

    echo -ne "${MAGENTA}"
    for ((i = 0; i < ${#prefix}; i++)); do
        echo -n "${prefix:$i:1}"
        sleep 0.03
    done

    echo -ne "${YELLOW}"
    for ((i = 0; i < ${#username}; i++)); do
        echo -n "${username:$i:1}"
        sleep 0.03
    done

    echo -ne "${MAGENTA}"
    for ((i = 0; i < ${#suffix}; i++)); do
        echo -n "${suffix:$i:1}"
        sleep 0.03
    done

    echo -e "${NC}\n"
}



if [ "$(id -u)" -ne 0 ]; then
clear
echo -e "${RED}Por favor, execute este script como root ${NC}"
exit 1

fi

print_welcome
show_menu
