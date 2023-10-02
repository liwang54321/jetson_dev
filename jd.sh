#!/bin/bash
source ./scripts/bash_log.sh
set -e
export DOCKER_VERSION=35.4.1
export SDK_VARIABLE_F="./.sdk_variable.env"

function set_variable() {
    local sdk_home=$1
    export BOARD=jetson-xavier-nx-devkit
    export SDK_VERSION=r35_release_v4.1
    export L4T_RELEASE_PACKAGE=jetson_linux_r35.4.1_aarch64.tbz2
    export SAMPLE_FS_PACKAGE=tegra_linux_sample-root-filesystem_r35.4.1_aarch64.tbz2
    export JETSON_KERNEL_VERSION=5.10.120-rt70-tegra
    export JETSON_STORAGE_TYPE="nvme0n1p1"

    export JETSON_SDK_PATH="${sdk_home}"
    export JETSON_SDK_HOME="${JETSON_SDK_PATH}/Linux_for_Tegra"
    export JETSON_TOOLCHAIN="${JETSON_SDK_PATH}/toolchain"
    export JETSON_PACKAGE_PATH="${JETSON_SDK_PATH}/packages"
    export JETSON_ROOTFS="${JETSON_SDK_HOME}/rootfs"
    export JETSON_ROOTFS_DEV="${JETSON_ROOTFS}_dev"
    export JETSON_PUBLIC_PACKAGE="${JETSON_SDK_HOME}/source/public"
    export JETSON_PUBLIC_SOURCE="${JETSON_SDK_HOME}/sources"
    export JETSON_KERNEL="${JETSON_PUBLIC_SOURCE}/kernels"
    export JETSON_DISPLAY_MODULE="${JETSON_PUBLIC_SOURCE}/NVIDIA-kernel-module-source-TempVersion"
    export JETSON_KERNEL_OUT="${JETSON_SDK_PATH}/build/kernel_out"

    export CROSS_COMPILE_AARCH64_PATH="${JETSON_SDK_PATH}/toolchain"
    export CROSS_COMPILE_AARCH64="${CROSS_COMPILE_AARCH64_PATH}/bin/aarch64-buildroot-linux-gnu-"
    export CROSS_COMPILE="${CROSS_COMPILE_AARCH64}"

    export LOCALVERSION="-tegra"
    export IGNORE_PREEMPT_RT_PRESENCE=1

    export BOARDID=3668
    export BOARDSKU=0000
    export FAB=100
    export tegra194
    export USER_NAME=lw
    export PASSWD=lw
    # TegraID Xavier 0x19 Orin 0x23
}

function save_variable() {
    cat >${SDK_VARIABLE_F} <<EOF
export SDK_VERSION=${SDK_VERSION}
export L4T_RELEASE_PACKAGE=${L4T_RELEASE_PACKAGE}
export SAMPLE_FS_PACKAGE=${SAMPLE_FS_PACKAGE}
export JETSON_KERNEL_VERSION=${JETSON_KERNEL_VERSION}
export JETSON_STORAGE_TYPE=${JETSON_STORAGE_TYPE}
export JETSON_SDK_PATH=${JETSON_SDK_PATH}
export JETSON_SDK_HOME=${JETSON_SDK_HOME}
export JETSON_TOOLCHAIN=${JETSON_TOOLCHAIN}
export JETSON_PACKAGE_PATH=${JETSON_PACKAGE_PATH}
export JETSON_ROOTFS=${JETSON_ROOTFS}
export JETSON_ROOTFS_DEV=${JETSON_ROOTFS_DEV}
export JETSON_PUBLIC_PACKAGE=${JETSON_PUBLIC_PACKAGE}
export JETSON_PUBLIC_SOURCE=${JETSON_PUBLIC_SOURCE}
export JETSON_KERNEL=${JETSON_KERNEL}
export JETSON_DISPLAY_MODULE=${JETSON_DISPLAY_MODULE}
export JETSON_KERNEL_OUT=${JETSON_KERNEL_OUT}
export CROSS_COMPILE_AARCH64_PATH=${CROSS_COMPILE_AARCH64_PATH}
export CROSS_COMPILE_AARCH64=${CROSS_COMPILE_AARCH64}
export CROSS_COMPILE=${CROSS_COMPILE}
export LOCALVERSION=${LOCALVERSION}
export IGNORE_PREEMPT_RT_PRESENCE=${IGNORE_PREEMPT_RT_PRESENCE}

export BOARD=${BOARD}
export BOARDID=${BOARDID}
export BOARDSKU=${BOARDSKU}
export FAB=${FAB}
export tegra194
export USER_NAME=${USER_NAME}
export PASSWD=${PASSWD}
EOF
}

