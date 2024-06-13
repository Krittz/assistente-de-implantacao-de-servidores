#!/bin/bash
ERROR='\033[0;31m'
INPUT='\033[0;32m'
WARNING='\033[1;33m'
SUCCESS='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'
NL='\n'
BLINK='\033[5m'

#echo -e "${NL}${MAGENTA} ...::: ${NC}${BOLD}Instalação do Docker${NC} ${MAGENTA}:::...${NC}"
#echo -e "${NL}${BLUE} >>>${NC}${BOLD} Atualizando Sistema ${NC}${BLUE}<<<${NC}"
#echo -e "${NL}${SUCCESS}${BOLD}✓ SUCESSO ✓${NC}: Docker á está instalado!"
#echo -e "${NL}${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao atualizar sistema. Verifique sua conexão com a internet e tente novamente."
#echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Opção inválida!"

# --->>> FUNÇÕES USUAIS <<<---
function check_container_name(){
    local container_name=$1
    if [ -z "$container_name" ]; then
        echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Nome do container não pode ser vazio!"
        return 1
    fi
    if [ ! -z "$(docker ps -a --filter name=^/${container_name}$ --format '{{.Names}}')" ]; then
        echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Nome '${container_name}' indisponível!"
        return 1
    else   
        echo -e "${NL}${SUCCESS}${BOLD}✓ SUCESSO ✓${NC}: Nome do container '${container_name}' está disponível."
        return 0
    fi
}

function check_and_suggest_port() {
    local port=$1
    local start_port=$2
    local end_port=$3

    if [ -z "$port" ]; then
        echo ""
        return 1
    fi

    if ss -tuln | grep -q ":${port}\b"; then
        for alt_port in $(seq $start_port $end_port); do
            if ! ss -tuln | grep -q ":${alt_port}\b"; then
                echo "$alt_port"
                return 0
            fi
        done
        echo ""
        return 1    
    else
        echo "$port"
        return 0
    fi
}



# --->>> //FUNÇÕES USUARIS <<<---

# --->>> MARIADB <<<---

