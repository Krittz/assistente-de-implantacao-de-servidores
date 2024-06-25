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
function check_container_exists() {
    local container_name="$1"   
    if [ ! -z "$(docker ps -a --filter name=^/${container_name}$ --format '{{.Names}}')" ]; then
        return 0  
    else
        return 1  
    fi
}
function check_directory_exists() {
    local directory_path="$1"

    if [ -d "$directory_path" ]; then
        return 0
    else
        return 1
    fi
}
# --->>> //FUNÇÕES USUAIS <<<---

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
ENV POSTGRES_PASSWORD=$db_password
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
function restore_backup_postgresql() {
    local container_name
    local db_name
    local backup_file_path

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Restaurar Backup PostgreSQL${NC}${BLUE} :::...${NC}"

    while true; do
        echo -ne " ${INPUT}↳${NC} Informe o nome do container PostgreSQL: "
        read container_name
        if [ -z "${container_name}" ]; then
            echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Nome do container não pode ser vazio!"
            continue
        fi

        if ! check_container_exists "${container_name}"; then
            echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: O container '${container_name}' não existe."
            continue
        fi
        break
    done

    while true; do
        echo -ne " ${INPUT}↳${NC} Informe o nome do banco de dados PostgreSQL: "
        read db_name

        if [ -z "$db_name" ]; then
            echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Nome do banco de dados não pode ser vazio!"
            continue
        fi
        break
    done

    while true; do
        echo -ne " ${INPUT}↳${NC} Informe o caminho completo do arquivo de backup: "
        read backup_file_path

        if [ ! -f "$backup_file_path" ]; then
            echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: O arquivo de backup '${backup_file_path}' não existe."
            continue
        fi
        break
    done

    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo -e "${INFO}${BOLD}ℹ INFO ℹ${NC}: O container '${container_name}' não está em execução. Iniciando container..."
        docker start "$container_name"
        if [ $? -ne 0 ]; then
            echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao iniciar o container '${container_name}'."
            return 1
        fi
    fi

    echo -e "${NL}${BLUE} >>>${NC}${BOLD} Verificando se o banco de dados '${db_name}' existe ${NC}${BLUE}<<<${NC}"
    if ! docker exec "$container_name" psql -U postgres -lqt | cut -d \| -f 1 | grep -qw "$db_name"; then
        echo -e "${INFO}${BOLD}ℹ INFO ℹ${NC}: O banco de dados '${db_name}' não existe. Criando banco de dados..."
        docker exec "$container_name" psql -U postgres -c "CREATE DATABASE ${db_name};"
        if [ $? -ne 0 ]; then
            echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao criar o banco de dados '${db_name}'."
            return 1
        fi
    fi

    echo -e "${NL}${BLUE} >>>${NC}${BOLD} Restaurando backup do banco de dados '${db_name}' ${NC}${BLUE}<<<${NC}"
    cat "$backup_file_path" | docker exec -i "$container_name" sh -c "exec psql -U postgres -d ${db_name}"

    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}${BOLD}✓ SUCESSO ✓${NC}: Backup do banco de dados '${db_name}' restaurado com sucesso."
    else
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao restaurar o backup do banco de dados '${db_name}'."
        return 1
    fi

    sleep 0.3
    main_menu
}
function backup_postgresql(){
    local container_name
    local db_name
    local backup_file_path

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Backup PostgreSQL${NC}${BLUE} :::...${NC}"

    while true; do
        echo -ne " ${INPUT}↳${NC} Informe o nome do container PostgreSQL: "
        read container_name
        if [ -z "${container_name}" ]; then
            echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Nome do container não pode ser vazio!"
            continue
        fi

        if ! check_container_exists "${container_name}"; then
            echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: O container '${container_name}' não existe."
            continue
        fi
        break
    done

    while true; do
        echo -ne " ${INPUT}↳${BOLD} Informe o nome do banco de dados PostgreSQL: "
        read db_name

        if [ -z "$db_name" ]; then
            echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Nome do banco de dados não pode ser vazio!"
            continue
        fi
        break
    done

    while true; do
        echo -ne " ${INPUT}↳${NC} Informe o caminho completo para salvar o backup (incluir nome do arquivo):"
        read backup_file_path

        local dir_path
        dir_path=$(dirname "$backup_file_path")

        if [ ! -d "$dir_path" ]; then
            echo -e"${ERROR}${BOLD}✕ ERRO ✕${NC}: O diretório '${dir_path}' não existe."
            continue
        fi
        break
    done

    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo -e "${INFO}${BOLD}ℹ INFO ℹ${NC}: O container '${container_name}' não está em execução. Iniciando container..." 
        docker start "$container_name"
        if [ $? -ne 0 ]; then
            echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao iniciar o container '${container_name}'."
            return 1
        fi
    fi

    echo -e "${NL}${BLUE} >>>${NC}${BOLD} Criando backup do banco de dados '${db_name}' ${NC}${BLUE}<<<${NC}"
    docker exec "$container_name" sh -c "exec pg_dump -U postgres ${db_name}" > "$backup_file_path"

    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}${BOLD}✓ SUCESSO ✓${NC}: Backup do banco de dados '${db_name}' criado com sucesso."
    else
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao criar o backup do banco de dados '${db_name}'."
        return 1
    fi
    sleep 0.3 
    main_menu
}
# --->>> //POSTGRESQL <<<---