function __remove_static_libs() {
    info "Start Remove Static Libs"
    pushd ${JETSON_ROOTFS} >/dev/null 2>&1
    sudo find -name lib*.a | xargs sudo rm
    popd >/dev/null
}

function __strip_rootfs() {
    pushd ${JETSON_ROOTFS} >/dev/null 2>&1
    sudo find -name "lib*.so" | xargs sudo ${CROSS_COMPILE_AARCH64}strip
    sudo find -name "lib*.so.*" | xargs sudo ${CROSS_COMPILE_AARCH64}strip
    sudo find -type f -executable -exec file {} \; | grep "ELF" | cut -d: -f1 | xargs sudo ${CROSS_COMPILE_AARCH64}strip
    popd >/dev/null
}

function __remove_include_file() {
    info "Start Remove Rootfs Include File"
    pushd ${JETSON_ROOTFS} >/dev/null 2>&1
    sudo find -name *.h | xargs sudo rm
    popd >/dev/null
}

function __gen_basic_rootfs() {
    pushd ${JETSON_SDK_HOME}/tools/samplefs >/dev/null 2>&1
    sudo bash -x ./nv_build_samplefs.sh --abi aarch64 --distro ubuntu --flavor basic --version focal
    [ $? != 0 ] && error "Build Basic Rootfs Failed" && exit -1
    popd >/dev/null 2>&1
}

