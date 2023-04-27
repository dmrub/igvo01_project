ARG BASE_IMAGE=tensorflow/tensorflow:2.9.1-gpu

FROM $BASE_IMAGE

LABEL org.opencontainers.image.authors="Dmitri Rubinstein"
LABEL org.opencontainers.image.source="https://github.com/dmrub/igvo01_project"

COPY requirements.txt /etc/

# Workaround
# https://github.com/NVIDIA/nvidia-docker/issues/1632#issuecomment-1135513277
RUN set -ex; \
    apt-key del 7fa2af80; \
    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/3bf863cc.pub; \
    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu2004/x86_64/7fa2af80.pub;

RUN set -ex; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        vim ffmpeg libsm6 libxext6; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    python3 -m pip install --upgrade pip; \
    python3 -m pip install -r /etc/requirements.txt;

ENV OPENSSH_PORT=22 \
    OPENSSH_ROOT_PASSWORD="" \
    OPENSSH_ROOT_AUTHORIZED_KEYS="" \
    OPENSSH_USER="ssh" \
    OPENSSH_USERID=1001 \
    OPENSSH_GROUP="ssh" \
    OPENSSH_GROUPID=1001 \
    OPENSSH_PASSWORD="" \
    OPENSSH_AUTHORIZED_KEYS="" \
    OPENSSH_HOME="/home/ssh" \
    OPENSSH_SHELL="/bin/bash" \
    OPENSSH_RUN="" \
    OPENSSH_ALLOW_TCP_FORWARDING="all"

RUN set -ex; \
    if ! command -v gpg > /dev/null; then \
        export DEBIAN_FRONTEND=noninteractive; \
        apt-get update; \
        apt-get install -y --no-install-recommends \
            gnupg \
            dirmngr \
        ; \
        rm -rf /var/lib/apt/lists/*; \
    fi

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      openssh-server rsync augeas-tools; \
    chmod +x /usr/local/bin/entrypoint.sh; \
    rm -f /etc/motd; \
    passwd -d root; \
    mkdir -p ~root/.ssh /etc/authorized_keys; \
    printf 'set /files/etc/ssh/sshd_config/AuthorizedKeysFile ".ssh/authorized_keys /etc/authorized_keys/%%u"\n'\
'set /files/etc/ssh/sshd_config/ClientAliveInterval 30\n'\
'set /files/etc/ssh/sshd_config/ClientAliveCountMax 5\n'\
'set /files/etc/ssh/sshd_config/PermitRootLogin yes\n'\
'set /files/etc/ssh/sshd_config/PasswordAuthentication yes\n'\
'set /files/etc/ssh/sshd_config/Port 22\n'\
'set /files/etc/ssh/sshd_config/AllowTcpForwarding no\n'\
'set /files/etc/ssh/sshd_config/Match[1]/Condition/Group "wheel"\n'\
'set /files/etc/ssh/sshd_config/Match[1]/Settings/AllowTcpForwarding yes\n'\
'save\n'\
'quit\n' | augtool; \
    cp -a /etc/ssh /etc/ssh.cache; \
    apt-get remove -y augeas-tools; \
    rm -rf /var/lib/apt/lists/*;

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
