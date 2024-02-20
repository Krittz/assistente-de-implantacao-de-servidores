#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
	echo "Por favor, execute este script como root"
	exit 1
fi

echo "|=================================================|"
echo "|			MENU PRINCIPAL			|"
echo "|=================================================|"
echo "|							|"
echo "|	[1] - Docker					|"
echo "|	[2] - SSH					|"
echo "| [3] - Samba					|"
echo "| [4] - VSFTPD					|"
echo "|_________________________________________________|"
