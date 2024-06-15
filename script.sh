#!/bin/bash
ERROR='\033[0;31m'
INPUT='\033[0;32m'
WARNING='\033[1;33m'
INFO='\033[0;33m' 
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
        echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Nome '${container_name}' indisponível! Tente novamente. "
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

# --->>> POSTGRESQL <<<---
function create_postgresql_container() {
    local container_name
    local db_user
    local db_password

    while true; do
        echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Criando PostgreSQL${NC} ${BLUE}:::...${NC}"
        
        echo -ne " ${INPUT}↳${NC} Informe o nome do novo container: "
        read container_name

        if check_container_name "$container_name"; then
            break  
        fi
    done

    echo -ne " ${INPUT}↳${NC} Informe o nome do usuário do banco de dados: "
    read db_user

    echo -ne " ${INPUT}↳${NC} Informe a senha do usuário do banco de dados: "
    read -s db_password
    echo

    if [ -z "$db_user" ] || [ -z "$db_password" ]; then
        echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Usuário e senha não podem ser vazios!"
        return 1
    fi

    local suggested_port
    if ! suggested_port=$(check_and_suggest_port 5432 5432 5499); then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Todas as portas entre 5432 e 5499 estão ocupadas. Não é possível criar o container."
        return 1
    fi

    mkdir -p configs

    cat > configs/Dockerfile-postgresql <<EOF
FROM postgres:latest

# Definir a senha do usuário postgres
ENV POSTGRES_PASSWORD=$db_password

# Expor a porta padrão do PostgreSQL
EXPOSE $suggested_port
EOF

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Construindo imagem Docker${NC} ${BLUE}:::...${NC}"
    docker build -t postgresql-image -f configs/Dockerfile-postgresql .

    if [ $? -ne 0 ]; then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao construir a imagem Docker."
        return 1
    fi

    docker run -d --name $container_name -p $suggested_port:5432 postgresql-image

    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}${BOLD}✓ SUCESSO ✓${NC}: Container '${container_name}' criado e executando na porta $suggested_port."
        echo -e " ${MAGENTA}🜙 ${NC}Container: ${BOLD}$container_name${NC}"
        echo -e " ${MAGENTA}🜙 ${NC}Banco: ${BOLD}PostgreSQL${NC}"
        echo -e " ${MAGENTA}🜙 ${NC}Porta: ${BOLD}$suggested_port${NC}"
        echo -e " ${MAGENTA}🜙 ${NC}Usuário: ${BOLD}$db_user${NC}"
        sleep 0.3
        main_menu
    else
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao criar o container '${container_name}'."
        return 1
    fi
}
# --->>> //POSTGRESQL <<<---

