#!/bin/bash

set -e
export DOCKER_VERSION=35.4.1
export SDK_VARIABLE_F="./.sdk_variable.env"

function set_variable()
{
    local sdk_home=$1
    export BOARD=${BOARD}
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
    export ADDITIONAL_DTB_OVERLAY="BootOrderNvme.dtbo"
    export USER_NAME=lw
    export PASSWD=lw
    # TegraID Xavier 0x19 Orin 0x23
}

function save_variable()
{
cat> ${SDK_VARIABLE_F} <<EOF
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
export ADDITIONAL_DTB_OVERLAY=BootOrderNvme.dtbo
export USER_NAME=${USER_NAME}
export PASSWD=${PASSWD}
EOF
}

function remove_static_libs()
{
    echo "Start Remove Static Libs"
    pushd ${JETSON_ROOTFS} > /dev/null 2>&1
    sudo find -name lib*.a | xargs sudo rm 
    popd > /dev/null
}

function strip_rootfs()
{
    echo "Start Strip Rootfs"
    pushd ${JETSON_ROOTFS} > /dev/null 2>&1
    sudo find -name lib*.so | xargs sudo ${CROSS_COMPILE_AARCH64}strip
    sudo find -executable | xargs sudo ${CROSS_COMPILE_AARCH64}strip
    popd > /dev/null
}

function remove_include_file()
{
    echo "Start Remove Rootfs Include File"
    pushd ${JETSON_ROOTFS} > /dev/null 2>&1
    sudo find -name *.h | xargs sudo rm 
    popd > /dev/null
}

function gen_base_rootfs()
{
    popd ${JETSON_SDK_HOME}/tools/samplefs > /dev/null 2>&1
    sudo ./nv_build_samplefs.sh --abi aarch64 --distro ubuntu --flavor basic --version focal
    popd  > /dev/null 2>&1
}

