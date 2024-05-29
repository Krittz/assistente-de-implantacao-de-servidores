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
NL='\n'
BLINK='\033[5m'

# --->>> MENUS <<<---
function apache_menu(){}
function nginx_menu(){}

function servers_menus(){
    echo -e "${NL}${BLUE}########################"
    echo -e "##     ${NC}${BOLD}SERVIDORES${NC}${BLUE}     ##"
    echo -e "##....................##"
    echo -e "##${NC} [1] - Apache       ${BLUE}##"
    echo -e "##${NC} [2] - NginX        ${BLUE}##"
    echo -e "##${NC} [3] - Samba        ${BLUE}##"
    echo -e "##${NC} [4] - ProFTPD      ${BLUE}##"
    echo -e "##${NC} [5] - vsFPTD       ${BLUE}##"
    echo -e "########################${NC}"
    
}

function main_menu(){}