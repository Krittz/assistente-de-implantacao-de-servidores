# Usar a imagem Debian como base
FROM debian:latest

# Instalar OpenSSH Server e outras dependências necessárias
RUN apt-get update     && DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server     && mkdir /var/run/sshd     && useradd -m cristian     && echo "cristian:calangos" | chpasswd     && chown root:root /home/cristian     && chmod 755 /home/cristian     && mkdir /home/cristian/upload     && chown cristian:cristian /home/cristian/upload     && echo "Subsystem sftp internal-sftp" >> /etc/ssh/sshd_config

# Copiar o arquivo de configuração sshd_config para o container
COPY configs/sshd_config /etc/ssh/sshd_config

# Criar um volume para o diretório de usuários SFTP
VOLUME /home/cristian

# Expor a porta 22 para conexões SSH/SFTP
EXPOSE 22

# Comando para iniciar o OpenSSH Server
CMD ["/usr/sbin/sshd", "-D"]