function copy_customer_layer()
{
    sudo cp -arfd ${JETSON_SDK_PATH}/customer_layer/Linux_for_Tegra/rootfs/* ${JETSON_ROOTFS}
}

function __install_jetpack()
{
    pushd "${JETSON_ROOTFS}" > /dev/null 2>&1
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

    sudo LC_ALL=C chroot . apt update
    sudo LC_ALL=C chroot . apt install --no-install-recommends -y gnupg2

    sudo LC_ALL=C chroot . apt-key adv --fetch-key https://repo.download.nvidia.com/jetson/jetson-ota-public.asc
    sudo LC_ALL=C chroot . apt update
    sudo LC_ALL=C chroot . apt install --no-install-recommends -y nvidia-jetpack-runtime htop lrzsz
    sudo LC_ALL=C chroot . usermod -aG docker ${USER_NAME}

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
    popd > /dev/null
}

function build_rootfs()
{
    local is_customer=${1}
    sudo rm -rf ${JETSON_SDK_HOME}/rootfs/*
    if [ ${is_customer} = "yes" ]; then
        local custom_rootfs=${JETSON_SDK_HOME}/tools/samplefs/sample_fs.tbz2
        [ ! -e ${custom_rootfs} ] && gen_base_rootfs
        
        sudo tar -xjf ${custom_rootfs} -C ${JETSON_ROOTFS}
    else
        echo "Start Download Jetson Rootfs"
        local rootfs_tgz=${JETSON_PACKAGE_PATH}/${SAMPLE_FS_PACKAGE}
        [ -d "${JETSON_PACKAGE_PATH}" ] || mkdir -p ${JETSON_PACKAGE_PATH}
        [ -f "${rootfs_tgz}" ] || \
        wget -P ${JETSON_PACKAGE_PATH} -N https://developer.nvidia.com/downloads/embedded/l4t/${SDK_VERSION}/release/${SAMPLE_FS_PACKAGE}

        echo "Start Install Jetson Rootfs"
        pushd "${JETSON_ROOTFS}" > /dev/null 2>&1
        [ ! -e "${JETSON_ROOTFS}/bin" ] && sudo tarpf ${rootfs_tgz}
        export LDK_ROOTFS_DIR=$PWD
        popd > /dev/null 2>&1

    fi
    setup_env
    create_user
    copy_customer_layer
    __install_jetpack
}

function install_sdk()
{
    [ $# != 1 ] && echo "Error: Input Install Path" && exit -1
    set_variable $1
    save_variable

    echo "Start Download ToolChain"
    [ -d "${JETSON_PACKAGE_PATH}" ] || mkdir -p ${JETSON_PACKAGE_PATH}
    local toolchain_tgz=${JETSON_PACKAGE_PATH}/aarch64--glibc--stable-final.tar.gz
    [ -f "${toolchain_tgz}" ] || \
    wget -O ${toolchain_tgz} -N https://developer.nvidia.com/embedded/jetson-linux/bootlin-toolchain-gcc-93
    
    echo "Start Download Jetson SDK"
    local sdk_tgz=${JETSON_PACKAGE_PATH}/${L4T_RELEASE_PACKAGE}
    [ -f "${sdk_tgz}" ] || \
    wget -P ${JETSON_PACKAGE_PATH} -N https://developer.nvidia.com/downloads/embedded/l4t/${SDK_VERSION}/release/${L4T_RELEASE_PACKAGE}
    
    echo "Start Download Jetson Kernel Source"
    [ -f "${JETSON_PACKAGE_PATH}/public_sources.tbz2" ] || \
    wget -N -P ${JETSON_PACKAGE_PATH} https://developer.nvidia.com/downloads/embedded/l4t/${SDK_VERSION}/sources/public_sources.tbz2

    echo "Start Install ToolChain"
    [ ! -d "${JETSON_TOOLCHAIN}" ] && mkdir -p "${JETSON_TOOLCHAIN}" && tar -xzf "${toolchain_tgz}" -C "${JETSON_TOOLCHAIN}"

    echo "Start Install Jetson SDK"
    [ ! -e "${JETSON_SDK_HOME}" ] && tar -xjf "${sdk_tgz}" -C "${JETSON_SDK_PATH}"

    echo "Start Install Jetson Public Sources"
    [ ! -d "${JETSON_SDK_HOME}/source/public" ] && \
    tar -xf ${JETSON_PACKAGE_PATH}/public_sources.tbz2 -C ${JETSON_SDK_PATH}
    pushd "${JETSON_SDK_HOME}/source/public" > /dev/null 2>&1
    [ ! -e ${JETSON_KERNEL} ] && mkdir -p ${JETSON_KERNEL}
    [ ! -e "${JETSON_SDK_HOME}/source/public/kernel" ] && tar -xf kernel_src.tbz2 -C ${JETSON_KERNEL}
    popd > /dev/null 2>&1

    pushd "${JETSON_PUBLIC_SOURCE}" > /dev/null 2>&1
    [ ! -d "${JETSON_DISPLAY_MODULE}" ] && \
    tar -xf "${JETSON_PUBLIC_PACKAGE}/nvidia_kernel_display_driver_source.tbz2" -C "${JETSON_PUBLIC_SOURCE}"
}

function setup_env()
{
    pushd "${JETSON_SDK_HOME}" > /dev/null 2>&1
    # Copy NVIDIA user space libraries into target file system
    echo "Start Install Rootfs Libraries"
    sudo ./apply_binaries.sh --factory

    # Install the prerequisite dependencies for flashing
    echo "Start Install Jetson Prerequisite"
    # sudo ./tools/l4t_flash_prerequisites.sh
    popd > /dev/null 2>&1
}

function install_customer_layer()
{
    # Install Customer Layer
    [ ! -d "${JETSON_SDK_PATH}/customer_layer" ] && cp "${JETSON_SDK_PATH}/customer_layer/*" . -arfd
}

function check_board()
{
    pushd "${JETSON_SDK_HOME}" > /dev/null 2>&1
    FLASH_BOARDID=$(sudo ./nvautoflash.sh --print_boardid)
    if [ $? -eq 1 ] ; then
        # There was an error with the Jetson connected
        # It may not be detectable, be in force recovery mode
        # Or there may be more than one Jetson in FRM 
        echo "$FLASH_BOARDID" | grep Error
        echo "Make sure that your Jetson is connected through"
        echo "a USB port and in Force Recovery Mode"
        exit 1
    fi
    echo ${FLASH_BOARDID}
    popd > /dev/null 2>&1
}

function flash_usb()
{
    echo "Start Flash Usb"
}

function build_image()
{
    local build_type=${1}
    echo "Start Build ${build_type} Image"
    pushd ${JETSON_SDK_HOME} > /dev/null 2>&1
    if [ ${build_type} == "nvme" ]; then
        sudo -E ADDITIONAL_DTB_OVERLAY="BootOrderNvme.dtbo" ADDITIONAL_DTB_OVERLAY_OPT="BootOrderNvme.dtbo" ./tools/kernel_flash/l4t_initrd_flash_internal.sh \
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
        echo "--sd"
    elif [ ${build_type} == "usb" ]; then 
        echo "--usb"
    fi
    popd > /dev/null
}

function initramfs()
{
    gunzip -c l4t_initrd.img | cpio -i
    find . | cpio -H newc -o | gzip -9 -n > l4t_initrd.img
}

function flash_nvme()
{
    # 7023 for Jetson AGX Orin 
    # 7019 for Jetson AGX Xavier.
    # 7e19 for Jetson AGX Xavier.
    local idProduct=7e19
    local usb_info=`grep ${idProduct} /sys/bus/usb/devices/*/idProduct`
    local usb_instance=`echo ${usb_info} | awk -F'/' '{print $6}' | tr -d '\n'`

    pushd ${JETSON_SDK_HOME} > /dev/null 2>&1
    sudo -E ADDITIONAL_DTB_OVERLAY="BootOrderNvme.dtbo" ADDITIONAL_DTB_OVERLAY_OPT="BootOrderNvme.dtbo" ./tools/kernel_flash/l4t_initrd_flash_internal.sh \
        --usb-instance ${usb_instance} \
        --external-device nvme0n1p1 \
        -c "tools/kernel_flash/flash_l4t_external.xml" \
        --showlogs \
        --network usb0 \
        --flash-only \
        -S 64GiB \
        --network usb0 \
        -S 64Gib
        ${BOARD} \
        internal
    popd > /dev/null
}

function flash_auto()
{
    echo "Auto Flash"
    sudo ./nvsdkmanager_flash.sh --storage "${JETSON_STORAGE_TYPE}"
}

function flash_sd()
{
    echo "Flash SD Card"
}

function flash()
{   
    local flash_type=${1}           # "nvme" "sd" "usb" "auto"

    echo "Start Flash Jetson ${flash_type}" 

    # Turn off USB mass storage during flashing
    sudo systemctl stop udisks2.service

    pushd "${JETSON_SDK_HOME}" > /dev/null 2>&1

    if [ "${flash_type}" == "nvme" ]; then
        flash_nvme
    elif [ "${flash_type}" == "sd" ]; then 
        flash_sd
    else 
        flash_auto
    fi
    
    popd > /dev/null 2>&1
    
    

    # sudo -E ./flash.sh --no-systemimg -r -S 32GiB ${BOARD} external

}

function build_kernel()
{
    echo "Start Build Kernel Source"
    pushd "${JETSON_KERNEL}" > /dev/null 2>&1
    pushd kernel > /dev/null 2>&1
    bash -E ./kernel-5.10/scripts/rt-patch.sh apply-patches
    popd > /dev/null 2>&1
    [ ! -d "${JETSON_KERNEL_OUT}" ] && mkdir -p "${JETSON_KERNEL_OUT}"
    ./nvbuild.sh -o "${JETSON_KERNEL_OUT}"
    popd > /dev/null 2>&1

    echo "Start Build Display Modules"
    pushd "${JETSON_DISPLAY_MODULE}" > /dev/null 2>&1

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

    popd > /dev/null 2>&1
}

function install_base_rootfs()
{
    pushd "${JETSON_SDK_HOME}tools/samplefs" > /dev/null 2>&1
    sudo ./nv_build_samplefs.sh --abi aarch64 --distro ubuntu --flavor basic --version focal
    popd > /dev/null 2>&1
}

function install_kernel() 
{
    echo "Start Install Kernel Images"
    cp -ardf "${JETSON_KERNEL_OUT}/arch/arm64/boot/Image" "${JETSON_SDK_HOME}/kernel/Image"
    
    pushd ${JETSON_KERNEL_OUT} > /dev/null 2>&1
    [ -e "${JETSON_SDK_HOME}/kernel/kernel_supplements.tbz2" ] && rm -rf "${JETSON_SDK_HOME}/kernel/kernel_supplements.tbz2"
    tar --owner root --group root -cjf ${JETSON_SDK_HOME}/kernel/kernel_supplements.tbz2 ${JETSON_SDK_HOME}/rootfs/lib/modules
    popd > /dev/null 2>&1
    
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

    [ ! -d "${JETSON_SDK_HOME}/rootfs/usr/lib/modules/${JETSON_KERNEL_VERSION}/extra/opensrc-disp/" ] && \
    sudo mkdir -p "${JETSON_SDK_HOME}/rootfs/usr/lib/modules/${JETSON_KERNEL_VERSION}/extra/opensrc-disp/"
    sudo cp -arfd ${JETSON_DISPLAY_MODULE}/kernel-open/{nvidia-drm.ko,nvidia.ko,nvidia-modeset.ko} \
    ${JETSON_SDK_HOME}/rootfs/usr/lib/modules/${JETSON_KERNEL_VERSION}/extra/opensrc-disp/

}

function create_user()
{
    pushd "${JETSON_SDK_HOME}/tools/" > /dev/null 2>&1
    sudo ./l4t_create_default_user.sh \
        --username ${USER_NAME} \
        --password ${PASSWD} \
        --hostname ${USER_NAME} \
        --accept-license
    popd > /dev/null 2>&1
}

function run_docker()
{
    docker run -itd --privileged \
        --name=jetson_dev \
        --net=host \
        -v /dev/bus/usb:/dev/bus/usb \
        -v ${PWD}:/l4t \
        jetson_dev:${DOCKER_VERSION}
}

function build_docker()
{
    cp `basename $0` docker/files -ardf
    docker build ./docker -t jetson_dev:${DOCKER_VERSION}
    run_docker bash /l4t/jd.sh --install_sdk /l4t
}

function usage()
{
    local ScriptName=$1
cat <<EOF 
    Use: "${ScriptName}" 
        [ --install_sdk|-i <PATH> ] Install l4t SDK
        [ --build_kernel ] Build Linux Kernel & Modules & Display Modulesx
        [ --build_rootfs <is_custom> ] Build Rootfs is_custom: yes, no
        [ --build_image <type> ] Build Flash Image type : nvme, sd, usb
        [ --install_kernel ] Install Linux Kernel & Modules & Display Modules To Flash Dir & Rootfs
        [ --flash|-f <type> ]  Flash Image To Jetson Device: type : nvme, sd, usb, auto
        [ --build_docker ] Build L4t Dev Docker Image
        [ --run_docker|-r ]  Run L4t Dev Docker
        [ --setup_env ] Install Dev Env Packages & Install Some L4t Package To Rootfs
        [ --help|-h ] Print This Message
EOF
}

if [ -f ${SDK_VARIABLE_F} ]; then
    source ${SDK_VARIABLE_F}
fi

# script name
SCRIPT_NAME=$(basename "$0")
GETOPT=`getopt -n "$SCRIPT_NAME" \
    --longoptions help,install_sdk:,build_kernel,build_rootfs:,install_kernel,build_image:,flash:,flash_only,build_docker,run_docker,setup_env \
    -o hi:f:r -- "$@"`
if [ $? != 0 ]; then
    usage
    exit 1
fi

eval set -- "${GETOPT}"
while [ $# -gt 0 ]; do
	case "$1" in
	-h|--help) usage ${SCRIPT_NAME} && exit 0 ;;
	-i|--install_sdk) install_sdk ${2} && exit 0 ;;
	--build_kernel) build_kernel && exit 0 ;;
	--build_rootfs) build_rootfs ${2} && exit 0 ;;
	--build_image) build_image ${2} && exit 0 ;;
	--install_kernel) install_kernel && exit 0 ;;
	-r|--run_docker) run_docker && exit 0 ;;
	--build_docker) build_docker && exit 0 ;;
	--setup_env) setup_env && exit 0 ;;
	-f|--flash) flash ${2}; shift;;
	--) shift; break ;;
	-*) echo "Unknown option: $@" >&2 ; usage "${SCRIPT_NAME}"; exit 1 ;;
	esac
	shift
done

