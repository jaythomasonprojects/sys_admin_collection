FROM docker.io/geerlingguy/docker-ubuntu2204-ansible:latest

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends openssh-server \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /run/sshd /etc/ssh/ssh_config.d /etc/ssh/sshd_config.d
