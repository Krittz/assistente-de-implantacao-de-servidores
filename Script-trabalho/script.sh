#!/bin/bash
RED="\e[91m"
GREEN="\e[92m"
YELLOW="\e[93m"
CYAN="\e[96m"
BOLD="\e[1m"
BLUE="\e[34m"
RESET="\e[0m"
MAGENTA="\e[35m"
PISCAR="\e[5m"
menu(){
echo "............................................."
echo "............................................."
echo -e "....::::${BOLD}${MAGENTA}╔═══════════════════════════╗${RESET}::::...."
echo -e "....::::${BOLD}${MAGENTA}║${RESET}      ${YELLOW}Menu Principal     ${RESET}  ${BOLD}${MAGENTA}║${RESET}::::...."
echo -e "....::::${BOLD}${MAGENTA}╠═══════════════════════════╣${RESET}::::...."
echo -e "....::::${BOLD}${MAGENTA}║${RESET} ${GREEN}Escolha uma opção:${RESET}        ${BOLD}${MAGENTA}║${RESET}::::...."
echo -e "....::::${BOLD}${MAGENTA}║${RESET} 1. ${GREEN}${BOLD}SSH & SCP${RESET}              ${BOLD}${MAGENTA}║${RESET}::::...."
echo -e "....::::${BOLD}${MAGENTA}║${RESET} 2. ${GREEN}${BOLD}FTP${RESET}                    ${BOLD}${MAGENTA}║${RESET}::::...."
echo -e "....::::${BOLD}${MAGENTA}║${RESET} 3. ${GREEN}${BOLD}SAMBA${RESET}                  ${BOLD}${MAGENTA}║${RESET}::::...."
echo -e "....::::${BOLD}${MAGENTA}║${RESET} 4. ${GREEN}${BOLD}LAMP${RESET}                   ${BOLD}${MAGENTA}║${RESET}::::...."
echo -e "....::::${BOLD}${MAGENTA}║${RESET} 5. ${GREEN}${BOLD}NET_TOOLS${RESET}              ${BOLD}${MAGENTA}║${RESET}::::...."
echo -e "....::::${BOLD}${MAGENTA}║${RESET} 6. ${GREEN}${BOLD}IP A  ${RESET}                 ${BOLD}${MAGENTA}║${RESET}::::...."
echo -e "....::::${BOLD}${MAGENTA}║${RESET} 7. ${GREEN}${BOLD}Opção 7${RESET}                ${BOLD}${MAGENTA}║${RESET}::::...."
echo -e "....::::${BOLD}${MAGENTA}║${RESET} 0. ${RED}${BOLD}Sair${RESET}                   ${BOLD}${MAGENTA}║${RESET}::::...."
echo -e "....::::${BOLD}${MAGENTA}╚═══════════════════════════╝${RESET}::::...."

echo -e "       ${BOLD} OPÇÃO: ${RESET}"

read opcao

case $opcao in
1) 
    ssh_scp
    ;;
2)
    FTP
    ;;
3) SAMBA ;;
4) LAMP;;
5) NET_TOOLS;;
6) IP_A;;
0) 
    echo "Script encerrado..."
    exit 0
;;
*) echo "Opção invalida"
esac

}
ssh_scp(){   
clear
echo -e "   ${BLUE}╔═══════════════════════════╗${RESET}"
echo -e "   ${BLUE}║         ${BOLD}${GREEN}SSH & SCP${RESET}${BLUE}         ║${RESET}"
echo -e "   ${BLUE}╠═══════════════════════════╣${RESET}"
echo -e "   ${BLUE}║ 1. Instalar               ║${RESET}"
echo -e "   ${BLUE}║ 2. Desinstalar            ║${RESET}"
echo -e "   ${BLUE}║                           ║${RESET}"
echo -e "   ${BLUE}║ 0. Voltar <<<             ║${RESET}"
echo -e "   ${BLUE}╚═══════════════════════════╝${RESET}"



}

clear
echo -e "${BLUE}${BOLD}⠀⠀⠀⠀⠀⠀⢀⣠⣤⣶⣶⡞⡀⣤⣬⣴⠀⠀⢳⣶⣶⣤⣄⡀⠀⠀⠀⠀⠀⠀${RESET}    ${CYAN}${BOLD}Título:${RESET} Assistente de Instalação de Serviços Linux"
echo -e "${BLUE}${BOLD}⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⡇⠀⢸⣿⠿⣿⡇⠀⠀⠸⣿⣿⣿⣿⣷⣦⡀⠀⠀⠀${RESET}    "
echo -e "${BLUE}${BOLD}⠀⠀⢠⡾⣫⣿⣻⣿⣽⣿⡇⠀⠈⢿⣧⡝⠟⠀⠀⢸⣿⣿⣿⣿⣿⣟⢷⣄⠀⠀${RESET}    ${CYAN}${BOLD}Autor:${RESET} Cristian Alves Silva"
echo -e "${BLUE}${BOLD}⠀⢠⣯⡾⢿⣿⣿⡿⣿⣿⣿⣆⣠⣶⣿⣿⣷⣄⣰⣿⣿⣿⣿⣿⣿⣿⢷⣽⣄⠀${RESET}    "
echo -e "${BLUE}${BOLD}⢠⣿⢋⠴⠋⣽⠋⡸⢱⣯⡿⣿⠏⣡⣿⣽⡏⠹⣿⣿⣿⡎⢣⠙⢿⡙⠳⡙⢿⠄${RESET}    ${CYAN}${BOLD}Orientador:${RESET} Claiton Luis Soares"
echo -e "${BLUE}${BOLD}⣰⢣⣃⠀⠊⠀⠀⠁⠘⠏⠁⠁⠸⣶⣿⡿⢿⡄⠈⠀⠁⠃⠈⠂⠀⠑⠠⣈⡈⣧${RESET}    "
echo -e "${BLUE}${BOLD}⡏⡘⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡥⢄⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢳⢸${RESET}    ${CYAN}${BOLD}Instituição:${RESET} Instituto Federal do Triângulo Mineiro"
echo -e "${BLUE}${BOLD}⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣄⣸⠟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢨${RESET}    "
echo -e "${BLUE}${BOLD}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡴⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈${RESET}    ${CYAN}${BOLD}Curso:${RESET} Tecnólogo em Análise e Desenvolvimento de Sistemas"
echo -e "${BLUE}${BOLD}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡳⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀${RESET}    "

while true; do
    menu
done

