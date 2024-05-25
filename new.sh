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

# ------------------------------------------------------------------------------------
# .................................. APACHE ..........................................
# ------------------------------------------------------------------------------------
function setup_static_site(){
    echo -e "${NEWLINE}${MAGENTA} ----- [${NC} Configurando Apache para hospedar site estático ${MAGENTA}] -----${NC}${NEWLINE}"
    echo -ne "${BLINk}${GREEN}->${NC}Digite o caminho para os arquivos do site: "
    read -r static_site_path
    if [ -z "$static_site_path" ]; then
        echo -e "${ERROR}<<< ERRO >>> :${NC} Caminho não pode ser vazio."
        sleep 1
        setup_static_site
        return
    fi
    mkdir -p configs/apache/static_site
    cat <<EOF > configs/apache/static_site/docker-compose.yml
version: '3'
services:
    apache-static:
        image: httpd:latest
        volumes:
            - ${static_site_path}:/usr/local/apache2/htdocs/
        ports:
            - "80:80"
EOF
    sleep 1
    docker-compose -f configs/apache/static_site/docker-compose.yml up -d
    sleep 1
    echo -e "${SUCCESS}+ ÊXITO + :${NC} Site estático hospedado com sucesso!"
}

function setup_dynamic_site(){
    echo -e "${NEWLINE}${MAGENTA} ----- [${NC} Configurando Apache para hospedar site dinâmico ${MAGENTA}] -----${NC}${NEWLINE}"
    echo -ne "${BLINK}${GREEN}->${NC}Digite o caminho para os arquivos do site dinâmico: "
    read -r dynamic_site_path
    if [ -z "$dynamic_site_path" ]; then
        echo -e "${ERROR}<<< ERRO >>> :${NC} Caminho não pode ser vazio."
        sleep 1
        setup_dynamic_site
        return
    fi
    echo -ne "${BLINK}${GREEN}->${NC}Digite a versão do PHP desejada (ex: 7.4, 8.0, 8.1): "
    read -r php_version
     if [ -z "$php_version" ]; then
        echo -e "${ERROR}<<< ERRO >>> :${NC} Versão do PHP não pode ser vazia."
        sleep 1
        setup_dynamic_site
        return
    fi
    mkdir -p configs/apache/dynamic_site
        cat <<EOF > configs/apache/dynamic_site/docker-compose.yml
version: '3'
services:
    apache-dynamic:
        image: php:${php_version}-apache
        volumes:
            - ${dynamic_site_path}:/var/www/html
        ports:
            - "80:80"
EOF
    sleep 1
    docker-compose -f configs/apache/dynamic_site/docker-compose.yml up -d
    sleep 1
    echo -e "${SUCCESS}+ ÊXITO + :${NC} Site dinâmico hospedado com sucesso!"

}


function configure_apache_server(){
    echo -e "${NEWLINE}${BLUE}Escolha a destinação do servidor Apache:${NC}"
    echo -e "[${GREEN}1${NC}] . Hospedar um site estático"
    echo -e "[${GREEN}2${NC}] . Hospedar um site dinâmico (PHP)"
    echo -e "[${GREEN}3${NC}] . Hospedar uma API"
    echo -e "[${GREEN}4${NC}] . Hospedar um banco de dados MySQL"
    echo -e "[${GREEN}5${NC}] . Hospedar um banco de dados MariaDB"
    echo -e "[${GREEN}0${NC}] . Voltar"
    echo -ne "${BLINk}${GREEN}->${NC}Escolha uma opção: "
    read destination_choice
        case $destination_choice in
        1)
            setup_static_site
            sleep 1
            ;;
        2) 
            setup_dynamic_site
            sleep 1
            ;;
        3) 
            setup_api
            sleep 1
            ;;
        4)
            setup_mysql
            sleep 1
            ;;
        5)
            setup_mariadb
            sleep 1
            ;;
        0)
            return
            ;;
        *)
            echo -e "${WARNING} * AVISO * :${NC} Opção inválida...${NC}"
    		sleep 1
            configure_apache_server
            ;;
    esac  

}

# ------------------------------------------------------------------------------------
# .................................. //APACHE ........................................
# ------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------
# .................................. DOCKER COMPOSE ..................................
# ------------------------------------------------------------------------------------