# --->>> MARIADB <<<----
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
# Definir variáveis de ambiente para o MariaDB
ENV MARIADB_ROOT_PASSWORD=$db_password
ENV MARIADB_USER=$db_user
ENV MARIADB_PASSWORD=$db_password
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
function restore_backup_mariadb() {
    local container_name
    local backup_file_path
    local database_name

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Restaurar Backup MariaDB${NC}${BLUE} :::...${NC}"
    echo -ne " ${INPUT}↳${NC} Informe o nome do container MariaDB: "
    read container_name

    if [ -z "${container_name}" ]; then
        echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Nome do container não pode ser vazio!"
        return 1
    fi

    if ! check_container_exists "${container_name}"; then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: O container '${container_name}' não existe."
        return 1
    fi

    echo -ne " ${INPUT}↳${NC} Informe o nome do banco de dados MariaDB: "
    read database_name

    if [ -z "${database_name}" ]; then
        echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Nome do banco de dados não pode ser vazio!"
        return 1
    fi

    echo -ne " ${INPUT}↳${NC} Informe o caminho completo do arquivo de backup: "
    read backup_file_path

    if [ ! -f "$backup_file_path" ]; then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: O arquivo de backup '${backup_file_path}' não existe."
        return 1
    fi

    if ! check_container_running "${container_name}"; then
        echo -e "${INFO}${BOLD}ℹ INFO ℹ${NC}: O container '${container_name}' não está em execução. Iniciando o container..."
        docker start "$container_name"
        if [ $? -ne 0 ]; then
            echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao iniciar o container '${container_name}'."
            return 1
        fi
    fi

    echo -e "${NL}${BLUE} >>>${NC}${BOLD} Verificando a existência do banco de dados '${database_name}' no container '${container_name}' ${NC}${BLUE}<<<${NC}"
    db_exists=$(docker exec "$container_name" sh -c "exec mariadb -u root -p\${MARIADB_ROOT_PASSWORD} -e 'SHOW DATABASES LIKE \"${database_name}\";'")
    if [ -z "$db_exists" ]; then
        echo -e "${INFO}${BOLD}ℹ INFO ℹ${NC}: O banco de dados '${database_name}' não existe. Criando o banco de dados..."
        docker exec "$container_name" sh -c "exec mariadb -u root -p\${MARIADB_ROOT_PASSWORD} -e 'CREATE DATABASE ${database_name};'"
        if [ $? -ne 0 ]; then
            echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao criar o banco de dados '${database_name}'."
            return 1
        fi
    fi

    echo -e "${NL}${BLUE} >>>${NC}${BOLD} Restaurando o backup no container '${container_name}' no banco de dados '${database_name}' ${NC}${BLUE}<<<${NC}"
    docker exec -i "$container_name" sh -c "exec mariadb -u root -p\${MARIADB_ROOT_PASSWORD} ${database_name}" < "$backup_file_path"

    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}${BOLD}✓ SUCESSO ✓${NC}: Backup restaurado com sucesso no container '${container_name}' no banco de dados '${database_name}'."
    else
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao restaurar o backup no container '${container_name}' no banco de dados '${database_name}'."
        return 1
    fi

    sleep 0.3
    main_menu
}
function backup_mariadb() {
    local container_name
    local db_name
    local backup_file_path

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Backup MariaDB${NC}${BLUE} :::...${NC}"

    while true; do
        echo -ne " ${INPUT}↳${NC} Informe o nome do container MariaDB: "
        read container_name
        if [ -z "${container_name}" ]; then
            echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Nome do container não pode ser vazio!"
            continue
        fi

        if ! check_container_exists "${container_name}"; then
            echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: O container '${container_name}' não existe."
            continue
        fi
        break
    done

    while true; do
        echo -ne " ${INPUT}↳${NC} Informe o nome do banco de dados MariaDB: "
        read db_name

        if [ -z "$db_name" ]; then
            echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Nome do banco de dados não pode ser vazio!"
            continue
        fi
        break
    done

    while true; do
        echo -ne " ${INPUT}↳${NC} Informe o caminho completo para salvar o backup (incluir o nome do arquivo): "
        read backup_file_path

        local dir_path
        dir_path=$(dirname "$backup_file_path")

        if [ ! -d "$dir_path" ]; then
            echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: O diretório '${dir_path}' não existe."
            continue
        fi
        break
    done

    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo -e "${INFO}${BOLD}ℹ INFO ℹ${NC}: O container '${container_name}' não está em execução. Iniciando container..."
        docker start "$container_name"
        if [ $? -ne 0 ]; then
            echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao iniciar o container '${container_name}'."
            return 1
        fi
    fi

    echo -e "${NL}${BLUE} >>>${NC}${BOLD} Criando backup do banco de dados '${db_name}' ${NC}${BLUE}<<<${NC}"
    docker exec "$container_name" sh -c "exec mariadb-dump -u root -p\${MARIADB_ROOT_PASSWORD} ${db_name}" > "$backup_file_path"

    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}${BOLD}✓ SUCESSO ✓${NC}: Backup do banco de dados '${db_name}' criado com sucesso."
    else
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao criar o backup do banco de dados '${db_name}'."
        return 1
    fi

    sleep 0.3
    main_menu
}
# --->>> //MARIADB <<<---
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
function restore_backup_mysql() {
    local container_name
    local backup_file_path
    local database_name

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Restaurar Backup${NC}${BLUE} :::...${NC}"
    echo -ne " ${INPUT}↳${NC} Informe o nome do container: "
    read container_name

    if [ -z "${container_name}" ]; then
        echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Nome do container não pode ser vazio!"
        return 1
    fi

    if ! check_container_exists "$container_name"; then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: O container '${container_name}' não existe."
        return 1
    fi

    echo -ne " ${INPUT}↳${NC} Informe o nome do banco de dados: "
    read database_name

    if [ -z "${database_name}" ]; then
        echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Nome do banco de dados não pode ser vazio!"
        return 1
    fi

    echo -ne " ${INPUT}↳${NC} Informe o caminho completo do arquivo de backup: "
    read backup_file_path

    if [ ! -f "$backup_file_path" ]; then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: O arquivo de backup '${backup_file_path}' não existe."
        return 1
    fi

    if ! check_directory_exists "$(dirname "$backup_file_path")"; then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: O diretório '$(dirname "$backup_file_path")' não existe."
        return 1
    fi

    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo -e "${INFO}${BOLD}ℹ INFO ℹ${NC}: O container '${container_name}' não está em execução. Iniciando o container..."
        docker start "$container_name"
        if [ $? -ne 0 ]; then
            echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao iniciar o container '${container_name}'."
            return 1
        fi
    fi

    echo -e "${NL}${BLUE} >>>${NC}${BOLD} Verificando a existência do banco de dados '${database_name}' no container '${container_name}' ${NC}${BLUE}<<<${NC}"
    db_exists=$(docker exec "$container_name" sh -c "exec mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'SHOW DATABASES LIKE \"${database_name}\";'")
    if [ -z "$db_exists" ]; then
        echo -e "${INFO}${BOLD}ℹ INFO ℹ${NC}: O banco de dados '${database_name}' não existe. Criando o banco de dados..."
        docker exec "$container_name" sh -c "exec mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'CREATE DATABASE ${database_name};'"
        if [ $? -ne 0 ]; then
            echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao criar o banco de dados '${database_name}'."
            return 1
        fi
    fi

    echo -e "${NL}${BLUE} >>>${NC}${BOLD} Restaurando o backup no container '${container_name}' no banco de dados '${database_name}' ${NC}${BLUE}<<<${NC}"
    docker exec -i "$container_name" sh -c "exec mysql -u root -p\${MYSQL_ROOT_PASSWORD} ${database_name}" < "$backup_file_path"

    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}${BOLD}✓ SUCESSO ✓${NC}: Backup restaurado com sucesso no container '${container_name}' no banco de dados '${database_name}'."
    else
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao restaurar o backup no container '${container_name}' no banco de dados '${database_name}'."
        return 1
    fi

    sleep 0.3
    main_menu
}
function backup_mysql() {
    local container_name
    local db_name
    local backup_file_path

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Cria Backup${NC}${BLUE} :::..."

    while true; do
        echo -ne " ${INPUT}↳${NC} Informe o nome do container MySQL: "
        read container_name
        if [ -z "${container_name}" ]; then
            echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Nome do container não pode ser vazio!"
            continue
        fi

        if ! check_container_exists "$container_name"; then
            echo -e "${ERROR}${BOLD}✕ ERRO ✕: O container '${container_name}' não existe."
            continue
        fi
        break
    done
    
    while true; do
        echo -ne " ${INPUT}↳${NC} Informe o nome do banco de dados MySQL: "
        read db_name

        if [ -z "$db_name" ]; then
            echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Nome do banco de dados não pode ser vazio!"
            continue
        fi
        break
    done

    while true; do
        echo -ne " ${INPUT}↳${NC} Informe o caminho completo para salvar o backup (incluir o nome do arquivo): "
        read backup_file_path

        if [ -z "$backup_file_path" ]; then
            echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: O diretório '${backup_file_path}' não existe."
            continue
        fi        
        if ! check_directory_exists "$(dirname "$backup_file_path")"; then
            echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: O diretório '$(dirname "$backup_file_path")' não existe."
            continue
        fi

        break
    done

    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo -e "${INFO}${BOLD}ℹ INFO ℹ${NC}: O container '${container_name}' não está em execução. Iniciando container..."
        docker start "$container_name"
        if [ $? -ne 0 ]; then
            echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao iniciar o container '${container_name}'."
            return 1
        fi
    fi

    echo -e "${NL}${BLUE} >>>${NC}${BOLD} Criando backup do banco de dados '${db_name}' ${NC}${BLUE}<<<${NC}"
    docker exec "$container_name" sh -c "exec mysqldump -u root -p\${MYSQL_ROOT_PASSWORD} ${db_name}" > "$backup_file_path"

    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}${BOLD}✓ SUCESSO ✓${NC}: Backup do banco de dados '${db_name}' criado com sucesso."
    else
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao criar o backup do banco de dados '${db_name}'."
        return 1
    fi

    sleep 0.3
    main_menu
}
# --->>> // MYSQL <<<---

