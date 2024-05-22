#!/bin/bash

ERROR='\033[0;31m'
GREEN='\033[0;32m'
WARNING='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
SUCCESS='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'
NEWLINE='\n'
BLINK='\033[5m'

function docker_install() {

    echo -e "${NEWLINE}${NEWLINE}"
    docker --version
    if ! [ $? -eq 0 ]; then

        echo -e "${NEWLINE}${NEWLINE}"
        sleep 1
        echo -e "${BLUE}-----------------------------------------${NC}"
        echo -e "   ${BOLD}Instalação do Docker!${NC}     "
        echo -e "${BLUE}-----------------------------------------${NC}"
        sleep 1
        echo -e "${NEWLINE}${NEWLINE}"

        echo -e "${MAGENTA} ----- [${NC} Atualizando sistema ${MAGENTA}] -----${NC}${NEWLINE}"
        sleep 1
        apt update && apt upgrade -y
        echo ""
        sleep 1
        if [ $? -ne 0 ]; then
            echo -e "${ERROR}<<< ERRO >>>:${NC} Erro ao atualizar o sistema. Verifique sua conexão com a internet e tente novamente.${NEWLINE}"
            sleep 1
            return
        fi

        echo -e "${MAGENTA} ----- [${NC} Instalando pacotes necessários ${MAGENTA}] -----${NC}${NEWLINE}"
        sleep 1
        apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
        echo ""
        sleep 1
        if [ $? -ne 0 ]; then
            echo -e "${ERROR}<<< ERRO >>>:${NC} Erro ao instalar pacotes necessários. Verifique sua conexão com a internet e tente novamente.${NEWLINE}"
            sleep 1
            return
        fi

        echo -e "${MAGENTA} ----- [${NC} Adicionando chave GPG do repositório Docker ${MAGENTA}] -----${NC}${NEWLINE}"
        sleep 1
        curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo ""
        sleep 1
        if [ $? -ne 0 ]; then
            echo -e "${ERROR}<<< ERRO >>>:${NC} Erro ao adicionar chave GPG no repositório Docker. Verifique sua conexão com a internet e tente novamente.${NEWLINE}"
            sleep 1
            return
        fi

        echo -e "${MAGENTA} ----- [${NC} Adicionando repositório Docker ao sistema ${MAGENTA}] -----${NC}${NEWLINE}"
        sleep 1
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt update
        echo ""
        sleep 1

        echo -e "${MAGENTA} ----- [${NC} Instalando Docker Engine ${MAGENTA}] -----${NC}${NEWLINE}"
        sleep 1
        apt install -y docker-ce docker-ce-cli containerd.io
        echo ""
        sleep 1
        if [ $? -ne 0 ]; then
            echo -e "${ERROR}<<< ERRO >>>:${NC} Erro ao instalar Docker Engine. Verifique sua conexão com a internet e tente novamente.${NEWLINE}"
            sleep 1
            return
        fi

        sleep 1
        echo -e "${MAGENTA} ----- [${NC} Adicionando usuário ao grupo docker ${MAGENTA}] -----${NC}${NEWLINE}"
        sleep 1
        echo -ne "${GREEN}${BLINK} ->${NC} Nome do usuário que irá utilizar o Docker: "
        read usr
        usermod -aG docker $usr
        sleep 5  # Adiciona uma pausa para garantir que o Docker crie o socket
        if [ -e /var/run/docker.sock ]; then
            chown $usr:docker /var/run/docker.sock
        fi
        /etc/init.d/docker restart
        echo ""
        sleep 1

        docker --version
        if [ $? -eq 0 ]; then
            echo -e "${SUCCESS}.........................................${NC}"
            echo -e "${BOLD} ...::: Docker instalado com sucesso! :::... ${NC}"
            echo -e "${SUCCESS}.........................................${NC}${NEWLINE}"
            sleep 1
        else 
            echo -e "${ERROR}<<< ERRO >>>:${NC} Erro ao instalar Docker Engine. Verifique sua conexão com a internet e tente novamente.${NEWLINE}"
            sleep 1
        fi
    else
        echo -e "${NEWLINE}${NEWLINE}"

        echo -e "${SUCCESS}.........................................${NC}"
        echo -e "${BOLD} ...::: Docker já está instalado! :::... ${NC}"
        echo -e "${SUCCESS}.........................................${NC}"

        echo -e "${NEWLINE}${NEWLINE}"
    fi
}

function docker_uninstall(){
    docker --version
    if [ $? -eq 0 ]; then
        sleep 1
        echo -e "${MAGENTA} ----- [${NC} Desinstalando Docker ${MAGENTA}] ----- ${NC}${NEWLINE}"
        sleep 1
        rm /usr/share/keyrings/docker-archive-keyring.gpg
        apt purge docker-ce docker-ce-cli containerd.io -y && apt autoremove -y
        apt clean
        groupdel docker
        echo -e "${NEWLINE}${NEWLINE}"
        echo -e "${SUCCESS}.........................................${NC}"
        echo -e "${BOLD}    ...::: Docker desinstalado! :::... ${NC}"
        echo -e "${SUCCESS}.........................................${NC}${NEWLINE}"
        sleep 1
    else

        echo -e "${SUCCESS}.........................................${NC}"
        echo -e "${BOLD} ...::: Docker não está instalado! :::... ${NC}"
        echo -e "${SUCCESS}.........................................${NC}${NEWLINE}"
        sleep 1
    fi
}

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
    echo -e "${BLUE}║ ${WHITE}1. ${GREEN}Instalar Docker                               ${BLUE}║${NC}"
    echo -e "${BLUE}║ ${WHITE}2. ${GREEN}Desinstalar Docker                                 ${BLUE}║${NC}"
    echo -e "${BLUE}║ ${WHITE}3. ${RED}Sair                                ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo -ne "Escolha uma opção: "


read -r option

case $option in
	1)
		docker_install
		sleep 1
		;;
	2)
		docker_uninstall
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
