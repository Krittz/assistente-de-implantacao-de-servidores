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

# .........................::: CRIAÇÃO DE CONTAINERS :::.........................
create_samba() {
    DOCKERFILE="Dockerfile.samba"
    cat <<EOF >Dockerfiles/$DOCKERFILE
FROM debian:bookworm-slim
RUN apt update && apt install -y --no-install-recommends samba && apt clean && rm -rf /var/lib/apt/lists/*
EXPOSE 137/udp 138/udp 139/tcp 445/tcp

# Criação do arquivo smb.conf dentro do Dockerfile
RUN echo "[global]" > /etc/samba/smb.conf \
    && echo "    workgroup = WORKGROUP" >> /etc/samba/smb.conf \
    && echo "    server string = Samba Server %v" >> /etc/samba/smb.conf \
    && echo "    netbios name = samba-server" >> /etc/samba/smb.conf \
    && echo "    security = user" >> /etc/samba/smb.conf \
    && echo "[shared]" >> /etc/samba/smb.conf \
    && echo "    path = /samba" >> /etc/samba/smb.conf \
    && echo "    read only = no" >> /etc/samba/smb.conf \
    && echo "    guest ok = yes" >> /etc/samba/smb.conf

VOLUME /samba
CMD ["smbd", "--foreground", "--no-process-group"]
EOF

    echo "Dockerfile.samba criado com sucesso!"

    echo "Construindo container samba"
    docker build -t samba-container -f Dockerfiles/$DOCKERFILE Dockerfiles/

    echo "Escreva o caminho do diretório a ser compartilhado"
    read caminho

    if [ -z "$caminho" ]; then
        echo "O caminho do diretório a ser compartilhado não foi fornecido"
        return 1
    elif [ ! -d "$caminho" ]; then
        echo "O caminho fornecido não é um diretório válido."
        return 1
    fi
    echo "Executando o container Samba..."

    docker run -d --name samba-instance -p 137:137/udp -p 138:138/udp -p 445:445 -v $caminho:/samba samba-container

    if docker ps | grep -q samba-instance; then
        echo "O container Samba foi criado com sucesso."
    else
        echo "Falha ao criar o container Samba."
    fi
}


create_ssh() {
    clear
    echo -e "${BOLD} Qual a senha deseja configurar para o root do ssh: ${RESET}"
    read pass
    DOCKERFILE="Dockerfile.ssh"
    cat <<EOF >Dockerfiles/$DOCKERFILE
FROM debian:bookworm-slim
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y openssh-server && apt clean && rm -rf /var/lib/apt/lists/*
RUN mkdir /var/run/sshd
RUN echo "root:$pass" | chpasswd
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"] 
EOF

    echo "Dockerfile.ssh criado com sucesso."
    clear
    echo "Construindo container SSH"
    docker build -t ssh-container -f Dockerfiles/$DOCKERFILE Dockerfiles/

    echo "Executando o container SSH"
    docker run -d --name ssh-instance -p 2222:22 ssh-container

    if docker ps -a | grep -q ssh-instance; then
        echo "O container SSH foi criado com sucesso."
    else
        echo "Falha ao criar o container SSH."
    fi
}

create_vsftpd() {
    clear
    CONF="vsftpd.conf"
    cat <<EOF >Confs/$CONF
listen=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
EOF
    echo "Arquivo vsfptd.conf criado com sucesso."
    sleep 1
    clear
    DOCKERFILE="Dockerfile.vsftpd"
    cat <<EOF >Dockerfiles/$DOCKERFILE
FROM debian:bookworm-slim
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y vsftpd && apt clean && rm -rf /var/lib/apt/lists/*
COPY Confs/$CONF /etc/vsftpd.conf
RUN mkdir -p /var/ftp
RUN chown nobody:nogroup /var/ftp
RUN chmod a-w /var/ftp
EXPOSE 21
CMD ["vsftpd", "/etc/vsftpd.conf"]
EOF
    echo "$DOCKERFILE criado com sucesso."
    sleep 1

    clear
    echo "Construindo container vsftpd"
    docker build -t vsftpd-container -f Dockerfiles/$DOCKERFILE Dockerfiles/

    sleep 1
    echo "Executando container vsftpd"
    docker run -d --name vsftpd-instance -p 21:21 -v /var/ftp:/var/ftp vsftpd-container

    if docker ps | grep -q vsftpd-instance; then
        echo "O container vsftpd foi criado com sucesso"
    else
        echo "Falha ao criar container vsftpd"
    fi
}

create_proftpd() {
    clear
    CONF="proftpd.conf"
    cat <<EOF >Confs/$CONF
ServerName "FTP Server"
ServerType standalone
DefaultServer on
Port 21
Umask 022
MaxInstances 30
User nobody
Group nogroup
DefaultRoot ~
EOF
    echo "$CONF criado com sucesso"
    sleep 1
    clear
    DOCKERFILE="Dockerfile.proftpd"
    cat <<EOF >Dockerfiles/$DOCKERFILE
FROM debian:bookworm-slim
RUN apt update && DEBIAN_FRONTEND=noninteractve apt install -y proftpd && apt clean && rm -rf /var/lib/apt/lists/*
COPY $CONF /etc/proftpd/proftpd.conf
EXPOSE 21
CMD ["proftpd", "--nodaemon"]
EOF
    echo "$DOCKERFILE criado com sucesso"
    sleep 1
    clear

    echo "Construindo container proftpd"
    docker build -t proftpd-container -f Dockerfiles/$DOCKERFILE Dockerfiles/
    clear
    echo "Escreva o caminho do diretório a ser compartilhado"
    read caminho

    if [ -z "$caminho" ]; then
        echo "O caminho do diretório a ser compartilhado não foi fornecido"
        return 1
    elif [ ! -d "$caminho" ]; then
        echo "O caminho fornecido não é um diretório válido."
        return 1
    fi
    echo "Executando o container ProFTPD..."

    docker run -d --name proftpd-instance -p 21:21 -v $caminho:/var/ftp proftpd-container

    if docker ps | grep -q proftpd-instance; then
        echo "O container ProFTPD foi criado com sucesso."
    else
        echo "Falha ao criar o container ProFTPD."
    fi
}

create_lamp() {
    clear
    DOCKERFILE="Dockerfile.lamp"
    cat <<EOF >Dockerfiles/$DOCKERFILE
FROM debian:bookworm-slim
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y apache2 mysql-server php php-mysql && apt clean && rm -rf /var/lib/apt/lists/*
EXPOSE 80
CMD ["apachectl", "-D", "FOREGROUND"]
EOF
    echo "$DOCKERFILE criado com sucesso."
    sleep 1

    clear
    echo "Construindo container LAMP"
    docker build -t lamp-container -f Dockerfiles/$DOCKERFILE Dockerfiles/

    clear
    echo "Executando container LAMP"
    docker run -d --name lamp-instance -p 80:80 lamp-container
    if docker ps | grep -q lamp-instance; then
        echo "O container LAMP foi criado com sucesso."
    else
        echo "Falha ao criar o container LAMP"
    fi
}

container_create() {
    mkdir Dockerfiles
    mkdir Confs
    clear
    echo "╔═══════════════════════════╗"
    echo "║      CRIAR CONTAINER      ║"
    echo "╠═══════════════════════════╣"
    echo "║ [1] - Samba               ║"
    echo "║ [2] - Apache              ║"
    echo "║ [3] - Nginx               ║"
    echo "║ [4] - SSH                 ║"
    echo "║ [5] - ProFPTD             ║"
    echo "║ [6] - VsFTPD              ║"
    echo "║ [7] - Lamp                ║"
    echo "║ [0] - Voltar              ║"
    echo "╚═══════════════════════════╝"
    read op
    case $op in
    1) create_samba ;;
    2) create_apache ;;
    3) create_nginx ;;
    4) create_ssh ;;
    5) create_proftpd ;;
    6) create_vsftpd ;;
    7) create_lamp ;;
    0) return ;;
    *) echo "Erro: Opção inválida" ;;
    esac
}
# .........................::: FIM DA CRIAÇÃO DE CONTAINERS :::.........................
# ....................................................................................
# .........................::: MANIPULAÇÃO DO DOCKER :::.........................

docker_install() {
    clear
    docker --version
    if [ $? -eq 0 ]; then
        echo "Docker ja está instalado!"
    else
        clear
        echo "...::: Instalando Docker :::..."
        echo "Atualizando o sistema..."
        apt update && apt upgrade -y
        if [ $? -ne 0 ]; then
            echo "Erro ao atualizar o sistema. Verifique sua conexão com a internet e tente novamente."
            return
        fi
        clear
        echo "Instalando pacotes necessários..."
        apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
        if [ $? -ne 0 ]; then
            echo "Erro ao instalar pacotes necessários. Verifique sua conexão com a internet e tente novamente."
            return
        fi
        clear
        echo "Adicionando chave GPG do repositório Docker..."
        curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        if [ $? -ne 0 ]; then
            echo "Erro ao adicionar chave GPG do repositório Docker. Verifique sua conexão com a internet e tente novamente."
            return
        fi

        clear
        echo "Adicionando repositório Docker ao sistema..."
        echo "deb [signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
        apt update
        clear
        echo "Instalando Docker Engine..."
        apt install -y docker-ce docker-ce-cli containerd.io
        if [ $? -ne 0 ]; then
            echo "Erro ao instalar Docker Engine. Verifique sua conexão com a internet e tente novamente."
            return
        fi
        clear
        echo "Adicionando usuário ao grupo docker..."
        echo -e "${BOLD} Nome do usuário que ira utilizar o Docker: ${RESET}"
        read usr
        usermod -aG docker $usr
        chown $usr:docker /var/run/docker.sock
        systemctl restart docker
        clear
        docker --version
        if [ $? -eq 0 ]; then
            echo "Docker foi instalado com sucesso!"
        else
            echo "Erro: Docker não está instalado ou ocorreu um problema durante a verificação."
        fi

    fi

}
docker_uninstall() {
    clear
    docker --version
    if [ $? -eq 0 ]; then
        echo "Desinstalando Docker"
        apt purge docker-ce docker-ce-cli containerd.io -y && apt autoremove -y
        apt clean
        groupdel docker
    else
        echo "Docker não esta instalado"
    fi
}

docker_menu() {
    clear
    echo "╔═══════════════════════════╗"
    echo "║           DOCKER          ║"
    echo "╠═══════════════════════════╣"
    echo "║ [1] - Instalar            ║"
    echo "║ [2] - Desinstalar         ║"
    echo "║ [0] - Voltar              ║"
    echo "╚═══════════════════════════╝"
    read -p "OPÇÃO >>> " op
    case $op in
    1) docker_install ;;
    2) docker_uninstall ;;
    0) return ;;
    *) echo "Opção inválida" ;;
    esac
}
# .........................::: FIM DA MANIPULAÇÃO DO DOCKER :::.........................

menu() {
    while true; do
        clear
        echo "╔═══════════════════════════╗"
        echo "║        MENU PRINCIPAL     ║"
        echo "╠═══════════════════════════╣"
        echo "║ [1] - Docker              ║"
        echo "║ [2] - Criar container     ║"
        echo "║ [3] - Listar containers   ║"
        echo "║ [4] - Iniciar container   ║"
        echo "║ [5] - Parar container     ║"
        echo "║ [6] - Remover container   ║"
        echo "║ [0] - Sair                ║"
        echo "╚═══════════════════════════╝"
        echo -e "\n"
        echo -n "OPÇÃO >>> "
        read op
        case $op in
        1) docker_menu ;;
        2) container_create ;;
        3) list ;;
        4) start ;;
        5) stop ;;
        6) remove ;;
        0) exit 0 ;;
        *) echo "Opção inválida" ;;
        esac
    done
}

if [ "$(id -u)" -ne 0 ]; then
    clear
    echo "Por favor, execute este script como root"
    exit 1
fi

menu