function docker_compose_install(){
    echo -e "${NEWLINE}${MAGENTA} ----- [${NC} Instalando Docker Compose ${MAGENTA}] -----${NC}${NEWLINE}"
    apt install -y docker-compose-plugin
    if [ $? -eq 0 ]; then
        echo -e "${NEWLINE}${SUCCESS}.........................................${NC}"
        echo -e "${BOLD} ...::: Compose instalado com sucesso! :::... ${NC}"
        echo -e "${SUCCESS}.........................................${NC}${NEWLINE}"
        sleep 1
    else
        echo -e "${NEWLINE}${ERROR}<<< ERRO >>>:${NC} Erro ao instalar Docker Compose. Verifique sua conexão com a internet e tente novamente."
        sleep 1
        return
    fi
}



# ------------------------------------------------------------------------------------
# ................................// DOCKER COMPOSE ..................................
# ------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------
# ....................................... DOCKER .....................................
# ------------------------------------------------------------------------------------
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
        

        echo -e "${NEWLINE}${MAGENTA} ----- [${NC} Atualizando sistema ${MAGENTA}] -----${NC}${NEWLINE}"
        sleep 1
        apt update && apt upgrade -y
        if [ $? -ne 0 ]; then
            echo -e "${ERROR}<<< ERRO >>>:${NC} Erro ao atualizar o sistema. Verifique sua conexão com a internet e tente novamente.${NEWLINE}"
            sleep 1
            return
        fi

        echo -e "${MAGENTA} ----- [${NC} Instalando pacotes necessários ${MAGENTA}] -----${NC}${NEWLINE}"
        sleep 1
        apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
        if [ $? -ne 0 ]; then
            echo -e "${ERROR}<<< ERRO >>>:${NC} Erro ao instalar pacotes necessários. Verifique sua conexão com a internet e tente novamente.${NEWLINE}"
            sleep 1
            return
        fi

        echo -e "${MAGENTA} ----- [${NC} Adicionando chave GPG do repositório Docker ${MAGENTA}] -----${NC}${NEWLINE}"
        sleep 1
        curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        if [ $? -ne 0 ]; then
            echo -e "${ERROR}<<< ERRO >>>:${NC} Erro ao adicionar chave GPG no repositório Docker. Verifique sua conexão com a internet e tente novamente.${NEWLINE}"
            sleep 1
            return
        fi

        echo -e "${MAGENTA} ----- [${NC} Adicionando repositório Docker ao sistema ${MAGENTA}] -----${NC}${NEWLINE}"
        sleep 1
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt update
        sleep 1

        echo -e "${MAGENTA} ----- [${NC} Instalando Docker Engine ${MAGENTA}] -----${NC}${NEWLINE}"
        sleep 1
        apt install -y docker-ce docker-ce-cli containerd.io
        if [ $? -ne 0 ]; then
            echo -e "${ERROR}<<< ERRO >>>:${NC} Erro ao instalar Docker Engine. Verifique sua conexão com a internet e tente novamente.${NEWLINE}"
            sleep 1
            return
        fi

        echo -e "${MAGENTA} ----- [${NC} Adicionando usuário ao grupo docker ${MAGENTA}] -----${NC}${NEWLINE}"
        sleep 1

        /etc/init.d/docker restart
        if [ $? -ne 0 ]; then
            echo -e "${ERROR}<<< ERRO >>>:${NC} Erro ao reiniciar o serviço Docker."
            return
        fi
        sleep 2

        echo -ne "${GREEN}${BLINK} ->${NC} Nome do usuário que irá utilizar o Docker: "
        read usr
        usermod -aG docker $usr
        if [ $? -ne 0 ]; then
            echo -e "${ERROR}<<< ERRO >>>:${NC} Erro ao adicionar usuário: ${usr} ao grupo docker."
            return
        fi

        if [ -e /var/run/docker.sock ]; then
            chown $usr:docker /var/run/docker.sock
            chmod 660 /var/run/docker.sock
            if [ $? -ne 0 ]; then
                echo -e "${ERROR}<<< ERRO >>>: ${NC} Erro ao mudar permissão do arquivo /var/run/docker.sock"
                return
            fi
        else
            echo -e "${ERROR}<<< ERRO >>>:${NC} O arquivo /var/run/docker.sock não existe."
            return
        fi

        /etc/init.d/docker restart
        sleep 1

        docker --version
        if [ $? -eq 0 ]; then
            echo -e "${SUCCESS}.........................................${NC}"
            echo -e "${BOLD} ...::: Docker instalado com sucesso! :::... ${NC}"
            echo -e "${SUCCESS}.........................................${NC}${NEWLINE}"
            
            echo -ne "${GREEN}${BLINK} ->${NC} Deseja reiniciar o shell agora para aplicar as mudanças? (s/n): "
            read resposta
            if [ "$resposta" = "s" ]; then
                su - $usr -c "newgrp docker"
            else
                echo -e "${BOLD} ...::: Por favor, faça logout e login novamente para aplicar as mudanças de grupo. :::... ${NC}"
            fi

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