function __copy_custom_rootfs_layer() {
    sudo cp -arfd ${JETSON_SDK_PATH}/custom_layer/Linux_for_Tegra/rootfs/* "${JETSON_ROOTFS}"
}

function __modules_dep() {
    sudo cp "${JETSON_KERNEL_OUT}/System.map" "${JETSON_ROOTFS}"
    sudo install --owner=root --group=root "/usr/bin/qemu-aarch64-static" "${JETSON_ROOTFS}/usr/bin/"
    pushd ${JETSON_ROOTFS} >/dev/null 2>&1
    LC_ALL=C sudo chroot . depmod -a -F System.map ${JETSON_KERNEL_VERSION}
    popd >/dev/null
    sudo rm ${JETSON_ROOTFS}/System.map -rf
    sudo rm -f "${JETSON_ROOTFS}/usr/bin/qemu-aarch64-static"
}

function __gen_rootfs_version() {
    sudo install --owner=root --group=root "/usr/bin/qemu-aarch64-static" "${JETSON_ROOTFS}/usr/bin/"
    pushd ${JETSON_ROOTFS} >/dev/null 2>&1
    LC_ALL=C sudo chroot . dpkg -l > rootfs_version.txt
    popd >/dev/null
    sudo rm -f "${JETSON_ROOTFS}/usr/bin/qemu-aarch64-static"
}

function __kernel_config() {
    local kernel_config_tool=${JETSON_KERNEL}/kernel/kernel-5.10/scripts/config
    local kernel_defconfig_file=${JETSON_KERNEL}/kernel/kernel-5.10/arch/arm64/configs/tegra_defconfig
    enable_config_items=(

    )
    module_config_items=(
        "CONFIG_FUSE_FS"
        "CONFIG_VFAT_FS"
        "CONFIG_NTFS_FS"
    )
    disable_config_items=(
        "CONFIG_SND_SOC_TEGRA_ALT"
        "CONFIG_SND_SOC_TEGRA_ALT_FORCE_CARD_REG"
        "CONFIG_SND_SOC_TEGRA_T186REF_ALT"
        "CONFIG_SND_SOC_TEGRA_T186REF_MOBILE_ALT"
    )

    for item in "${enable_config_items[@]}"; do
        ${kernel_config_tool} --file "${kernel_defconfig_file}" --enable ${item}
    done

    for item in "${module_config_items[@]}"; do
        ${kernel_config_tool} --file "${kernel_defconfig_file}" --module ${item}
    done

    for item in "${disable_config_items[@]}"; do
        ${kernel_config_tool} --file "${kernel_defconfig_file}" --disable ${item}
    done

}

function __install_jetpack() {
    local is_dev=${1} # "yes" or "no"
    [ ${is_dev} == "yes" ] && info "Start Build Dev Rootfs"

    info "Start Build Rootfs ${JETSON_ROOTFS}"

    pushd "${JETSON_ROOTFS}" >/dev/null 2>&1
    sudo cp /usr/bin/qemu-aarch64-static "${JETSON_ROOTFS}/usr/bin/qemu-aarch64-static" -ardf
    sudo chmod 755 "${JETSON_ROOTFS}/usr/bin/qemu-aarch64-static"

    sudo mount /sys ./sys -o bind
    sudo mount /proc ./proc -o bind
    sudo mount /dev ./dev -o bind
    sudo mount /dev/pts ./dev/pts -o bind

    if [ -s etc/resolv.conf ]; then
        sudo mv etc/resolv.conf etc/resolv.conf.saved
    fi
    if [ -e "/run/resolvconf/resolv.conf" ]; then
        sudo cp /run/resolvconf/resolv.conf etc/
    elif [ -e "/etc/resolv.conf" ]; then
        sudo cp /etc/resolv.conf etc/
    fi

    info "Start Install Nvidia Key"
    sudo LC_ALL=C chroot . apt update && : || :
    sudo LC_ALL=C chroot . apt install --no-install-recommends -y gnupg2
    sudo LC_ALL=C chroot . apt-key adv --fetch-key https://repo.download.nvidia.com/jetson/jetson-ota-public.asc

    info "Start Install JetPack Runtime"
    sudo LC_ALL=C chroot . apt update
    # local jetpack_pkgs=nvidia-jetpack-runtime # NOTE: Remove nvidia-opencv
    local jetpack_pkgs="nvidia-l4t-jetson-multimedia-api nvidia-cuda nvidia-tensorrt nvidia-cudnn8 nvidia-cupva nvidia-container nvidia-vpi "
    if [ ${is_dev} == "yes" ]; then
        # jetpack_pkgs=nvidia-jetpack
        jetpack_pkgs+="nvidia-tensorrt-dev nvidia-cuda-dev nvidia-vpi-dev nvidia-cudnn8-dev" # FIXME: add nvidia-nsight-sys to jetpack_pkgs
    fi

    sudo LC_ALL=C chroot . apt install --no-install-recommends -y \
        ${jetpack_pkgs} \
        network-manager \
        tree \
        bc \
        wireless-tools \
        iw

    # Install Debug Tools
    sudo LC_ALL=C chroot . apt install --no-install-recommends -y \
        neovim \
        lrzsz \
        htop \
        i2c-tools \
        v4l-utils \
        lsof \
        file

    if [ ${is_dev} == "yes" ]; then
        sudo LC_ALL=C chroot . apt install --no-install-recommends -y \
            python3-pip
    fi

    # sudo LC_ALL=C chroot . pip3 install -U jetson-stats
    sudo LC_ALL=C chroot . chown ${USER_NAME}:${USER_NAME} /home/${USER_NAME} -R
    sudo LC_ALL=C chroot . usermod -aG docker ${USER_NAME}
    sudo LC_ALL=C chroot . usermod -aG gpio ${USER_NAME}
    sudo LC_ALL=C chroot . usermod -aG dialout ${USER_NAME}
    sudo LC_ALL=C chroot . usermod -aG trusty ${USER_NAME}
    sudo LC_ALL=C chroot . usermod -aG crypto ${USER_NAME}

    info "Start Update Apt"
    sudo LC_ALL=C chroot . apt update

    # sudo LC_ALL=C chroot . /bin/bash

    info "Start Remote Packages"
    sudo LC_ALL=C chroot . apt remove -y --purge \
        nvidia-l4t-kernel

    if [ ${is_dev} != "yes" ]; then
        sudo LC_ALL=C chroot . apt remove -y --purge \
            nvidia-l4t-vulkan-sc-samples \
            nvidia-l4t-vulkan-sc-dev
    fi

    # sudo LC_ALL=C chroot . sudo apt-mark manual \
    #     cuda-cccl-11-4 \
    #     cuda-cudart-dev-11-4 \
    #     cuda-driver-dev-11-4 \
    #     nvidia-l4t-camera \
    #     nvidia-l4t-cuda \
    #     nvidia-l4t-multimedia \
    #     nvidia-l4t-multimedia-utils

    # sudo LC_ALL=C chroot . apt remove --purge -y \
    #     libc6-dev \
    #     libcrypt-dev \
    #     libc-dev-bin \
    #     linux-libc-dev \
    #     libegl-dev \
    #     libgl-dev \
    #     nvidia-l4t-jetson-multimedia-api \
    #     xserver-xorg-input-wacom \
    #     xbitmaps

    info "Start Auto Remove"
    sudo LC_ALL=C chroot . apt autoremove -y

    sudo LC_ALL=C chroot . sync
    sudo LC_ALL=C chroot . apt-get clean
    sudo LC_ALL=C chroot . sync

    if [ -s etc/resolv.conf.saved ]; then
        sudo mv etc/resolv.conf.saved etc/resolv.conf
    fi

    sudo umount ./sys
    sudo umount ./proc
    sudo umount ./dev/pts
    sudo umount ./dev

    sudo rm "${JETSON_ROOTFS}/usr/bin/qemu-aarch64-static"

    sudo rm -rf var/lib/apt/lists/*
    sudo rm -rf dev/*
    sudo rm -rf var/log/*
    sudo rm -rf var/cache/apt/archives/*.deb
    sudo rm -rf var/tmp/*
    sudo rm -rf tmp/*
    popd >/dev/null
}

function __check_errors() {
    # Check Mount Error
    mountpoint -q ${JETSON_ROOTFS}/sys && sudo umount ${JETSON_ROOTFS}/sys || :
    mountpoint -q ${JETSON_ROOTFS}/proc && sudo umount ${JETSON_ROOTFS}/proc || :
    mountpoint -q ${JETSON_ROOTFS}/dev/pts && sudo umount ${JETSON_ROOTFS}/dev/pts || :
    mountpoint -q ${JETSON_ROOTFS}/dev && sudo umount ${JETSON_ROOTFS}/dev || :
}

function __build_rootfs_impl() {
    local is_custom=${1} # "yes" or "no"
    local is_dev=${2}    # "yes" or "no"

    info "Start Clean Rootfs Dir"
    [ ! -d "${JETSON_ROOTFS}" ] && mkdir -p "${JETSON_ROOTFS}"
    [ ! -z "$(ls -A ${JETSON_ROOTFS})" ] && sudo rm -rf ${JETSON_ROOTFS}/*

    info "Start Install Rootfs"
    if [ ${is_custom} = "yes" ]; then
        local custom_rootfs=${JETSON_SDK_HOME}/tools/samplefs/sample_fs.tbz2
        [ ! -e ${custom_rootfs} ] && __gen_basic_rootfs && [ $? != 0 ] && exit -1

        sudo tar -xjf ${custom_rootfs} -C ${JETSON_ROOTFS}
    else
        info "Start Download Jetson Rootfs"
        local rootfs_tgz=${JETSON_PACKAGE_PATH}/${SAMPLE_FS_PACKAGE}
        [ -d "${JETSON_PACKAGE_PATH}" ] || mkdir -p ${JETSON_PACKAGE_PATH}
        [ -f "${rootfs_tgz}" ] ||
            wget -P ${JETSON_PACKAGE_PATH} -N https://developer.nvidia.com/downloads/embedded/l4t/${SDK_VERSION}/release/${SAMPLE_FS_PACKAGE}

        info "Start Install Jetson Rootfs"
        pushd "${JETSON_ROOTFS}" >/dev/null 2>&1
        [ ! -e "${JETSON_ROOTFS}/bin" ] && sudo tar -xpf ${rootfs_tgz}
        export LDK_ROOTFS_DIR=$PWD
        popd >/dev/null 2>&1
    fi

    # info "Start Setup Rootfs Env"
    __setup_dev_env

    # info "Start Create User"
    __create_user

    info "Start Install Custom Layer"
    __copy_custom_rootfs_layer

    info "Start Install Jetpack"
    __install_jetpack ${is_dev}

    info "Start Install Kernel"
    install_kernel

    info "Start Modules Dep"
    __modules_dep

    info "Start Strip Rootfs"
    [ ${is_dev} != "yes" ] && __strip_rootfs || :
    [ ${is_dev} != "yes" ] && __remove_include_file || :
    [ ${is_dev} != "yes" ] && __remove_static_libs || :

}

function build_rootfs() {
    local is_custom=${1} # "yes" or "no"
    local need_dev=${2}  # "yes" or "no"

    __check_errors

    if [ ${is_custom} == "yes" ]; then
        __build_rootfs_impl "${is_custom}" "yes"
        [ -d ${JETSON_ROOTFS_DEV} ] && sudo rm -rf ${JETSON_ROOTFS_DEV}
        __gen_rootfs_version
        sudo mv ${JETSON_ROOTFS} ${JETSON_ROOTFS_DEV}
        info "Rootfs Dev Genrate Done"
    fi

    __build_rootfs_impl "${is_custom}" "no"
    __gen_rootfs_version
    info "Rootfs Genrate Done"
}

function build_public_src() {
    # Build Public Src
    pushd ${JETSON_PUBLIC_PACKAGE} >/dev/null 2>&1
    CROSS_COMPILE_AARCH64=${CROSS_COMPILE_AARCH64} \
        CROSS_COMPILE_AARCH64_PATH=${CROSS_COMPILE_AARCH64_PATH} \
        NV_TARGET_BOARD=t186ref \
        ./nv_public_src_build.sh
    popd >/dev/null

    # Build OPTEE
    pushd ${JETSON_PUBLIC_PACKAGE} >/dev/null 2>&1
    tar -I lbzip2 -xf nvidia-jetson-optee-source.tbz2

    # Xavier
    CROSS_COMPILE_AARCH64=${CROSS_COMPILE_AARCH64} \
        CROSS_COMPILE_AARCH64_PATH=${CROSS_COMPILE_AARCH64_PATH} \
        PYTHON3_PATH="/usr/local/bin/python3" \
        UEFI_STMM_PATH=${JETSON_SDK_HOME}/bootloader/standalonemm_optee_t194.bin \
        ./optee_src_build.sh -p t194

    # Orin
    # CROSS_COMPILE_AARCH64=${CROSS_COMPILE_AARCH64} \
    # CROSS_COMPILE_AARCH64_PATH=${CROSS_COMPILE_AARCH64_PATH} \
    # PYTHON3_PATH="/usr/local/bin/python3" \
    # UEFI_STMM_PATH=/Linux_for_Tegra/bootloader/standalonemm_optee_t234.bin \
    # ./optee_src_build.sh -p t234

    popd >/dev/null
}

function build_uefi() {
    echo ""
}

function install_sdk() {
    [ $# != 1 ] && error "Error: Input Install Path" && exit -1
    set_variable $1
    [ -e ${SDK_VARIABLE_F} ] && save_variable && info "SDK Variable Update Success" && exit 0
    save_variable

    info "Start Download ToolChain"
    [ -d "${JETSON_PACKAGE_PATH}" ] || mkdir -p ${JETSON_PACKAGE_PATH}
    local toolchain_tgz=${JETSON_PACKAGE_PATH}/aarch64--glibc--stable-final.tar.gz
    [ -f "${toolchain_tgz}" ] ||
        wget -O ${toolchain_tgz} -N https://developer.nvidia.com/embedded/jetson-linux/bootlin-toolchain-gcc-93

    info "Start Download Jetson SDK"
    local sdk_tgz=${JETSON_PACKAGE_PATH}/${L4T_RELEASE_PACKAGE}
    [ -f "${sdk_tgz}" ] ||
        wget -P ${JETSON_PACKAGE_PATH} -N https://developer.nvidia.com/downloads/embedded/l4t/${SDK_VERSION}/release/${L4T_RELEASE_PACKAGE}

    info "Start Download Jetson Kernel Source"
    [ -f "${JETSON_PACKAGE_PATH}/public_sources.tbz2" ] ||
        wget -N -P ${JETSON_PACKAGE_PATH} https://developer.nvidia.com/downloads/embedded/l4t/${SDK_VERSION}/sources/public_sources.tbz2

    info "Start Install ToolChain"
    [ ! -d "${JETSON_TOOLCHAIN}" ] && mkdir -p "${JETSON_TOOLCHAIN}" && tar -xzf "${toolchain_tgz}" -C "${JETSON_TOOLCHAIN}"

    info "Start Install Jetson SDK"
    [ ! -e "${JETSON_SDK_HOME}" ] && tar -xjf "${sdk_tgz}" -C "${JETSON_SDK_PATH}"

    info "Start Install Jetson Public Sources"
    [ ! -d "${JETSON_SDK_HOME}/source/public" ] &&
        tar -xf ${JETSON_PACKAGE_PATH}/public_sources.tbz2 -C ${JETSON_SDK_PATH}
    pushd "${JETSON_SDK_HOME}/source/public" >/dev/null 2>&1
    [ ! -e ${JETSON_KERNEL} ] && mkdir -p ${JETSON_KERNEL}
    [ ! -e "${JETSON_SDK_HOME}/source/public/kernel" ] && tar -xf kernel_src.tbz2 -C ${JETSON_KERNEL}
    popd >/dev/null 2>&1

    pushd "${JETSON_PUBLIC_SOURCE}" >/dev/null 2>&1
    [ ! -d "${JETSON_DISPLAY_MODULE}" ] &&
        tar -xf "${JETSON_PUBLIC_PACKAGE}/nvidia_kernel_display_driver_source.tbz2" -C "${JETSON_PUBLIC_SOURCE}"
    popd >/dev/null 2>&1

    info "Start Install Custom Layer"
    sudo cp ${JETSON_SDK_PATH}/custom_layer/Linux_for_Tegra/* ${JETSON_SDK_HOME} -ardf
}

function __setup_dev_env() {
    pushd "${JETSON_SDK_HOME}" >/dev/null 2>&1
    # Copy NVIDIA user space libraries into target file system
    info "Start Install Rootfs Libraries"
    sudo ./apply_binaries.sh --factory
    popd >/dev/null 2>&1
}

function setup_host_env() {
    pushd "${JETSON_SDK_HOME}" >/dev/null 2>&1
    # Install the prerequisite dependencies for flashing
    info "Start Install Jetson Prerequisite"
    # sudo ./tools/l4t_flash_prerequisites.sh
    popd >/dev/null 2>&1
}

function setup_env() {
    sudo apt install -y --no-install-recommends \
        qemu-user-static \
        docker.io
}

function __install_custom_layer() {
    # Install Custom Layer
    [ ! -d "${JETSON_SDK_PATH}/custom_layer" ] &&
        cp "${JETSON_SDK_PATH}/custom_layer/*" . -arfd
}

function check_board() {
    pushd "${JETSON_SDK_HOME}" >/dev/null 2>&1
    FLASH_BOARDID=$(sudo ./nvautoflash.sh --print_boardid)
    if [ $? -eq 1 ]; then
        # There was an error with the Jetson connected
        # It may not be detectable, be in force recovery mode
        # Or there may be more than one Jetson in FRM
        error "$FLASH_BOARDID" | grep Error
        error "Make sure that your Jetson is connected through"
        error "a USB port and in Force Recovery Mode"
        exit 1
    fi
    info ${FLASH_BOARDID}
    popd >/dev/null 2>&1
}

function flash_usb() {
    info "Start Flash Usb"
}

function build_image() {
    local build_type=${1}
    info "Start Build ${build_type} Image"
    pushd ${JETSON_SDK_HOME} >/dev/null 2>&1
    if [ ${build_type} == "nvme" ]; then
        sudo -E ADDITIONAL_DTB_OVERLAY_OPT="BootOrderNvme.dtbo" ./tools/kernel_flash/l4t_initrd_flash_internal.sh \
            --external-device nvme0n1p1 \
            -c tools/kernel_flash/flash_l4t_external.xml \
            --network usb0 \
            --showlogs \
            -S 64GiB \
            --no-flash \
            -p '--no-systemimg -c bootloader/t186ref/cfg/flash_l4t_t194_qspi_p3668.xml' \
            ${BOARD} \
            internal
    elif [ ${build_type} == "sd" ]; then
        sudo -E ./tools/kernel_flash/l4t_initrd_flash.sh \
            --no-flash \
            -c bootloader/t186ref/cfg/flash_l4t_t194_spi_sd_p3668.xml \
            --network usb0 \
            --showlogs \
            -S 32GiB \
            ${BOARD} \
            mmcblk0p1
    elif [ ${build_type} == "usb" ]; then
        info "--usb"
    fi
    popd >/dev/null
}

function initramfs() {
    sudo gunzip -c l4t_initrd.img | sudo cpio -i
    sudo find . | sudo cpio -H newc -o | sudo gzip -9 -n >l4t_initrd.img
}

function flash() {
    local flash_type=${1} # "nvme" "sd" "usb" "auto"

    info "Start Flash Jetson ${flash_type}"

    # Turn off USB mass storage during flashing
    sudo systemctl stop udisks2.service

    pushd "${JETSON_SDK_HOME}" >/dev/null 2>&1
    # 7023 for Jetson AGX Orin
    # 7019 for Jetson AGX Xavier.
    # 7e19 for Jetson AGX Xavier.
    local idProduct=7e19
    local usb_info=$(grep ${idProduct} /sys/bus/usb/devices/*/idProduct)
    local usb_instance=$(echo ${usb_info} | awk -F'/' '{print $6}' | tr -d '\n')

    if [ "${flash_type}" == "nvme" ]; then
        sudo -E ADDITIONAL_DTB_OVERLAY_OPT="BootOrderNvme.dtbo" ./tools/kernel_flash/l4t_initrd_flash_internal.sh \
            --usb-instance ${usb_instance} \
            --external-device nvme0n1p1 \
            -c "tools/kernel_flash/flash_l4t_external.xml" \
            --showlogs \
            --network usb0 \
            --flash-only \
            -S 64GiB \
            --network usb0 \
            -S 64Gib \
            ${BOARD} \
            internal
    elif [ "${flash_type}" == "sd" ]; then
        sudo -E ./flash.sh \
            -k APP \
            -S 32GiB \
            --usb-instance ${usb_instance} \
            ${BOARD} \
            internal
        # sudo -E ./tools/kernel_flash/l4t_initrd_flash.sh \
        #     --usb-instance ${usb_instance} \
        #     -c bootloader/t186ref/cfg/flash_l4t_t194_spi_sd_p3668.xml \
        #     --flash-only \
        #     --showlogs \
        #     --network usb0 \
        #     -S 32GiB \
        #     ${BOARD} \
        #     mmcblk0p1
    else
        sudo -E ./nvsdkmanager_flash.sh --storage "${JETSON_STORAGE_TYPE}"
    fi

    popd >/dev/null 2>&1

    # sudo -E ./flash.sh --no-systemimg -r -S 32GiB ${BOARD} external

}