# --->>> APACHE2 <<<---
function apache_static_site(){
    local container_name
    local site_directory

    while true; do
        echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Criando Container Apache${NC} ${BLUE}:::...${NC}"
        echo -ne " ${INPUT}↳${NC} Informe o nome do novo container: "
        read container_name

        if check_container_name "$container_name"; then
            break
        fi
    done

    while true; do 
        echo -ne " ${INPUT}↳${NC} Informe o caminho completo do diretório do site estático: "
        read site_directory

        if check_directory_exists "$site_directory"; then
            break
        else 
           echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: O diretório '${site_directory}' não existe. Tente novamente."
        fi
    done

    local suggested_port
    if ! suggested_port=$(check_and_suggest_port 8080 8099); then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Todas as portas entre 8080 e 8099 estão ocupadas. Não é possível criar o container."
        return 1
    fi
     echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Criando e iniciando container Apache${NC} ${BLUE}:::...${NC}"
    docker run -d --name "$container_name" -p $suggested_port:80 -v "$site_directory":/usr/local/apache2/htdocs/ httpd:2.4

    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}${BOLD}✓ SUCESSO ✓${NC}: Container '${container_name}' criado e executando na porta $suggested_port."
        echo -e " ${MAGENTA}🜙 ${NC}Container: ${BOLD}$container_name${NC}"
        echo -e " ${MAGENTA}🜙 ${NC}Porta: ${BOLD}$suggested_port${NC}"
        sleep 0.3
        main_menu
    else
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao criar o container '${container_name}'."
        return 1
    fi
} 
function reverse_proxy_apache() {
    local container_name
    local upstream_url

    while true; do
        echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Criando container Apache (Proxy Reverso)${NC} ${BLUE}:::...${NC}"
        echo -ne " ${INPUT}↳${NC} Informe o nome do novo container: "
        read container_name

        if check_container_name "$container_name"; then
            break
        fi
    done

    echo -ne " ${INPUT}↳${NC} Informe a URL do upstream da API (ex: http://endereco-da-api:porta): "
    read upstream_url

    local suggested_port
    if ! suggested_port=$(check_and_suggest_port 8080 8099); then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Todas as portas entre 8080 e 8099 estão indisponíveis. Não é possível criar o container."
        return 1
    fi

    mkdir -p configs

    cat > configs/httpd.conf <<EOF
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_http_module modules/mod_proxy_http.so
LoadModule log_config_module modules/mod_log_config.so
LoadModule mpm_event_module modules/mod_mpm_event.so
LoadModule authz_core_module modules/mod_authz_core.so

<VirtualHost *:80>
    ServerName localhost
    ProxyPreserveHost On
    ProxyPass / $upstream_url
    ProxyPassReverse / $upstream_url
    <Proxy *>
        Require all granted
    </Proxy>
    ErrorLog /usr/local/apache2/logs/error.log
    CustomLog /usr/local/apache2/logs/access.log combined
</VirtualHost>
EOF

    cat > configs/Dockerfile-apache <<EOF
FROM httpd:latest
COPY configs/httpd.conf /usr/local/apache2/conf/httpd.conf
RUN mkdir -p /usr/local/apache2/logs && chmod -R 777 /usr/local/apache2/logs
EOF

    echo -e "${NL}${BLUE} ...:::${NC}${BOLD}Construindo imagem Docker${NC}${BLUE} :::...${NC}"
    docker build -t apache-image -f configs/Dockerfile-apache .

    if [ $? -ne 0 ]; then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao construir a imagem Docker."
        return 1
    fi

    docker run -d --name $container_name -p $suggested_port:80 apache-image
    
    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}${BOLD}✓ SUCESSO ✓${NC}: Container '${container_name}' criado e executando na porta $suggested_port."
        echo -e " ${MAGENTA}🜙 ${NC}Container: ${BOLD}$container_name${NC}"
        echo -e " ${MAGENTA}🜙 ${NC}Proxy reverso para: ${BOLD}$upstream_url${NC}"
        echo -e " ${MAGENTA}🜙 ${NC}Porta: ${BOLD}$suggested_port${NC}"
        sleep 0.3
        main_menu
    else
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao criar o container '${container_name}'."
        return 1
    fi
}