# --->>> MARIADB <<<---
function create_mariadb_container() {
    local container_name
    local db_user
    local db_password

    while true; do
        echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Criando MariaDB${NC} ${BLUE}:::...${NC}"
        
        echo -ne " ${INPUT}↳${NC} Informe o nome do novo container: "
        read container_name

        if check_container_name "$container_name"; then
            break  
        fi
    done

    echo -ne " ${INPUT}↳${NC} Informe o nome do usuário do banco de dados: "
    read db_user

    echo -ne " ${INPUT}↳${NC} Informe a senha do usuário do banco de dados: "
    read -s db_password
    echo

    if [ -z "$db_user" ] || [ -z "$db_password" ]; then
        echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Usuário e senha não podem ser vazios!"
        return 1
    fi

    local suggested_port
    if ! suggested_port=$(check_and_suggest_port 3306 3306 3399); then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Todas as portas entre 3306 e 3399 estão ocupadas. Não é possível criar o container."
        return 1
    fi

    mkdir -p configs

    cat > configs/Dockerfile-mariadb <<EOF
FROM mariadb:latest

# Definir a senha de root do MariaDB
ENV MARIADB_ROOT_PASSWORD=$db_password

# Expor a porta padrão do MariaDB
EXPOSE $suggested_port
EOF

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Construindo imagem Docker${NC} ${BLUE}:::...${NC}"
    docker build -t mariadb-image -f configs/Dockerfile-mariadb .

    if [ $? -ne 0 ]; then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao construir a imagem Docker."
        return 1
    fi

    docker run -d --name $container_name -p $suggested_port:3306 mariadb-image

    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}${BOLD}✓ SUCESSO ✓${NC}: Container '${container_name}' criado e executando na porta $suggested_port."
        echo -e " ${MAGENTA}🜙 ${NC}Container: ${BOLD}$container_name${NC}"
        echo -e " ${MAGENTA}🜙 ${NC}Banco: ${BOLD}MariaDB${NC}"
        echo -e " ${MAGENTA}🜙 ${NC}Porta: ${BOLD}$suggested_port${NC}"
        echo -e " ${MAGENTA}🜙 ${NC}Usuário: ${BOLD}$db_user${NC}"
        sleep 0.3
        main_menu
    else
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao criar o container '${container_name}'."
        return 1
    fi
}
# --->>> //MARIADB <<<---
# --->>> SQLITE <<<---
function create_sqlite_container() {
    local container_name

    while true; do
        echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Criando SQLite${NC} ${BLUE}:::...${NC}"
        
        echo -ne " ${INPUT}↳${NC} Informe o nome do novo container: "
        read container_name

        if check_container_name "$container_name"; then
            break
        fi
    done

    local suggested_port
    if ! suggested_port=$(check_and_suggest_port 3306 3306 3399); then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Todas as portas entre 3306 e 3399 estão ocupadas. Não é possível criar o container."
        return 1
    fi

    mkdir -p configs

    cat > configs/Dockerfile-sqlite <<EOF
FROM alpine:latest

# Instalar SQLite
RUN apk add --no-cache sqlite

# Criar um diretório para armazenar os arquivos de banco de dados
RUN mkdir /data

# Definir /data como o diretório de trabalho
WORKDIR /data

# Comando padrão para o container
CMD ["sh", "-c", "while true; do sleep 1000; done"]
EOF

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Construindo imagem Docker${NC} ${BLUE}:::...${NC}"
    docker build -t sqlite-image -f configs/Dockerfile-sqlite .

    if [ $? -ne 0 ]; then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao construir a imagem Docker."
        return 1
    fi

    docker run -d --name $container_name -p $suggested_port:3306 sqlite-image

    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}${BOLD}✓ SUCESSO ✓${NC}: Container '${container_name}' criado e executando na porta $suggested_port."
         echo -e " ${MAGENTA}🜙 ${NC}Container: ${BOLD}$container_name${NC}"
        echo -e " ${MAGENTA}🜙 ${NC}Banco: ${BOLD}SQLite${NC}"
        echo -e " ${MAGENTA}🜙 ${NC}Porta: ${BOLD}$suggested_port${NC}"
        echo -e " ${MAGENTA}🜙 ${NC}Usuário: ${BOLD}$db_user${NC}"
        sleep 0.3
        main_menu
    else
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao criar o container '${container_name}'."
        return 1
    fi
}

# --->>> //SQLITE <<<---

