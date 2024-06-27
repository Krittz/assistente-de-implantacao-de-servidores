FROM debian:latest
RUN apt-get update     && DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server     && mkdir /var/run/sshd     && useradd -m cristian     && echo "cristian:calangos" | chpasswd     && chown root:root /home/cristian     && chmod 755 /home/cristian     && mkdir /home/cristian/upload     && chown cristian:cristian /home/cristian/upload     && echo "Subsystem sftp internal-sftp" >> /etc/ssh/sshd_config

COPY configs/sshd_config /etc/ssh/sshd_config
VOLUME /home/cristian
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
