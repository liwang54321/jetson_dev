ARG ubuntu_version=22.04
FROM ubuntu:${ubuntu_version}

ARG ubuntu_version=22.04
ARG user_name=lw

ENV DEBIAN_FRONTEND noninteractive
ENV TIME_ZONE Asia/Shanghai
ENV LANG C.UTF-8

# update source
RUN apt update && \
    apt install -y --no-install-recommends --reinstall ca-certificates && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --chown=root:root ./files/sources.list.${ubuntu_version}  /etc/apt/sources.list

# timezone
RUN apt clean && apt update && apt upgrade -y && \
    apt-get install -y tzdata && \
    ln -snf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime && \
    echo $TIME_ZONE > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# install apps
RUN apt update && apt upgrade -y && \
    apt install -y --no-install-recommends \
                python3-pip python3-dev python-is-python3 \
                fish sudo \
                rsync lrzsz tmux tio xxd \
                git tig neovim \
                sshpass openssh-server nfs-kernel-server \
                build-essential qemu-user-static ninja-build \
                zip unzip pigz \
                libtool libssl-dev libusb-1.0-0-dev usbutils libncurses5-dev ncurses-dev \
                autoconf automake bison device-tree-compiler \
                tftp-hpa tftpd-hpa \
                htop tree wget curl \
                silversearcher-ag \
                gnutls-bin pkg-config gettext mtools bc cpio flex \
                apt-transport-https \
                iputils-ping net-tools iproute2 \
                kmod gnupg2 && \
                apt-get autoremove -y && \
                apt-get clean && \
                rm -rf /var/lib/apt/lists/*

# User
RUN useradd -d "/home/${user_name}" -m \
            -G "sudo,video,audio,adm,dialout" \
            -s "/bin/fish" \
            --no-log-init \
            -p ${user_name} \
            ${user_name}
            
RUN echo "${user_name} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

WORKDIR /home/${user_name}
USER ${user_name}

# git
RUN git config --global user.name ${user_name} \
    && git config --global user.email "liwang54321@gmail.com" \
    && git config --global core.editor vim \
    && git config --global http.sslVerify false \
    && git config --global http.postBuffer 1048576000 

# cmake
RUN sudo apt update && \
    sudo apt-get install -y --no-install-recommends dialog && \
    curl https://apt.kitware.com/kitware-archive.sh | sudo bash && \
    sudo apt update && \
    sudo apt install cmake \
    cmake --version && \
    sudo apt-get autoremove -y && \
    sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/*

# space vim
RUN curl -sLf https://spacevim.org/install.sh | bash

# for fish
SHELL ["/bin/fish", "-c"]
RUN curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install -o /tmp/install && \
    fish /tmp/install --noninteractive && rm /tmp/install

# python
RUN pip3 config set global.index-url https://mirrors.aliyun.com/pypi/simple/ \
    && sudo pip3 config set global.index-url https://mirrors.aliyun.com/pypi/simple/ \
    && sudo pip3 install --upgrade conan \
    && conan profile detect --force

# Jetson Specific Packages
RUN sudo apt update && \
    sudo apt install -y --no-install-recommends \ 
    whiptail && \
    sudo apt-get autoremove -y && \
    sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/*
    
RUN sudo apt-key adv --fetch-keys https://repo.download.nvidia.com/jetson/jetson-ota-public.asc && \
    echo "deb https://repo.download.nvidia.com/jetson/x86_64/jammy r36.4 main" | sudo tee -a /etc/apt/sources.list.d/nvidia-l4t-apt-source.list && \
    sudo apt update && \
    sudo apt-get install -y --no-install-recommends cuda-toolkit-12-6 cuda-cross-aarch64-12-6 \
        nvsci libnvvpi3 vpi3-dev vpi3-cross-aarch64-l4t python3.10-vpi3 \
        vpi3-samples vpi3-python-src \
        nsight-systems-2024.5.4 nsight-graphics-for-embeddedlinux-2024.2.0.0 && \
        sudo apt-get autoremove -y && \
        sudo apt-get clean && \
        sudo rm -rf /var/lib/apt/lists/*


# COPY SDK
COPY --chown=${user_name}:${user_name} files/l4t_flash_prerequisites.sh /tmp/

# Install SDK
SHELL ["/bin/bash", "-c"]
ARG sdk_path=/l4t
RUN sudo mkdir ${sdk_path} && sudo chown ${user_name}:${user_name} ${sdk_path} -R
RUN sudo sh -c "/tmp/l4t_flash_prerequisites.sh"

# clean 
RUN sudo rm /tmp/* -rf && \
    sudo apt autoremove -y && \
    sudo apt clean

WORKDIR ${sdk_path}
# ENTRYPOINT ["/bin/fish"]
CMD /bin/fish
