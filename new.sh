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

# Função para verificar se um contêiner com o mesmo nome já está em uso
function container_name_in_use(){
    container_name=$1
    if [ ! -z "$(docker ps -a --filter name=^/${container_name}$ --format '{{.Names}}')" ]; then
        echo -e "${ERROR}<<< ERRO >>> :${NC} Nome de contêiner '${container_name}' já está em uso. Por favor, escolha outro nome."
        return 1
    else
        return 0
    fi
}

# Função para verificar portas disponíveis
function list_available_ports(){
    start_port=$1
    end_port=$2
    available_ports=()
    for (( port=$start_port; port<=$end_port; port++ )); do
        if ! lsof -i:$port > /dev/null; then
            available_ports+=($port)
        fi
    done
    echo "${available_ports[@]}"
}

# Função para escolher a porta
function choose_port(){
    start_port=$1
    end_port=$2
    echo -e "${BLINK}${GREEN}->${NC}Portas disponíveis entre ${start_port} e ${end_port}:"
    available_ports=$(list_available_ports $start_port $end_port)
    if [ -z "$available_ports" ]; then
        echo -e "${ERROR}<<< ERRO >>> :${NC} Nenhuma porta disponível encontrada entre ${start_port} e ${end_port}."
        return 1
    fi
    echo -e "${available_ports}"
    echo -ne "${BLINK}${GREEN}->${NC}Escolha uma porta: "
    read -r chosen_port
    if [[ ! " ${available_ports[@]} " =~ " ${chosen_port} " ]]; then
        echo -e "${ERROR}<<< ERRO >>> :${NC} Porta escolhida não está disponível. Por favor, escolha outra porta."
        return 1
    fi
    echo $chosen_port
    return 0
}

# ------------------------------------------------------------------------------------
# .................................. APACHE ..........................................
# ------------------------------------------------------------------------------------
function setup_static_site(){
    echo -e "${NEWLINE}${MAGENTA} ----- [${NC} Configurando Apache para hospedar site estático ${MAGENTA}] -----${NC}${NEWLINE}"
    echo -ne "${BLINK}${GREEN}->${NC}Digite o caminho para os arquivos do site: "
    read -r static_site_path
    if [ -z "$static_site_path" ]; then
        echo -e "${ERROR}<<< ERRO >>> :${NC} Caminho não pode ser vazio."
        sleep 1
        setup_static_site
        return
    fi
    echo -ne "${BLINK}${GREEN}->${NC}Digite o nome do contêiner: "
    read -r container_name
    if [ -z "$container_name" ]; then
        echo -e "${ERROR}<<< ERRO >>> :${NC} Nome do contêiner não pode ser vazio."
        sleep 1
        setup_static_site
        return
    fi
    if container_name_in_use $container_name; then
        sleep 1
        setup_static_site
        return
    fi
    static_site_port=$(choose_port 8080 8090)
    if [ $? -ne 0 ]; then
        sleep 1
        setup_static_site
        return
    fi
    mkdir -p configs/apache/static_site
    cat <<EOF > configs/apache/static_site/docker-compose.yml
version: '3'
services:
    ${container_name}:
        image: httpd:latest
        volumes:
            - ${static_site_path}:/usr/local/apache2/htdocs/
        ports:
            - "${static_site_port}:80"
EOF
    sleep 1
    docker-compose -f configs/apache/static_site/docker-compose.yml up -d
    sleep 1
    echo -e "${SUCCESS}+ ÊXITO + :${NC} Site estático hospedado com sucesso no contêiner '${container_name}' na porta ${static_site_port}!"
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
    echo -ne "${BLINK}${GREEN}->${NC}Digite o nome do contêiner: "
    read -r container_name
    if [ -z "$container_name" ]; then
        echo -e "${ERROR}<<< ERRO >>> :${NC} Nome do contêiner não pode ser vazio."
        sleep 1
        setup_dynamic_site
        return
    fi
    if container_name_in_use $container_name; then
        sleep 1
        setup_dynamic_site
        return
    fi
    dynamic_site_port=$(choose_port 8080 8090)
    if [ $? -ne 0 ]; then
        sleep 1
        setup_dynamic_site
        return
    fi
    mkdir -p configs/apache/dynamic_site
    cat <<EOF > configs/apache/dynamic_site/docker-compose.yml
version: '3'
services:
    ${container_name}:
        image: php:${php_version}-apache
        volumes:
            - ${dynamic_site_path}:/var/www/html
        ports:
            - "${dynamic_site_port}:80"
EOF
    sleep 1
    docker-compose -f configs/apache/dynamic_site/docker-compose.yml up -d
    sleep 1
    echo -e "${SUCCESS}+ ÊXITO + :${NC} Site dinâmico hospedado com sucesso no contêiner '${container_name}' na porta ${dynamic_site_port}!"
}

