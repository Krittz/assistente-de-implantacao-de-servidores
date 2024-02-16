#!/bin/bash
instalar(){
apt --fix-broken install
apt-get update
apt install apache2 -y 
cd /var/www
chmod 777 html
}

desinstalar(){
apt autoremove apache2 -y
}
iniciar(){
/etc/init.d/apache2 start
}
parar(){
/etc/init.d/apache2 stop
}

case "$1" in
"install") instalar ;;
"desinstall") desinstalar ;; 
"start") iniciar ;;
"stop") parar ;;
*) echo "Use os parâmetro start, stop, install ou desinstall"
esac