function build_kernel() {
    info "Start Modify Kernel Config"
    __kernel_config

    info "Start Build Kernel Source"
    pushd "${JETSON_KERNEL}" >/dev/null 2>&1
    pushd kernel >/dev/null 2>&1
    bash -E ./kernel-5.10/scripts/rt-patch.sh apply-patches
    popd >/dev/null 2>&1
    [ ! -d "${JETSON_KERNEL_OUT}" ] && mkdir -p "${JETSON_KERNEL_OUT}"
    ./nvbuild.sh -o "${JETSON_KERNEL_OUT}"
    popd >/dev/null 2>&1

    info "Start Build Display Modules"
    pushd "${JETSON_DISPLAY_MODULE}" >/dev/null 2>&1

    make \
        modules \
        SYSSRC="${JETSON_KERNEL}/kernel/kernel-5.10" \
        SYSOUT="${JETSON_KERNEL_OUT}" \
        CC=${CROSS_COMPILE_AARCH64}gcc \
        LD=${CROSS_COMPILE_AARCH64}ld.bfd \
        AR=${CROSS_COMPILE_AARCH64}ar \
        CXX=${CROSS_COMPILE_AARCH64}g++ \
        OBJCOPY=${CROSS_COMPILE_AARCH64}objcopy \
        TARGET_ARCH=aarch64 \
        ARCH=arm64 \
        -j$(nproc)

    make \
        ARCH=arm64 \
        LOCALVERSION="-tegra" \
        CROSS_COMPILE="${CROSS_COMPILE_AARCH64}" \
        -C "${JETSON_KERNEL}/kernel/kernel-5.10" \
        O=${JETSON_KERNEL_OUT} \
        -j$(nproc) \
        modules_prepare

    popd >/dev/null 2>&1
}

