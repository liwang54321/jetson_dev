ARG ubuntu_version=20.04
FROM ubuntu:${ubuntu_version}

ARG user_name=lw

ARG jetson_sdk=Jetson_Linux_R35.4.1_aarch64.tbz2
ARG jetson_rootfs=Tegra_Linux_Sample-Root-Filesystem_R35.4.1_aarch64.tbz2

ENV TIME_ZONE Asia/Shanghai
ENV LANG C.UTF-8

# update source
RUN  apt update && apt install --no-install-recommends --reinstall ca-certificates -y
COPY --chown=root:root ./files/sources.list.20.04  /etc/apt/sources.list
RUN apt clean && apt update && apt upgrade -y

# timezone
RUN apt-get install -y tzdata \
    && ln -snf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime && echo $TIME_ZONE > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata

# install apps
RUN apt install -y --no-install-recommends \
                python3-pip \
                python3-dev \
                python-is-python3 \
                fish \
                rsync \
                git \
                tig \
                lrzsz \
                openssh-server \
                build-essential \
                qemu-user-static \
                zip \
                unzip \
                nfs-kernel-server \
                ncurses-dev \
                libtool \
                libssl-dev \
                autoconf \
                automake \
                bison \
                device-tree-compiler \
                tftp-hpa \
                tftpd-hpa \
                tmux \
                htop \
                libusb-1.0-0-dev \
                neovim \
                wget \
                tree \
                curl \
                silversearcher-ag \
                pkg-config \
                ninja-build \
                gettext\
                libncurses5-dev \
                mtools \
                bc \
                ctags \
                sudo \
                gnutls-bin \
                apt-transport-https \
                usbutils \
                iputils-ping \
                net-tools \
                iproute2 \
                pigz \
                minicom \
                sshpass \
                cpio \
                flex \
                xxd \
                kmod \
                gnupg2


# User
RUN useradd -d "/home/${user_name}" -m \
            -G "sudo,video,audio,adm,dialout,docker" \
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
ARG cmake_version=3.27.4
RUN wget -N https://github.com/Kitware/CMake/releases/download/v${cmake_version}/cmake-${cmake_version}.tar.gz
RUN tar -xzf cmake-${cmake_version}.tar.gz -C .\
    && cd cmake-${cmake_version} \
    && ./bootstrap --parallel=$(nproc) \
    && make -j$(nproc) \
    && sudo make install \
    && cd .. \
    && rm cmake* -rf

# space vim
RUN curl -sLf https://spacevim.org/install.sh | bash

# for fish
RUN curl https://gitee.com/mirrors/oh-my-fish/raw/master/bin/install | fish

# python
RUN pip3 config set global.index-url https://mirrors.aliyun.com/pypi/simple/ \
    && sudo pip3 config set global.index-url https://mirrors.aliyun.com/pypi/simple/ \
    && sudo pip3 install --upgrade conan \
    && conan profile detect --force

# Install JetPack
RUN sudo apt-key adv --fetch-key http://repo.download.nvidia.com/jetson/jetson-ota-public.asc
RUN sudo sh -c 'echo "\ndeb http://repo.download.nvidia.com/jetson/x86_64/focal r35.4 main" >> /etc/apt/sources.list'

RUN sudo apt update && \
    sudo apt-get install cuda-cross-aarch64-11-4 cuda-cupti-cross-aarch64-11-4 \
        cuda-sanitizer-11-4 cuda-toolkit-11-4 libnvvpi2 nsight-compute-2022.2.1 \
        nsight-compute-addon-l4t-2022.2.1 nsight-graphics-for-embeddedlinux-2023.2.0.0 \
        nsight-systems-2023.2.4 nvsci python3.8-vpi2 vpi2-demos vpi2-cross-aarch64-l4t vpi2-dev vpi2-samples -y

# COPY SDK
COPY --chown=${user_name}:${user_name} files/l4t_flash_prerequisites.sh /tmp/

# Install SDK
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