# --->>> // APACHE2 <<<---
# --->>> NGINX <<<---
function create_nginx_frontend_container() {
    local container_name
    local frontend_dir

    while true; do
        echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Criando Nginx para Frontend${NC} ${BLUE}:::...${NC}"
        
        echo -ne " ${INPUT}↳${NC} Informe o nome do novo container: "
        read container_name

        if check_container_name "$container_name"; then
            break  
        fi
    done

    while true; do
        echo -ne " ${INPUT}↳${NC} Informe o caminho completo do diretório do frontend: "
        read frontend_dir

        if check_directory_exists "$frontend_dir"; then
            break
        else
            echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Diretório '${frontend_dir}' não existe. Tente novamente."
        fi
    done

    local suggested_port
    if ! suggested_port=$(check_and_suggest_port 8080 8080 8099); then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Todas as portas entre 8080 e 8099 estão ocupadas. Não é possível criar o container."
        return 1
    fi

    mkdir -p configs
    cp -r "$frontend_dir" configs/frontend

    cat > configs/Dockerfile-frontend <<EOF
FROM nginx:latest
COPY frontend /usr/share/nginx/html
EXPOSE 80
EOF

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Construindo imagem Docker${NC} ${BLUE}:::...${NC}"
    docker build -t frontend-image -f configs/Dockerfile-frontend configs

    if [ $? -ne 0 ]; then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao construir a imagem Docker."
        return 1
    fi

    docker run -d --name $container_name -p $suggested_port:80 frontend-image

    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}${BOLD}✓ SUCESSO ✓${NC}: Container '${container_name}' criado e executando na porta $suggested_port."
        echo -e " ${MAGENTA}🜙 ${NC}Container: ${BOLD}$container_name${NC}"
        echo -e " ${MAGENTA}🜙 ${NC}Porta: ${BOLD}$suggested_port${NC}"
        echo -e " ${MAGENTA}🜙 ${NC}Diretório Frontend: ${BOLD}$frontend_dir${NC}"
        sleep 0.3
        main_menu
    else
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao criar o container '${container_name}'."
        return 1
    fi
}