function install_kernel() {
    info "Start Install Kernel Images"
    cp -ardf "${JETSON_KERNEL_OUT}/arch/arm64/boot/Image" "${JETSON_SDK_HOME}/kernel/Image"

    pushd ${JETSON_KERNEL_OUT} >/dev/null 2>&1
    [ -e "${JETSON_SDK_HOME}/kernel/kernel_supplements.tbz2" ] && rm -rf "${JETSON_SDK_HOME}/kernel/kernel_supplements.tbz2"
    tar --owner root --group root -cjf ${JETSON_SDK_HOME}/kernel/kernel_supplements.tbz2 ${JETSON_SDK_HOME}/rootfs/lib/modules
    popd >/dev/null 2>&1

    sudo make ARCH=arm64 \
        CROSS_COMPILE="${CROSS_COMPILE_AARCH64}" \
        O="${JETSON_KERNEL_OUT}" \
        -C "${JETSON_KERNEL}/kernel/kernel-5.10" \
        modules_install \
        LOCALVERSION="-tegra" \
        INSTALL_MOD_PATH="${JETSON_SDK_HOME}/rootfs/" \
        INSTALL_MOD_STRIP=1 \
        -j$(nproc)

    sudo cp -arfd "${JETSON_KERNEL_OUT}/drivers/gpu/nvgpu/nvgpu.ko" \
        "${JETSON_SDK_HOME}/rootfs/usr/lib/modules/${JETSON_KERNEL_VERSION}/kernel/drivers/gpu/nvgpu/nvgpu.ko"

    sudo cp -arfd "${JETSON_KERNEL_OUT}/arch/arm64/boot/dts/nvidia/" \
        "${JETSON_SDK_HOME}/kernel/dtb"

    [ ! -d "${JETSON_SDK_HOME}/rootfs/usr/lib/modules/${JETSON_KERNEL_VERSION}/extra/opensrc-disp/" ] &&
        sudo mkdir -p "${JETSON_SDK_HOME}/rootfs/usr/lib/modules/${JETSON_KERNEL_VERSION}/extra/opensrc-disp/"
    sudo cp -arfd ${JETSON_DISPLAY_MODULE}/kernel-open/{nvidia-drm.ko,nvidia.ko,nvidia-modeset.ko} \
        ${JETSON_SDK_HOME}/rootfs/usr/lib/modules/${JETSON_KERNEL_VERSION}/extra/opensrc-disp/

    __modules_dep
}