# --->>> MYSQL <<<---
function create_mysql_container() {
    local container_name
    local db_user
    local db_password

    while true; do
        echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Criando MySQL${NC} ${BLUE}:::...${NC}"
        
        echo -ne " ${INPUT}↳${NC} Informe o nome do novo container: "
        read container_name

        if check_container_name "$container_name"; then
            break 
        fi
    done

    echo -ne " ${INPUT}↳${NC} Informe o nome do usuário do banco de dados: "
    read db_user

    echo -ne " ${INPUT}↳${NC} Informe a senha do usuário do banco de dados: "
    read -s db_password
    echo

    if [ -z "$db_user" ] || [ -z "$db_password" ]; then
        echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Usuário e senha não podem ser vazios!"
        return 1
    fi

    local suggested_port
    if ! suggested_port=$(check_and_suggest_port 3306 3306 3399); then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Todas as portas entre 3306 e 3399 estão ocupadas. Não é possível criar o container."
        return 1
    fi

    mkdir -p configs

    cat > configs/Dockerfile-mysql <<EOF
FROM mysql:latest

# Definir variáveis de ambiente para o MySQL
ENV MYSQL_ROOT_PASSWORD=$db_password
ENV MYSQL_USER=$db_user
ENV MYSQL_PASSWORD=$db_password

# Expor a porta padrão do MySQL
EXPOSE $suggested_port
EOF

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Construindo imagem Docker${NC} ${BLUE}:::...${NC}"
    docker build -t mysql-image -f configs/Dockerfile-mysql .

    if [ $? -ne 0 ]; then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao construir a imagem Docker."
        return 1
    fi

    docker run -d --name $container_name -p $suggested_port:3306 mysql-image

    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}${BOLD}✓ SUCESSO ✓${NC}: Container '${container_name}' criado e executando na porta $suggested_port."
        echo -e " ${MAGENTA}🜙 ${NC}Container: ${BOLD}$container_name${NC}"
        echo -e " ${MAGENTA}🜙 ${NC}Banco: ${BOLD}MySQL${NC}"
        echo -e " ${MAGENTA}🜙 ${NC}Porta: ${BOLD}$suggested_port${NC}"
        echo -e " ${MAGENTA}🜙 ${NC}Usuário: ${BOLD}$db_user${NC}"
        sleep 0.3
        main_menu
    else
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao criar o container '${container_name}'."
        return 1
    fi
}
function restore_backup_mysql(){
    local container_name
    local backup_file_path
    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Restaurar Backup${NC}${BLUE} :::...${NC}"
    read container_name

    if ! docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: o container '${container_name}' não existe."
        return 1
    fi

    echo -ne " ${INPUT}↳${NC} Informe o caminho completo do arquivo de backup: "
    read backup_file_path

    if [ ! -f "$backup_file_path" ]; then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: O arquivo de backup '${backup_file_path}' não existe."
        return 1
    fi

    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}"; then
        echo -e "${INFO}${BOLD}ℹ INFO ℹ${NC}: O container '${container_name}' não está em execução. Iniciando o container..."
        docker start "$container_name"
        if [ $? -ne 0 ]; then
            echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao iniciar o container '${container_name}'."
            return 1
        fi
    fi

    echo -e "${NL}${BLUE} >>>${NC}${BOLD} Restaurando o backup no container '${container_name}' ${NC}${BLUE}<<<${NC}"
    docker exec -i "$container_name" sh -c 'exec mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD}' < "$backup_file_path"

    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}${BOLD}✓ SUCESSO ✓${NC}: Backup restaurado com sucesso no container '${container_name}'."
    else
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao restaurar o backup no container '${container_name}'."
        return 1
    fi
    sleep 0.3
    main_menu

} 
# --->>> // MYSQL <<<---
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
function mariadb_menu(){
    echo -e "${NL}${BLUE} ################################################"
    echo -e " ##                   ${NC}${BOLD}MARIADB${NC}${BLUE}                  ##"
    echo -e " ##............................................##"
    echo -e " ##${NC} [${INPUT}1${NC}] - Criar um container novo              ${BLUE}##"
    echo -e " ##${NC} [${INPUT}2${NC}] - Restaurar um banco de dados          ${BLUE}##"
    echo -e " ##${NC} [${INPUT}3${NC}] - Realizar backup de um banco de dados ${BLUE}##"
    echo -e " ##${NC} [${INPUT}0${NC}] - Voltar                               ${BLUE}##"
    echo -e " ################################################${NC}"
    echo -ne " ${INPUT}↳${NC} Selecione uma opção: "
    read -r mariadb_option
    case $mariadb_option in
    1)
        sleep 0.3
        create_mariadb_container
        ;;
    2)
        sleep 0.3
        ;;
    3)
        sleep 0.3
        ;;
    0)
        sleep 0.3
        clear
        database_menu
        ;;
    *)
        sleep 0.3
        echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Opção inválida!"
        sleep 0.3
        mariadb_menu
        ;;  
    
    esac
}
function mysql_menu(){
    echo -e "${NL}${BLUE} ################################################"
    echo -e " ##                   ${NC}${BOLD}MySQL${NC}${BLUE}                    ##"
    echo -e " ##............................................##"
    echo -e " ##${NC} [${INPUT}1${NC}] - Criar um container novo              ${BLUE}##"
    echo -e " ##${NC} [${INPUT}2${NC}] - Restaurar um banco de dados          ${BLUE}##"
    echo -e " ##${NC} [${INPUT}3${NC}] - Realizar backup de um banco de dados ${BLUE}##"
    echo -e " ##${NC} [${INPUT}0${NC}] - Voltar                               ${BLUE}##"
    echo -e " ################################################${NC}"
    echo -ne " ${INPUT}↳${NC} Selecione uma opção: "
    read -r mysql_option
    case $mysql_option in
    1)
        sleep 0.3
        create_mysql_container
        ;;
    2)
        sleep 0.3
        restore_backup_mysql
        ;;
    3)
        sleep 0.3
        ;;
    0)
        sleep 0.3
        clear
        database_menu
        ;;
    *)
        sleep 0.3
        echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Opção inválida!"
        sleep 0.3
        mysql_menu
        ;;

    
    
    esac
}
function postgre_menu(){
    echo -e "${NL}${BLUE} ################################################"
    echo -e " ##              ${NC}${BOLD}PostgreSQL${NC}${BLUE}                    ##"
    echo -e " ##............................................##"
    echo -e " ##${NC} [${INPUT}1${NC}] - Criar um container novo              ${BLUE}##"
    echo -e " ##${NC} [${INPUT}2${NC}] - Restaurar um banco de dados          ${BLUE}##"
    echo -e " ##${NC} [${INPUT}3${NC}] - Realizar backup de um banco de dados ${BLUE}##"
    echo -e " ##${NC} [${INPUT}0${NC}] - Voltar                               ${BLUE}##"
    echo -e " ################################################${NC}"
    echo -ne " ${INPUT}↳${NC} Selecione uma opção: "
    read -r postgre_option
    case $postgre_option in
    1)
        sleep 0.3
        create_postgre_container
        ;;
    2)
        sleep 0.3
        ;;
    3)
        sleep 0.3
        ;;
    0)
        sleep 0.3
        clear
        database_menu
        ;;
    *)
        sleep 0.3
        echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Opção inválida!"
        sleep 0.3
        postgre_menu
        ;;

    
    
    esac
}
function sqlite_menu(){
    echo -e "${NL}${BLUE} ################################################"
    echo -e " ##                   ${NC}${BOLD}SQLite${NC}${BLUE}                   ##"
    echo -e " ##............................................##"
    echo -e " ##${NC} [${INPUT}1${NC}] - Criar um container novo              ${BLUE}##"
    echo -e " ##${NC} [${INPUT}2${NC}] - Restaurar um banco de dados          ${BLUE}##"
    echo -e " ##${NC} [${INPUT}3${NC}] - Realizar backup de um banco de dados ${BLUE}##"
    echo -e " ##${NC} [${INPUT}0${NC}] - Voltar                               ${BLUE}##"
    echo -e " ################################################${NC}"
    echo -ne " ${INPUT}↳${NC} Selecione uma opção: "
    read -r sqlite_option
    case $sqlite_option in
    1)
        sleep 0.3
        create_sqlite_container
        ;;
    2)
        sleep 0.3
        ;;
    3)
        sleep 0.3
        ;;
    0)
        sleep 0.3
        clear
        database_menu
        ;;
    *)
        sleep 0.3
        echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Opção inválida!"
        sleep 0.3
        sqlite_menu
        ;;   
    esac
}
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
            mysql_menu
            ;;
        2)
            sleep 0.3
            mariadb_menu
            ;;
        3)
            sleep 0.3
            postgre_menu
            ;;
        4)
            sleep 0.3
            sqlite_menu
            ;;
        0)
            sleep 0.3
            clear
            main_menu
            ;;
        *)
            sleep 0.3
            echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Opção inválida!"
            sleep 0.3
            database_menu
            ;;
    esac
}
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
function docker_menu(){
    echo -e "${NL}${BLUE} ########################"
    echo -e " ##       ${NC}${BOLD}DOCKER${NC}${BLUE}       ##"
    echo -e " ##....................##"
    echo -e " ##${NC} [${INPUT}1${NC}] - Instalar     ${BLUE}##"
    echo -e " ##${NC} [${INPUT}2${NC}] - Desinstalar  ${BLUE}##"
    echo -e " ##${NC} [${INPUT}0${NC}] - Voltar       ${BLUE}##"
    echo -e " ########################${NC}"
    echo -ne " ${INPUT}↳${NC} Selecione uma opção: "
    read -r docker_option
    case $docker_option in
        1)  sleep 0.3
            docker_install
            ;;
        2)
            sleep 0.3
            docker_uninstall
            ;;
        0)
            sleep 0.3
            return
            ;;
        *)
            sleep 0.3
            echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Opção inválida!"
            sleep 0.3
            main_menu
            ;;
    esac
}
function main_menu(){
    while true; do
        echo -e "${NL}${BLUE}             ###################################"
        echo -e "██╗███████╗  ##         ${NC}${BOLD}MENU PRINCIPAL        ${BLUE}##"
        echo -e "██║██╔════╝  ##...............................##" 
        echo -e "██║█████╗    ##${NC} [${INPUT}1${NC}] - Docker                  ${BLUE}##"
        echo -e "██║██╔══╝    ##${NC} [${INPUT}2${NC}] - Servidores Web          ${BLUE}##"
        echo -e "██║██║       ##${NC} [${INPUT}3${NC}] - Servidores FTP          ${BLUE}##"
        echo -e "╚═╝╚═╝       ##${NC} [${INPUT}4${NC}] - Bancos de Dados         ${BLUE}##"
        echo -e "             ##${NC} [${INPUT}0${NC}] - Sair                    ${BLUE}##"
        echo -e "             ###################################${NC}"      
        echo -e "               ${INPUT}↳${NC} Selecione uma opção: "  
        read -r menu_option

        case $menu_option in

            1)  sleep 0.3
                clear
                docker_menu
                ;;
            2)  sleep 0.3
                clear
                web_server_menu
                ;;
            3)  sleep 0.3
                clear
                fpt_server_menu
                ;;
            4)  slee 0.3
                clear
                database_menu
                ;;
            0)  echo -ne "${BLUE}Encerrando ...${NL}"
                sleep 0.3
                exit 0
                ;;
            *)  sleep 0.3
                echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Opção inválida!"
                sleep 0.3
                main_menu
                ;;
        esac
    done
}
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${NL}${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Por favor execute esse script como root!${NL}"
    exit 1
fi
main_menu