function create_mariadb_container() {
    local container_name
    local db_name
    local db_user
    local db_password

    # Solicitar informações do usuário
    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Criando MariaDB${NC} ${BLUE}:::...${NC}"

    echo -ne " ${INPUT}↳${NC} Informe o nome do novo container: "
    read container_name

    if ! check_container_name "$container_name"; then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Nome de container inválido."
        return 1
    fi

    echo -ne " ${INPUT}↳${NC} Informe o nome do banco de dados: "
    read db_name

    echo -ne " ${INPUT}↳${NC} Informe o nome do usuário do banco de dados: "
    read db_user

    echo -ne " ${INPUT}↳${NC} Informe a senha do usuário do banco de dados: "
    read -s db_password
    echo

    # Verificar se algum campo está vazio
    if [ -z "$db_name" ] || [ -z "$db_user" ] || [ -z "$db_password" ]; then
        echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Nome do banco, usuário e senha não podem ser vazios!"
        return 1
    fi

    # Verificar a disponibilidade da porta 3306 e sugerir uma alternativa se necessário
    local suggested_port
    if ! suggested_port=$(check_and_suggest_port 3306 3306 3399); then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Todas as portas entre 3306 e 3399 estão ocupadas. Não é possível criar o container."
        return 1
    fi

    # Cria um diretório configs se não existir
    mkdir -p configs

    # Escrever o Dockerfile para MariaDB na pasta configs
    cat > configs/Dockerfile-mariadb <<EOF
FROM mariadb:latest
RUN apt-get update && apt-get install -y mysql-client && rm -rf /var/lib/apt/lists/*
ENV MYSQL_DATABASE=$db_name
ENV MYSQL_USER=$db_user
ENV MYSQL_PASSWORD=$db_password
ENV MYSQL_ROOT_PASSWORD=$db_password
COPY ./configs/db_setup.sql /docker-entrypoint-initdb.d/
EXPOSE $suggested_port
EOF

    # Escrever o script SQL para inicialização do banco de dados
    cat > configs/db_setup.sql <<SQL
CREATE DATABASE IF NOT EXISTS $db_name;
USE $db_name;
CREATE USER '$db_user'@'%' IDENTIFIED BY '$db_password';
GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'%';
FLUSH PRIVILEGES;
SQL

    # Build da imagem Docker para MariaDB
    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Construindo imagem Docker${NC} ${BLUE}:::...${NC}"
    docker build -t mariadb-image -f configs/Dockerfile-mariadb .

    if [ $? -ne 0 ]; then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao construir a imagem Docker."
        return 1
    fi

    # Run do container Docker para MariaDB
    docker run -d --name $container_name -p $suggested_port:3306 mariadb-image

    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}${BOLD}✓ SUCESSO ✓${NC}: Container '${container_name}' criado e executando na porta $suggested_port."
    else
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao criar o container '${container_name}'."
        return 1
    fi
}


# --->>> //MARIADB <<<---

# --->>> DOCKER <<<---
function docker_install(){
    echo ""
    docker --version
    if [ $? -eq 0 ]; then
        sleep 0.3 
        echo -e "${NL}${SUCCESS}${BOLD}✓ SUCESSO ✓${NC}: Docker já está instalado!"
        sleep 0.3
        return
    else
        echo -e "${NL}${MAGENTA} ...::: ${NC}${BOLD}Instalação do Docker${NC} ${MAGENTA}:::...${NC}"
        echo -e "${NL}${BLUE} >>>${NC}${BOLD} Atualizando Sistema ${NC}${BLUE}<<<${NC}"
        apt update && apt upgrade -y
        if [ $? -ne 0 ]; then
            sleep 0.3
            echo -e "${NL}${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao atualizar sistema. Verifique sua conexão com a internet e tente novamente."
            sleep 0.3
            return
        fi
        echo -e "${NL}${BLUE} >>>${NC}${BOLD} Instalando pacotes necessários ${NC}${BLUE}<<<${NC}"
        apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
        if [ $? -ne 0 ]; then
            sleep 0.3
            echo -e "${NL}${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao instalar pacotes necessários. Verifique sua conexão com a internet e tente novamente."
            sleep 0.3
            return
        fi
        echo -e "${NL}${BLUE} >>>${NC}${BOLD} Adicionando chave GPG do repositório Docker ${NC}${BLUE}<<<${NC}"
        curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        if [ $? -ne 0 ]; then
            sleep 0.3
            echo -e "${NL}${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao adicionar chave GPG. Verifique sua conexão com a internet e tente novamente."
            sleep 0.3
            return
        fi
        echo -e "${NL}${BLUE} >>>${NC}${BOLD} Adicionando repositório Docker ao sistema ${NC}${BLUE}<<<${NC}"
        echo "deb [signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
        apt update

        echo -e "${NL}${BLUE} >>>${NC}${BOLD} Instalando Docker Engine ${NC}${BLUE}<<<${NC}"
        apt install -y docker-ce docker-ce-cli containerd.io
        if [ $? -ne 0 ]; then
            sleep 0.3
            echo -e "${NL}${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao instalar Docker Engine. Verifique sua conexão com a internet e tente novamente."
            sleep 0.3
            return
        fi

        echo -e "${NL}${BLUE} >>>${NC}${BOLD} Adicionando usuário ao grupo Docker ${NC}${BLUE}<<<${NC}"
        echo -ne " ${INPUT}↳${NC} Informe o nome do usuário que utilizará o Docker: "
        read -r usr
        usermod -aG docker $usr
        chown $usr:docker /var/run/docker.sock
        /etc/init.d/docker restart
        docker --version
        if [ $? -eq 0 ]; then
            sleep 0.3
            echo -e "${NL}${SUCCESS}${BOLD}✓ SUCESSO ✓${NC}: Docker instalado!"
            sleep 0.3
        else
            sleep 0.3
            echo -e "${NL}${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao instalar Docker. Verifique sua conexão com a internet e tente novamente."
            sleep 0.3
            return
        fi
    fi
}
function docker_uninstall(){
    echo ""
    docker --version
    if ! [ $? -eq 0 ]; then
        sleep 0.3
        echo -e "${NL}${SUCCESS}${BOLD}✓ SUCESSO ✓${NC}: Docker não está instalado!"
        sleep 0.3
    else
        echo -e "${NL}${BLUE} >>>${NC}${BOLD} Desinstalando Docker ${NC}${BLUE}<<<${NC}"
        rm /usr/share/keyrings/docker-archive-keyring.gpg
        apt purge docker-ce docker-ce-cli containerd.io -y && apt autoremove -y
        apt clean
        groupdel docker
        sleep 0.3
        echo -e "${NL}${SUCCESS}${BOLD}✓ SUCESSO ✓${NC}: Docker desinstalado!"
        sleep 0.3
    fi
}
# --->>> //DOCKER <<<---

# --->>> MENUS <<<---
#function proftpd_menu(){}
#function vsftpd_menu(){}
#function filezilla_menu(){}
function fpt_server_menu(){
    echo -e "${NL}${BLUE} ########################"
    echo -e " ##   ${NC}${BOLD}SERVIDORES FTP${NC}${BLUE}   ##"
    echo -e " ##....................##"
    echo -e " ##${NC} [${INPUT}1${NC}] - ProFTPD      ${BLUE}##"
    echo -e " ##${NC} [${INPUT}2${NC}] - vsftpd       ${BLUE}##"
    echo -e " ##${NC} [${INPUT}3${NC}] - FileZilla    ${BLUE}##"
    echo -e " ##${NC} [${INPUT}0${NC}] - Voltar       ${BLUE}##"
    echo -e " ########################${NC}"
    echo -ne " ${INPUT}↳${NC} Selecione uma opção: "
    read -r server_option

    case $server_option in
        1)
            sleep 0.3
            echo "proftpd_menu"
            ;;
        2)
            sleep 0.3
            echo "vsftpd_menu"
            ;;
        3)
            sleep 0.3
            echo "filezilla_menu"
            ;;
        0)
            sleep 0.3
            return
            ;;
        *)
            sleep 0.3
            echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Opção inválida!"
            sleep 0.3
            ftp_server_menu
            ;;
    esac
}

#function mysql_menu(){}
#function mariadb_menu(){}
#function postgresql_menu(){}
#function sqlite_menu(){}
function database_menu(){
    echo -e "${NL}${BLUE} #########################"
    echo -e " ##   ${NC}${BOLD}BANCOS DE DADOS${NC}${BLUE}   ##"
    echo -e " ##.....................##"
    echo -e " ##${NC} [${INPUT}1${NC}] - MySQL         ${BLUE}##"
    echo -e " ##${NC} [${INPUT}2${NC}] - MariaDB       ${BLUE}##"
    echo -e " ##${NC} [${INPUT}3${NC}] - PostgreSQL    ${BLUE}##"
    echo -e " ##${NC} [${INPUT}4${NC}] - SQLite        ${BLUE}##"
    echo -e " ##${NC} [${INPUT}0${NC}] - Voltar        ${BLUE}##"
    echo -e " #########################${NC}"
    echo -ne " ${INPUT}↳${NC} Selecione uma opção: "
    read -r database_option
    case $database_option in
        1)
            sleep 0.3
            echo "mysql_menu"
            ;;
        2)
            sleep 0.3
            create_mariadb_container
            ;;
        3)
            sleep 0.3
            echo "postgresql_menu"
            ;;
        4)
            sleep 0.3
            echo "sqlite_menu"
            ;;
        0)
            sleep 0.3
            return
            ;;
        *)
            sleep 0.3
            echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Opção inválida!"
            sleep 0.3
            database_menu
            ;;
    esac
}

function apache_menu(){
    echo -e "${NL}${BLUE} ########################"
    echo -e " ##      ${NC}${BOLD}APACHE${NC}${BLUE}        ##"
    echo -e " ##....................##"
    echo -e " ##${NC} [${INPUT}1${NC}] -              ${BLUE}##"
    echo -e " ##${NC} [${INPUT}2${NC}] -              ${BLUE}##"
    echo -e " ##${NC} [${INPUT}0${NC}] - Voltar       ${BLUE}##"

    echo -e " ########################${NC}"
    echo -ne " ${INPUT}↳${NC} Selecione uma opção: "
    read -r server_option
}
#function nginx_menu(){}
#function samba_menu(){}
#function proftpd_menu(){}
#function vsftpd_menu(){}
function web_server_menu(){
    echo -e "${NL}${BLUE} ########################"
    echo -e " ##   ${NC}${BOLD}SERVIDORES WEB${NC}${BLUE}   ##"
    echo -e " ##....................##"
    echo -e " ##${NC} [${INPUT}1${NC}] - Apache       ${BLUE}##"
    echo -e " ##${NC} [${INPUT}2${NC}] - NginX        ${BLUE}##"
    echo -e " ##${NC} [${INPUT}0${NC}] - Voltar       ${BLUE}##"

    echo -e " ########################${NC}"
    echo -ne " ${INPUT}↳${NC} Selecione uma opção: "
    read -r server_option

    case $server_option in
        1)
            sleep 0.3
            echo "apache_menu"
            ;;
        2)
            sleep 0.3
           echo "nginx_menu"
            ;;
        0)
            sleep 0.3
            return
            ;;
        *)
            sleep 0.3
            echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Opção inválida!"
            sleep 0.3
            web_server_menu
            ;;
    esac
}

#function main_menu(){}
#web_server_menu
database_menu
#fpt_server_menu
#apache_menu