function reverse_proxy_nginx(){
    local container_name
    local upstream_url
    while true; do
        echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Criando container Nginx (Proxy Reverso)${NC} ${BLUE}:::...${NC}"
        echo -ne " ${INPUT}↳${NC} Informe o nome do novo container: "
        read container_name

        if check_container_name "$container_name"; then
            break
        fi
    done

    echo -ne " ${INPUT}↳${NC} Informe a URL do upstream da API (ex: http://endereco-da-api:porta): "
    read upstream_url

    local suggested_port
    if ! suggested_port=$(check_and_suggest_port 8080 8099); then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Todas as portas entre 8080 e 8099 estão indisponíveis. Não é possível criar o container."
        return 1
    fi

    mkdir -p configs

    cat > configs/nginx.conf <<EOF
events {}
http {
    server {
        listen 80;
        location / {
            proxy_pass $upstream_url;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOF
    cat > configs/Dockerfile-nginx << EOF
FROM nginx:latest
COPY configs/nginx.conf /etc/nginx/nginx.conf
EOF

    echo -e "${NL}${BLUE} ...:::${NC}${BOLD}Construindo imagem Docker${NC}${BLUE} :::...${NC}"
    docker build -t nginx-image -f configs/Dockerfile-nginx .

    if [ $? -ne 0 ]; then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao construir a imagem Docker."
        return 1
    fi

    docker run -d --name $container_name -p $suggested_port:80 nginx-image
    
    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}${BOLD}✓ SUCESSO ✓${NC}: Container '${container_name}' criado e executando na porta $suggested_port."
        echo -e " ${MAGENTA}🜙 ${NC}Container: ${BOLD}$container_name${NC}"
        echo -e " ${MAGENTA}🜙 ${NC}Proxy reverso para: ${BOLD}$upstream_url${NC}"
        echo -e " ${MAGENTA}🜙 ${NC}Porta: ${BOLD}$suggested_port${NC}"
        sleep 0.3
        main_menu
    else
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao criar o container '${container_name}'."
        return 1
    fi
}
# --->>> //NGINX <<<---

# --->>> VSFTPD <<<---
function create_vsftpd_container() {
    local container_name
    local sftp_user
    local sftp_password

    while true; do
        echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Criando SFTP${NC} ${BLUE}:::...${NC}"
        
        echo -ne " ${INPUT}↳${NC} Informe o nome do novo container: "
        read container_name

        if check_container_name "$container_name"; then
            break  
        fi
    done

     while true; do
        echo -ne " ${INPUT}↳${NC} Informe o nome do usuário SFTP: "
        read sftp_user

        echo -ne " ${INPUT}↳${NC} Informe a senha do usuário SFTP: "
        read -s sftp_password
        echo

        if [ -n "$sftp_user" ] && [ -n "$sftp_password" ]; then
            break
        else
            echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Usuário e senha não podem ser vazios!"
        fi
    done

    local suggested_port
    if ! suggested_port=$(check_and_suggest_port 22 22 29); then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Todas as portas entre 22 e 29 estão ocupadas. Não é possível criar o container."
        return 1
    fi

    mkdir -p configs

    cat > configs/Dockerfile-sftp <<EOF
FROM ubuntu:latest
RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:screencast' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN mkdir /home/$sftp_user
RUN useradd -d /home/$sftp_user -s /bin/bash $sftp_user
RUN echo '$sftp_user:$sftp_password' | chpasswd
RUN chown -R $sftp_user:$sftp_user /home/$sftp_user
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
EOF

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Construindo imagem Docker${NC} ${BLUE}:::...${NC}"
    docker build -t sftp-image -f configs/Dockerfile-sftp .

    if [ $? -ne 0 ]; then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao construir a imagem Docker."
        return 1
    fi

    docker run -d --name $container_name -p $suggested_port:22 sftp-image

    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}${BOLD}✓ SUCESSO ✓${NC}: Container '${container_name}' criado e executando na porta $suggested_port."
        echo -e " ${MAGENTA}🜙 ${NC}Container: ${BOLD}$container_name${NC}"
        echo -e " ${MAGENTA}🜙 ${NC}SFTP: ${BOLD}OpenSSH${NC}"
        echo -e " ${MAGENTA}🜙 ${NC}Porta: ${BOLD}$suggested_port${NC}"
        echo -e " ${MAGENTA}🜙 ${NC}Usuário: ${BOLD}$sftp_user${NC}"
        sleep 0.3
        main_menu
    else
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao criar o container '${container_name}'."
        return 1
    fi
}
# --->>> //VSFTPD <<<---
# --->>> OpenSSH <<<---
function create_ssh_sftp_container() {
    local container_name
    local sftp_user
    local sftp_password

    while true; do
        echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Criando SFTP${NC} ${BLUE}:::...${NC}"
        
        echo -ne " ${INPUT}↳${NC} Informe o nome do novo container: "
        read container_name

        if check_container_name "$container_name"; then
            break  
        fi
    done

    while true; do
        echo -ne " ${INPUT}↳${NC} Informe o nome do usuário SFTP: "
        read sftp_user

        echo -ne " ${INPUT}↳${NC} Informe a senha do usuário SFTP: "
        read -s sftp_password
        echo

        if [ -n "$sftp_user" ] && [ -n "$sftp_password" ]; then
            break
        else
            echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Usuário e senha não podem ser vazios!"
        fi
    done

    local suggested_port
    if ! suggested_port=$(check_and_suggest_port 2222 2299); then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Todas as portas entre 2222 e 2299 estão ocupadas. Não é possível criar o container."
        return 1
    fi

    mkdir -p configs

    echo "$sftp_user:$sftp_password:1001" > configs/users.conf

    cat > configs/sshd_config <<EOF
Subsystem sftp internal-sftp
Match User $sftp_user
    PasswordAuthentication yes
    ChrootDirectory /home/$sftp_user
    ForceCommand internal-sftp
    AllowTcpForwarding no
EOF

    cat > Dockerfile <<EOF
# Usar a imagem Debian como base
FROM debian:latest
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server \
    && mkdir /var/run/sshd \
    && useradd -m cristian \
    && echo "cristian:calangos" | chpasswd \
    && chown root:root /home/cristian \
    && chmod 755 /home/cristian \
    && mkdir /home/cristian/upload \
    && chown cristian:cristian /home/cristian/upload \
    && echo "Subsystem sftp internal-sftp" >> /etc/ssh/sshd_config

COPY configs/sshd_config /etc/ssh/sshd_config
VOLUME /home/cristian
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
EOF

    echo -e "${NL}${BLUE} ...::: ${NC}${BOLD}Construindo imagem Docker${NC} ${BLUE}:::...${NC}"
    docker build -t sftp-image .

    if [ $? -ne 0 ]; then
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao construir a imagem Docker."
        return 1
    fi

    docker run -d --name $container_name -p $suggested_port:22 \
      -v $(pwd)/configs/users.conf:/etc/sftp-users.conf \
      sftp-image

    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}${BOLD}✓ SUCESSO ✓${NC}: Container '${container_name}' criado e executando na porta $suggested_port."
        echo -e " ${MAGENTA}🜙 ${NC}Container: ${BOLD}$container_name${NC}"
        echo -e " ${MAGENTA}🜙 ${NC}SFTP via SSH: ${BOLD}OpenSSH${NC}"
        echo -e " ${MAGENTA}🜙 ${NC}Porta: ${BOLD}$suggested_port${NC}"
        echo -e " ${MAGENTA}🜙 ${NC}Usuário: ${BOLD}$sftp_user${NC}"
        sleep 0.3
        main_menu
    else
        echo -e "${ERROR}${BOLD}✕ ERRO ✕${NC}: Falha ao criar o container '${container_name}'."
        return 1
    fi
}
# --->>> //OpenSSH <<<---
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
function apache_menu(){
    echo -e "${NL}${BLUE} #######################################"
    echo -e " ##              ${NC}${BOLD}APACHE   ${NC}${BLUE}            ##"
    echo -e " ##...................................##"
    echo -e " ##${NC} [${INPUT}1${NC}] - Hospedar um site estático   ${BLUE}##"
    echo -e " ##${NC} [${INPUT}2${NC}] - Proxy reverso para APIs     ${BLUE}##"
    echo -e " ##${NC} [${INPUT}0${NC}] - Voltar                      ${BLUE}##"
    echo -e " #######################################${NC}"
    echo -ne " ${INPUT}↳${NC} Selecione uma opção: "
    read -r web_option
    case $web_option in
        1)
            sleep 0.3
            apache_static_site
            ;;
        2)
            sleep 0.3
            reverse_proxy_apache
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
            apache_menu
            ;;     
    esac

}
function nginx_menu(){
    echo -e "${NL}${BLUE} #######################################"
    echo -e " ##               ${NC}${BOLD}NGINX  ${NC}${BLUE}             ##"
    echo -e " ##...................................##"
    echo -e " ##${NC} [${INPUT}1${NC}] - Hospedar um site estático   ${BLUE}##"
    echo -e " ##${NC} [${INPUT}2${NC}] - Proxy reverso para APIs     ${BLUE}##"
    echo -e " ##${NC} [${INPUT}0${NC}] - Voltar                      ${BLUE}##"
    echo -e " #######################################${NC}"
    echo -ne " ${INPUT}↳${NC} Selecione uma opção: "
    read -r web_option
    case $web_option in
        1)
            sleep 0.3
            create_nginx_frontend_container
            ;;
        2)
            sleep 0.3
            reverse_proxy_nginx
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
            nginx_menu
            ;;     
    esac

}
function web_server_menu(){
    echo -e "${NL}${BLUE} ########################"
    echo -e " ##     ${NC}${BOLD}WEB SERVERS${NC}${BLUE}    ##"
    echo -e " ##....................##"
    echo -e " ##${NC} [${INPUT}1${NC}] - Apache       ${BLUE}##"
    echo -e " ##${NC} [${INPUT}2${NC}] - Nginx        ${BLUE}##"
    echo -e " ##${NC} [${INPUT}0${NC}] - Voltar       ${BLUE}##"
    echo -e " ########################${NC}"
    echo -ne " ${INPUT}↳${NC} Selecione uma opção: "
    read -r server_option
    case $server_option in 
        1) 
            sleep 0.3
            apache_menu
            ;;
        2) 
            sleep 0.3
            nginx_menu
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
            web_server_menu
            ;;     
    esac
}

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
        restore_backup_mariadb
        ;;
    3)
        sleep 0.3
        backup_mariadb
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
        backup_mysql
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
        create_postgresql_container
        ;;
    2)
        sleep 0.3
        restore_backup_postgresql
        ;;
    3)
        sleep 0.3
        backup_postgresql
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
function sfpt_menu(){
    echo -e "${NL}${BLUE} ########################"
    echo -e " ##   ${NC}${BOLD}SERVIDORES SFTP${NC}${BLUE}  ##"
    echo -e " ##....................##"
    echo -e " ##${NC} [${INPUT}1${NC}] - OpenSSH      ${BLUE}##"
    echo -e " ##${NC} [${INPUT}2${NC}] - vsftpd       ${BLUE}##"
    echo -e " ##${NC} [${INPUT}0${NC}] - Voltar       ${BLUE}##"
    echo -e " ########################${NC}"
    echo -ne " ${INPUT}↳${NC} Selecione uma opção: "
    read -r server_option

    case $server_option in
        1)
            sleep 0.3
            create_ssh_sftp_container
            ;;
        2)
            sleep 0.3
            create_vsftpd_container
            ;;
       
        0)
            sleep 0.3
            main_menu
            ;;
        *)
            sleep 0.3
            echo -e "${WARNING}${BOLD}⚠ AVISO ⚠ ${NC}: Opção inválida!"
            sleep 0.3
            sftp_menu
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
                sfpt_menu
                ;;
            4)  sleep 0.3
                clear
                database_menu
                ;;
            5) sleep 0.3
                clear
                create_samba_container
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