function __create_user() {
    pushd "${JETSON_SDK_HOME}/tools/" >/dev/null 2>&1
    sudo ./l4t_create_default_user.sh \
        --username ${USER_NAME} \
        --password ${PASSWD} \
        --hostname ${USER_NAME} \
        --accept-license
    popd >/dev/null 2>&1
}

function run_docker() {
    local docker_name=$(basename "$(pwd)")_job
    if [[ ! "$(docker ps -aqf "name=${docker_name}")" ]]; then
        info "Start New Docker Container"
        docker run -itd --privileged \
            --name=${docker_name} \
            --net=host \
            -v /dev/bus/usb:/dev/bus/usb \
            -v ${PWD}:/l4t \
            jetson_dev:${DOCKER_VERSION}
    fi

    if ! docker ps -qf "name=$docker_name" | grep -q . ; then
        docker start ${docker_name}
    fi
    docker exec -it ${docker_name} fish
}

function build_docker() {
    cp $(basename $0) docker/files -ardf
    docker build ./docker -t jetson_dev:${DOCKER_VERSION}
    # run_docker bash /l4t/jd.sh --install_sdk /l4t
}

function build_app() {
    local need_clear=${1} # yes or no
    local is_verbose=${2} # yes or no
    local is_debug=${3}   # yes or no

    local app_build="${JETSON_SDK_PATH}/build/application"
    [ ! -d ${app_build} ] && mkdir -p ${app_build}

    if [[ ${need_clear} == "yes" || -z "$(ls -A ${app_build})" ]]; then
        cmake \
            -B ${app_build} \
            -S "${JETSON_SDK_PATH}/application" \
            -DCMAKE_TOOLCHAIN_FILE=${JETSON_SDK_PATH}/scripts/toolchain_aarch64.cmake
    fi
    cmake --build ${app_build} -j$(nproc)
}

