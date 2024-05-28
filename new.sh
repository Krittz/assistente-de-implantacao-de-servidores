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

function container_name_in_use(){
    container_name=$1
    if [ ! -z "$(docker ps -a --filter name=^/${container_name}$ --format '{{.Names}}')" ]; then
        echo -e "${ERROR}<<< ${BOLD}ERRO${NC} >>> :${NC} Nome de contêiner '${BOLD}${container_name}${NC}' já está em uso. Por favor, escolha outro nome."
        return 1
    else
        return 0
    fi
}

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

function choose_port(){
    start_port=$1
    end_port=$2
    echo -e "${BLINK}${GREEN}->${NC}Portas disponíveis entre ${start_port} e ${end_port}:"
    available_ports=$(list_available_ports $start_port $end_port)
    if [ -z "$available_ports" ]; then
        echo -e "${ERROR}<<< ${BOLD}ERRO${NC} >>> :${NC} Nenhuma porta disponível encontrada entre ${start_port} e ${end_port}."
        return 1
    fi
    echo -e "${available_ports}"
    echo -ne "${BLINK}${GREEN}->${NC}Escolha uma porta: "
    read -r chosen_port
    if [[ ! " ${available_ports[@]} " =~ " ${chosen_port} " ]]; then
        echo -e "${ERROR}<<< ${BOLD}ERRO${NC} >>> :${NC} Porta escolhida não está disponível. Por favor, escolha outra porta."
        return 1
    fi
    echo $chosen_port
    return 0
}

# ------------------------------------------------------------------------------------
# .................................. BANCO DE DADOS ..................................
# ------------------------------------------------------------------------------------
function setup_mysql(){
    echo -e "${NEWLINE}${MAGENTA} ----- [${NC} Configurando MySQL ${MAGENTA}] -----${NC}${NEWLINE}"
    
    echo -ne "${BLINK}${GREEN}->${NC} Digite o nome do container: "
    read -r container_name
    if [ -z "$container_name" ]; then
        echo -e "${ERROR}<<< ${BOLD}ERRO${NC} >>> :${NC} Nome do container não pode ser vazio."
        sleep 1
        setup_mysql
        return
    fi
    if container_name_in_use $container_name; then
        echo -e "${ERROR}<<< ${BOLD}ERRO${NC} >>>:${NC} Nome do container já está em uso."
        sleep 1
        setup_mysql
        return
    fi

    echo -ne "${BLINK}${GREEN}->${NC} Digite a senha do usuário root: "
    read -r root_password
    if [ -z "$root_password" ]; then
        echo -e "${ERROR}<<< ${BOLD}ERRO${NC} >>> :${NC} Senha do usuário root não pode ser vazia."
        sleep 1
        setup_mysql
        return
    fi

    mysql_port=$(choose_port 3306 3350)
    if [ $? -ne 0 ]; then
        sleep 1
        setup_mysql
        return
    fi

    echo -ne "${BLINK}${GREEN}->${NC} Digite o caminho para o arquivo de backup do banco de dados (opcional): "
    read -r backup_file

    mkdir -p configs/database/mysql
    cat <<EOF > configs/database/mysql/docker-compose.yml
version: '3'
services:
    ${container_name}:
        image: mysql:latest
        environment:
            MYSQL_ROOT_PASSWORD: ${root_password}
        ports:
            - "${mysql_port}:3306"
        volumes:
            - mysql_data:/var/lib/mysql
EOF
    if [ -n "$backup_file" ]; then
        cat <<EOF >> configs/database/mysql/docker-compose.yml
            - ${backup_file}:/docker-entrypoint-initdb.d/backup.sql
EOF
    fi

    cat <<EOF >> configs/database/mysql/docker-compose.yml
volumes:
    mysql_data:
EOF

    sleep 1
    docker-compose -f configs/database/mysql/docker-compose.yml up -d
    sleep 1
    echo -e "${SUCCESS}+ ${BOLD}ÊXITO${NC} + :${NC} Banco de dados MySQL configurado com sucesso no container ${BOLD}${container_name}${NC} na porta: ${BOLD}${mysql_port}${NC}!"
}

function configure_databases(){
    echo -e "${NEWLINE}${BLUE}Escolha a destinação do servidor de banco de dados:${NC}"
    echo -e "[${GREEN}1${NC}] . Banco MySQL"
    echo -e "[${GREEN}2${NC}] . Banco MariaDB"
    echo -e "[${GREEN}3${NC}] . Banco PostgreSQL"
    echo -e "[${GREEN}0${NC}] . Voltar"
    echo -ne "${BLINK}${GREEN}->${NC}Escolha uma opção: "
    read destination_choice
        case $destination_choice in
        1)
            setup_mysql
            sleep 1
            ;;
        2) 
            ##setup_mariadb
            sleep 1
            ;;
        3) 
            #setup_postgresql
            sleep 1
            ;;
        0)
            return
            ;;
        *)
            echo -e "${WARNING} * ${BOLD}AVISO${NC} * :${NC} Opção inválida...${NC}"
            sleep 1
            configure_databases
            ;;
    esac  
}