function configure_apache_server(){
    echo -e "${NEWLINE}${BLUE}Escolha a destinação do servidor Apache:${NC}"
    echo -e "[${GREEN}1${NC}] . Hospedar um site estático"
    echo -e "[${GREEN}2${NC}] . Hospedar um site dinâmico (PHP)"
    echo -e "[${GREEN}3${NC}] . Hospedar uma API"
    echo -e "[${GREEN}4${NC}] . Hospedar um banco de dados MySQL"
    echo -e "[${GREEN}5${NC}] . Hospedar um banco de dados MariaDB"
    echo -e "[${GREEN}0${NC}] . Voltar"
    echo -ne "${BLINK}${GREEN}->${NC}Escolha uma opção: "
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
            #setup_api
            sleep 1
            ;;
        4)
            #setup_mysql
            sleep 1
            ;;
        5)
            #setup_mariadb
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
    apt install -y docker-compose
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

function docker_install(){
    if ! command -v docker &> /dev/null; then
        echo -e "${NEWLINE}${MAGENTA} ----- [${NC} Instalando Docker ${MAGENTA}] -----${NC}${NEWLINE}"
        sleep 1
        apt update
        apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        if [ $? -ne 0 ]; then
            echo -e "${ERROR}<<< ERRO >>>:${NC} Erro ao adicionar repositório Docker ao sistema. Verifique sua conexão com a internet e tente novamente.${NEWLINE}"
            sleep 1
            return
        fi
        echo -e "${MAGENTA} ----- [${NC} Atualizando índices do repositório Docker ${MAGENTA}] -----${NC}${NEWLINE}"
        sleep 1
        apt update
        if [ $? -ne 0 ]; then
            echo -e "${ERROR}<<< ERRO >>>:${NC} Erro ao atualizar índices do repositório Docker. Verifique sua conexão com a internet e tente novamente.${NEWLINE}"
            sleep 1
            return
        fi
        echo -e "${MAGENTA} ----- [${NC} Instalando Docker ${MAGENTA}] -----${NC}${NEWLINE}"
        sleep 1
        apt install -y docker-ce docker-ce-cli containerd.io
        if [ $? -eq 0 ]; then
            echo -e "${SUCCESS}.........................................${NC}"
            echo -e "${BOLD} ...::: Docker instalado com sucesso! :::... ${NC}"
            echo -e "${SUCCESS}.........................................${NC}${NEWLINE}"
            sleep 1
        else
            echo -e "${ERROR}<<< ERRO >>>:${NC} Erro ao instalar Docker. Verifique sua conexão com a internet e tente novamente.${NEWLINE}"
            sleep 1
            return
        fi
    else
        echo -e "${WARNING} * AVISO * :${NC} Docker já está instalado.${NEWLINE}"
    fi
}

# ------------------------------------------------------------------------------------
# ................................. // DOCKER ........................................
# ------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------
# .................................. MENU PRINCIPAL ..................................
# ------------------------------------------------------------------------------------

function main_menu(){
    echo -e "${NEWLINE}${BLUE}-----------------------------------------${NC}"
    echo -e "   ${BOLD}MENU PRINCIPAL!${NC}     "
    echo -e "${BLUE}-----------------------------------------${NC}"
    echo -e "[${GREEN}1${NC}] . Instalar Docker"
    echo -e "[${GREEN}2${NC}] . Instalar Docker Compose"
    echo -e "[${GREEN}3${NC}] . Configurar Servidor Apache"
    echo -e "[${GREEN}0${NC}] . Sair"
    echo -ne "${BLINK}${GREEN}->${NC}Escolha uma opção: "
    read main_choice
        case $main_choice in
        1)
            docker_install
            sleep 1
            ;;
        2)
            docker_compose_install
            sleep 1
            ;;
        3)
            configure_apache_server
            sleep 1
            ;;
        0)
            echo -e "${NEWLINE}${WHITE}Saindo...${NC}"
            sleep 1
            exit
            ;;
        *)
            echo -e "${WARNING} * AVISO * :${NC} Opção inválida...${NC}"
            sleep 1
            main_menu
            ;;
    esac  
}

main_menu
