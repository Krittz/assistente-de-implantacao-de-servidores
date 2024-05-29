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
    echo -ne " ${BLINK}${INPUT}>>>${NC} Selecione uma opção: "
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
    echo -ne " ${BLINK}${INPUT}>>>${NC} Selecione uma opção: "
    read -r database_option
    case $database_option in
        1)
            sleep 0.3
            echo "mysql_menu"
            ;;
        2)
            sleep 0.3
           echo "mariadb_menu"
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

#function apache_menu(){}
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
    echo -ne " ${BLINK}${INPUT}>>>${NC} Selecione uma opção: "
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
#database_menu
fpt_server_menu