# ------------------------------------------------------------------------------------
# .................................. //BANCO DE DADOS ................................
# ------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------
# .................................. APACHE ..........................................
# ------------------------------------------------------------------------------------

function setup_static_site(){
    echo -ne "${BLINK}${GREEN}->${NC}Digite o caminho para os arquivos do site: "
    read -r static_site_path
    if [ -z "$static_site_path" ]; then
        echo -e "${ERROR}<<< ${BOLD}ERRO${NC} >>> :${NC} Caminho não pode ser vazio."
        sleep 1
        setup_static_site
        return
    fi
    echo -ne "${BLINK}${GREEN}->${NC}Digite o nome do contêiner: "
    read -r container_name
    if [ -z "$container_name" ]; then
        echo -e "${ERROR}<<< ${BOLD}ERRO${NC} >>> :${NC} Nome do contêiner não pode ser vazio."
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
    echo -e "${SUCCESS}+ ${BOLD}ÊXITO${NC} + :${NC} Site estático hospedado com sucesso no contêiner '${BOLD}${container_name}${NC}' na porta ${BOLD}${static_site_port}${NC}!"
}

function configure_apache_server(){
    echo -e "${NEWLINE}${BLUE}Escolha a destinação do servidor Apache:${NC}"
    echo -e "[${GREEN}1${NC}] . Hospedar um site estático"
    echo -e "[${GREEN}2${NC}] . Hospedar um site dinâmico (PHP)"
    echo -e "[${GREEN}3${NC}] . Hospedar uma API"
    echo -e "[${GREEN}4${NC}] . Configurar Banco de Dados"
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
            configure_databases
            sleep 1
            ;;
        0)
            return
            ;;
        *)
            echo -e "${WARNING} * ${BOLD}AVISO${NC} * :${NC} Opção inválida...${NC}"
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
        echo -e "${NEWLINE}${SUCCESS}+ ${BOLD}ÊXITO${NC} + :${NC} Docker Compose instalado com sucesso!"
        sleep 1
    else
        echo -e "${NEWLINE}${ERROR}<<< ${BOLD}ERRO${NC} >>>:${NC} Erro ao instalar Docker Compose. Verifique sua conexão com a internet e tente novamente."
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
            echo -e "${ERROR}<<< ${BOLD}ERRO${NC} >>> :${NC} Erro ao adicionar repositório Docker ao sistema. Verifique sua conexão com a internet e tente novamente.${NEWLINE}"
            sleep 1
            return
        fi
        echo -e "${MAGENTA} ----- [${NC} Atualizando índices do repositório Docker ${MAGENTA}] -----${NC}${NEWLINE}"
        sleep 1
        apt update
        if [ $? -ne 0 ]; then
            echo -e "${ERROR}<<< ${BOLD}ERRO${NC} >>> :${NC} Erro ao atualizar índices do repositório Docker. Verifique sua conexão com a internet e tente novamente.${NEWLINE}"
            sleep 1
            return
        fi
        echo -e "${MAGENTA} ----- [${NC} Instalando Docker ${MAGENTA}] -----${NC}${NEWLINE}"
        sleep 1
        apt install -y docker-ce docker-ce-cli containerd.io
        if [ $? -eq 0 ]; then
            echo -e "${SUCCESS}+ ${BOLD}ÊXITO${NC} + :${NC} Docker instalado com sucesso!"
            sleep 1
        else
            echo -e "${ERROR}<<< ${BOLD}ERRO${NC} >>> :${NC} Erro ao instalar Docker. Verifique sua conexão com a internet e tente novamente.${NEWLINE}"
            sleep 1
            return
        fi
    else
        echo -e "${WARNING} * ${BOLD}AVISO${NC} * :${NC} Docker já está instalado.${NEWLINE}"
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
    echo -e "[${GREEN}4${NC}] . Configurar Banco de Dados"
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
        4)
            configure_databases
            sleep 1
            ;;
        0)
            echo -e "${NEWLINE}${WHITE}Saindo...${NC}"
            sleep 1
            exit
            ;;
        *)
            echo -e "${WARNING} * ${BOLD}AVISO${NC} * :${NC} Opção inválida...${NC}"
            sleep 1
            main_menu
            ;;
    esac  
}

main_menu