function usage() {
    local ScriptName=$1
    cat <<EOF
    Use: "${ScriptName}" 
        [ --install_sdk <path> | -i <path> ] Install l4t SDK
            path: sdk install path 
        [ --build_app |  -b ] Build Application
        [ --build_kernel ] Build Linux Kernel & Modules & Display Modulesx
        [ --build_rootfs <is_custom> <need_dev> ] Build Rootfs; 
            is_custom: yes, no; 
            need_dev: yes, no
        [ --build_image <type> ] Build Flash Image; 
            type : nvme, sd, usb
        [ --install_kernel ] Install Linux Kernel & Modules & Display Modules To Flash Dir & Rootfs
        [ --flash | -f <type> ]  Flash Image To Jetson Device; 
            type : nvme, sd, usb, auto
        [ --build_docker ] Build L4t Dev Docker Image
        [ --run_docker | -r ]  Run L4t Dev Docker
        [ --setup_env ] Install Dev Env To Current Host PC
        [ --help | -h ] Print This Message
EOF
}

if [ -f ${SDK_VARIABLE_F} ]; then
    source ${SDK_VARIABLE_F}
fi

function parse_args() {
    while [ -n "${1}" ]; do
        case "${1}" in
        -h | --help)
            usage $(basename "$0")
            exit 0
            ;;
        -i | --install_sdk)
            install_sdk ${2}
            exit 0
            ;;
        --build_app)
            build_app
            exit 0
            ;;
        --build_kernel)
            build_kernel
            exit 0
            ;;
        --build_rootfs)
            build_rootfs ${2} ${3}
            exit 0
            ;;
        --install_kernel)
            install_kernel
            exit 0
            ;;
        --build_image)
            build_image ${2}
            exit 0
            ;;
        -f | --flash)
            flash ${2}
            exit 0
            ;;
        --build_docker)
            build_docker
            exit 0
            ;;
        -r | --run_docker)
            run_docker
            exit 0
            ;;
        *)
            echo "ERROR: Invalid parameter. Exiting..."
            usage
            exit 1
            ;;
        esac
    done
}

parse_args $@
