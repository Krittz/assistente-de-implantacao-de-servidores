# Shell Script para Gerenciamento de Servidores em Docker

## Descrição

Este script foi desenvolvido para facilitar a criação e gerenciamento de containers Docker em sistemas Linux, para servidores web como, Apache e NGINX, servidores SFTP como, VSFTPD e bancos de dados MySQL, MariaDB e PostgreSQL.
Ele inclui funções para criar containers, realizar backups e restaurar bancos de dados.

## Funcionalidades

- **Verificação de Instalação do Docker**: Certifica-se de que o Docker está instalado antes de continuar.
- **Criação de Containers para Servidores Web**: Cria e configura containers para aplicações, front-end e para proxy reverso, utilizando servidores Apache e NGINX.
- **Criação de Containers para Servidores SFTP**: Cria e configura containers para servidores de transferência segura de arquivos, tanto o VSFTPD e o OpenSSH.
- **Criação de Containers para Bancos de Dados**: Cria e configura containers para MySQL, PostgreSQL e MariaDB, deixando-os pronto para uso.
- **Backup de Bancos de Dados**: Realiza backups de bancos de dados MySQL, PostgreSQL e MariaDB.
- **Restauração de Bancos de Dados**: Restaura bancos de dados MySQL, PostgreSQL e MariaDB a partir de arquivos de backup, criando novos containers ou reaproveitando antigos.

## Pré-requisitos

- Acesso à linha de comando.

## Uso

### 1. Clonar o Repositório

```bash
git clone https://github.com/seu-usuario/seu-repositorio.git
cd seu-repositorio
sudo ./script.sh
