#!/bin/bash
chmod u=rwx,g=rwx,o=rwx alterando_nome.sh
SCRIPT=$(basename "$0")

HOSTNAME=/etc/hostname
HOSTS=/etc/hosts
KERNEL=/proc/sys/kernel/hostname

OLDNAME=$(hostname)

if [ $UID -ne 0 ]; then
 echo "$SCRIPT: requer privilégios de root." 1>&2
 exit 1

elif [ ! $1 ]; then
 echo "Uso: 'sudo $0 nome'" 1>&2
 exit 1
fi

if echo "$1" | tee $HOSTNAME $KERNEL 1>/dev/null && sed -i "s/\b$OLDNAME\b/$1/g" $HOSTS; then
 echo $SCRIPT': nome alterado com sucesso !!!'
else
 echo "$SCRIPT: erro ao tentar alterar nome." 1>&2
 exit 1
fi

exit 0

