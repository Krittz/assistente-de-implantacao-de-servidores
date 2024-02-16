#!/bin/bash
clear
Menu() {
    clear
    echo -e '\n'
    echo "=========================="
    echo "          MAPRIJE   "
    echo "=========================="
    echo "       ============       "
    echo "          ======          "
    echo "            ==            "
    echo "__________________________"
    echo "[ 1 ] | SSH_E_SCP"
    echo "[ 2 ] | WEB"
    echo "[ 3 ] | FTP"
    echo "[ 4 ] | SAMBA"
    echo "[ 5 ] | CONF_REDE"
    echo "[ 6 ] | ALTERAR_NOME_PC"
    echo "[ 0 ] | SAIR"
    echo -e '\n'
    echo "RESPOSTA: "
    read opcao
    case $opcao in
    1) SSH_E_SCP;;
    2) WEB ;;
    3) FTP ;;
    4) SAMBA ;;
    5) CONF_REDE ;;
    6) ALTERAR_NOME_PC ;;
    0) SAIR ;;
    *) "Comando desconhecido" ; echo ; Menu;;
    esac
    }

SSH_E_SCP () {
clear
    echo "SSH_E_SCP  "
    echo "O que deseja fazer?"
    echo "install ou remove"
    echo "[ 1 ] Voltar"
    echo "[ 0 ] Sair"
    read opcao
    case $opcao in
   
    "install")apt install ssh -y ;;
    "remove")apt remove ssh -y ;;
    1) Voltar ;;
    0) Sair ;;
    
    *) "Comando desconhecido" ; echo ; SSH_E_SCP  ;;
    esac
     echo "Serviço concluído"
     sleep 2
     ./edu.sh
     
}
WEB () {
clear
    echo "WEB "
    echo "O que deseja fazer?"
    echo "start, stop, install ou desinstall"
    echo "[ 1 ] Voltar"
    echo "[ 0 ] Sair"
    chmod u=rwx,g=rwx,o=rwx web.sh
    read opcao
    case $opcao in
    1) Voltar ;;
    0) Sair ;;
    "start")./web.sh start;;
    "stop")./web.sh stop;;
    "install")./web.sh install;;
    "desinstall")./web.sh desinstall;;
     *) "Comando desconhecido" ; echo ; WEB  ;;
     
    esac
    echo "serviço concluido"
    sleep 2
    ./edu.sh
}
FTP () {
    clear
    echo "Serviço FTP"
    echo "Digite o serviço FTP que deseja"
    echo "start, stop, restart, configure, install ou desinstall"
    echo "[ 1 ] Voltar"
    echo "[ 0 ] Sair"
    chmod u=rwx,g=rwx,o=rwx ftp.sh
    read opcao
    case "$opcao" in
    
    1) Voltar ;;
    0) Sair ;;

    "start")  ./ftp.sh start ;;       
    "stop") ./ftp.sh stop ;;
    "restart") ./ftp.sh restart ;;
    "configure") ./ftp.sh configure ;;
    "install") ./ftp.sh install ;;
    "desinstall") ./ftp.sh desinstall ;;
    
    esac 
    echo "Serviço FTP Concluído"
    sleep 2
    ./edu.sh
    
    
   
}

SAMBA() {
    clear
    echo "Serviço SAMBA"
    echo "Digite o serviço SAMBA que deseja"
    echo "start, stop, restart, configure, install ou desinstall"
    echo "[ 1 ] Voltar"
    echo "[ 0 ] Sair"
    chmod u=rwx,g=rwx,o=rwx samba2.sh
    read opcao
    case "$opcao" in
    
    1) Voltar ;;
    0) Sair ;;

    "start")  ./samba2.sh start;;
    "stop") ./samba2.sh stop;;
    "restart") ./samba2.sh restart;;
    "configure") ./samba2.sh configure ;;
    "install") ./samba2.sh install ;;
    "desinstall") ./samba2.sh desinstall ;;
    *) echo "Use os parâmetros start, stop, restart, configure, install ou desinstall"
    esac

    echo "Serviço SAMBA Concluído"
      sleep 2
    ./edu.sh
}


CONF_REDE() {
    clear
    echo "CONF_REDE"
    echo "O que deseja fazer?"
    echo "install, list, stop, up, newip"
    echo "[ 1 ] Voltar"
    echo "[ 0 ] Sair"
    chmod u=rwx,g=rwx,o=rwx conf_rede.sh
    read opcao
    case "$opcao" in
    1) Voltar ;;
    0) Sair ;;
    
	"install") ./conf_rede.sh install;;
	"list") ./conf_rede.sh  list;;
	"stop") ./conf_rede.sh  stop;;
	"up") ./conf_rede.sh  up;;
	"newip") ./conf_rede.sh  newip;;
    *) echo "Use os parâmetros install, stop, list, up, newip"
    esac
 
    echo "Serviço concluído"
    sleep 2
    ./edu.sh
 
   
}

ALTERAR_NOME_PC () {
    clear
    echo "ALTERAR NOME DO PC"
    echo "O que deseja fazer?"
    echo "[ 1 ] Voltar"
    echo "[ 0 ] Sair"
    nano /etc/hosts
    nano /etc/hostname
    nano /proc/sys/kernel/hostname
    echo "Serviço concluído."
    read opcao
    case $opcao in
    1) Voltar ;;
    0) Sair ;;
    *) "Comando desconhecido" ; echo ; ALTERAR_NOME_PC   ;;
 esac  
    echo "Serviço concluído"
    sleep 2
   ./edu.sh
 
 
 } 
  

Voltar() {
    clear
        Menu
}

Sair() {
    clear
    exit
}
clear
Menu