# ------------------------------------------------------------------------------------
# .....................................// DOCKER .....................................
# ------------------------------------------------------------------------------------
function show_servers_menu(){

    while true; do
    echo -e "${CYAN}"
    echo -e "╔════════════════════════════════════════╗"
    echo -e "║            ${YELLOW}MENU SERVIDORES${CYAN}              ║"
    echo -e "╚════════════════════════════════════════╝"
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ ${WHITE}1. ${GREEN}Apache                     ${BLUE}║${NC}"
    echo -e "${BLUE}║ ${WHITE}2. ${GREEN}NginX                      ${BLUE}║${NC}"
    echo -e "${BLUE}║ ${WHITE}3. ${GREEN}Samba                      ${BLUE}║${NC}"
    echo -e "${BLUE}║ ${WHITE}4. ${GREEN}ProFTPD                    ${BLUE}║${NC}"
    echo -e "${BLUE}║ ${WHITE}5. ${GREEN}vsFTPd                     ${BLUE}║${NC}"
    echo -e "${BLUE}║ ${WHITE}0. ${RED}Voltar                                ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo -ne "${BLINk}${GREEN}->${NC}Escolha uma opção: "
    read -r option
        case $option in
            1) 
                show_menu_apache
                sleep 1
                ;;
            2) 
                show_menu_nginx
                sleep 1
                ;;
            3) 
                show_menu_samba
                sleep 1
                ;;
            4) 
                show_menu_proftpd
                sleep 1
                ;;
            5)
                show_menu_vsftpd
                sleep 1
                ;;
            0) 
                return 
                ;;
            *)
                echo -e "${WARNING} * AVISO * :${NC} Opção inválida...${NC}"
                sleep 1
                show_servers_menu
                ;;

        esac

    done
}


function show_menu(){

    while true; do

    echo -e "${CYAN}"
    echo -e "╔════════════════════════════════════════╗"
    echo -e "║                                        ║"
    echo -e "║            ${YELLOW}MENU PRINCIPAL${CYAN}              ║"
    echo -e "║                                        ║"
    echo -e "╚════════════════════════════════════════╝"
    sleep 0.5
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ ${WHITE}1. ${GREEN}Instalar Docker                     ${BLUE}║${NC}"
    echo -e "${BLUE}║ ${WHITE}2. ${GREEN}Desinstalar Docker                  ${BLUE}║${NC}"
    echo -e "${BLUE}║ ${WHITE}3. ${GREEN}Instalar Docker Compose             ${BLUE}║${NC}"
    echo -e "${BLUE}║ ${WHITE}4. ${GREEN}Servidores                          ${BLUE}║${NC}"
    echo -e "${BLUE}║ ${WHITE}0. ${RED}Sair                                  ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo -ne "${BLINk}${GREEN}->${NC}Escolha uma opção: "


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
            docker_compose_install
            sleep 1
            ;;
    	0)
    		echo "saindo..."
    		sleep 1
    		exit 0
    		;;
    	*)
    		echo -e "${WARNING} * AVISO * :${NC} Opção inválida...${NC}"
    		sleep 1
    		;;
    esac

    done

}

print_welcome() {
    prefix="Bem-vindo(a) ao Gerenciador de Servidores Linux! Escolha uma opção:"
   
    echo -ne "${MAGENTA}"
    for ((i = 0; i < ${#prefix}; i++)); do
        echo -n "${prefix:$i:1}"
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
