#!/bin/bash
instalar(){
apt install net-tools
}
listar(){
ifconfig -a
route
cat /etc/resolv.conf
}
parar(){
ifconfig
echo “Digite a interface”
read interface
ifconfig $interface down
}
iniciar(){
ifconfig
echo “Digite a interface”
read interface
ifconfig $interface up
}
novoip(){
listar
echo "Digite o IP"
read ip
echo "Digite o Gateway"
read gateway
echo "Digite a Máscara"
read mascara
echo "Digite DNS1"
read DNS1
echo "Digite DNS2"
read DNS2
echo "Digite a interface"
read interface
ifconfig $interface down
ifconfig $interface $ip netmask $mascara up
route add default gw $gateway $interface
echo "
nameserver $DNS1
nameserver $DNS2
" > /etc/resolv.conf 
}
case "$1" in
"install") instalar;;
"list") listar;;
"stop") parar;;
"up") iniciar;;
"newip") novoip;;
*)echo "Use os parâmetros install, list, stop, up ou newIp"
esac













