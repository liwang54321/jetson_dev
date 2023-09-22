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
    # export SAMPLE_FS_PACKAGE=base_fs.tbz2
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
EOF
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
    
    echo "Start Download Jetson Rootfs"
    local rootfs_tgz=${JETSON_PACKAGE_PATH}/${SAMPLE_FS_PACKAGE}
    [ -d "${JETSON_PACKAGE_PATH}" ] || mkdir -p ${JETSON_PACKAGE_PATH}
    [ -f "${rootfs_tgz}" ] || \
    wget -P ${JETSON_PACKAGE_PATH} -N https://developer.nvidia.com/downloads/embedded/l4t/${SDK_VERSION}/release/${SAMPLE_FS_PACKAGE}
    
    echo "Start Download Jetson Kernel Source"
    [ -f "${JETSON_PACKAGE_PATH}/public_sources.tbz2" ] || \
    wget -N -P ${JETSON_PACKAGE_PATH} https://developer.nvidia.com/downloads/embedded/l4t/${SDK_VERSION}/sources/public_sources.tbz2

    echo "Start Install ToolChain"
    [ ! -d "${JETSON_TOOLCHAIN}" ] && mkdir -p "${JETSON_TOOLCHAIN}" && tar -xzf "${toolchain_tgz}" -C "${JETSON_TOOLCHAIN}"

    echo "Start Install Jetson SDK"
    [ ! -e "${JETSON_SDK_HOME}" ] && tar -xjf "${sdk_tgz}" -C "${JETSON_SDK_PATH}"
    
    echo "Start Install Jetson Rootfs"
    pushd "${JETSON_ROOTFS}" > /dev/null 2>&1
    [ ! -e "${JETSON_ROOTFS}/bin" ] && sudo tar -xpf ${rootfs_tgz}
    export LDK_ROOTFS_DIR=$PWD
    popd > /dev/null 2>&1

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

function flash_nvme()
{
    echo "Start Flash Nvme"
    # 7023 for Jetson AGX Orin 
    # 7019 for Jetson AGX Xavier.
    # 7e19 for Jetson AGX Xavier.
    local idProduct=7e19
    local usb_info=`grep ${idProduct} /sys/bus/usb/devices/*/idProduct`
    local usb_instance=`echo ${usb_info} | awk -F'/' '{print $6}' | tr -d '\n'`

    local flash_only=${1}

    if [ "${flash_only}" == "off" ]; then
        echo "Start Gen Flash Images"
        sudo -E ADDITIONAL_DTB_OVERLAY="BootOrderNvme.dtbo" ADDITIONAL_DTB_OVERLAY_OPT="BootOrderNvme.dtbo" bash -x ./tools/kernel_flash/l4t_initrd_flash_internal.sh \
            --external-device nvme0n1p1 \
            -c tools/kernel_flash/flash_l4t_nvme.xml \
            --network usb0 \
            --showlogs \
            -S 64GiB \
            --no-flash \
            -p '--no-systemimg -c bootloader/t186ref/cfg/flash_l4t_t194_qspi_p3668.xml' \
            ${BOARD} \
            internal
    fi

    echo "Start Flash Images"
    sudo -E ADDITIONAL_DTB_OVERLAY="BootOrderNvme.dtbo" ADDITIONAL_DTB_OVERLAY_OPT="BootOrderNvme.dtbo" bash -x ./tools/kernel_flash/l4t_initrd_flash_internal.sh \
        --usb-instance ${usb_instance} \
        --device-instance 0 \
        --external-device nvme0n1p1 \
        -c "tools/kernel_flash/flash_l4t_nvme.xml" \
        --showlogs \
        --network usb0 \
        --flash-only \
        -S 64GiB \
        --network usb0 \
        ${BOARD} \
        internal

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
    local flash_type=${1}           # "nvme" "sd" "auto"
    local flash_only=${2}           # "on" "off"

    echo "Start Flash ${flash_type} Flash_only = ${flash_only}" 

    # Turn off USB mass storage during flashing
    sudo systemctl stop udisks2.service

    pushd "${JETSON_SDK_HOME}" > /dev/null 2>&1

    if [ "${flash_type}" == "nvme" ]; then
        flash_nvme ${flash_only}
    elif [ "${flash_type}" == "sd" ]; then 
        flash_sd ${flash_only}
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
    sudo ./l4t_create_default_user.sh --username lw --password lw --hostname lw --accept-license
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
        [ --build_kernel ] Build Linux Kernel & Modules & Display Modules
        [ --install_kernel ] Install Linux Kernel & Modules & Display Modules To Flash Dir & Rootfs
        [ --create_user|-u ] Create User To Rootfs
        [ --flash|-f <type> <flash_only> ]  Flash Image To Jetson Device: type : nvme, sd, auto, flash_only: on, off
        [ --build_docker ] Build L4t Dev Docker Image
        [ --run_docker|-r ]  Run L4t Dev Docker
        [ --setup_env ] Install Dev Env Packages & Install Some L4t Package To Rootfs
        [ --help|-h ] Print This Message
EOF
}

if [ -f ${SDK_VARIABLE_F} ]; then
    echo "Get Env File"
    source ${SDK_VARIABLE_F}
fi

# script name
SCRIPT_NAME=$(basename "$0")
GETOPT=`getopt -n "$SCRIPT_NAME" \
    --longoptions help,install_sdk:,build_kernel,install_kernel,create_user,flash:,flash_only,build_docker,run_docker,setup_env \
    -o hi:uf:r -- "$@"`
if [ $? != 0 ]; then
    usage
    exit 1
fi

eval set -- "${GETOPT}"
flash_only="off"
flash_dev="auto"
while [ $# -gt 0 ]; do
	case "$1" in
	-h|--help) usage ${SCRIPT_NAME} && exit 0 ;;
	-i|--install_sdk) install_sdk ${2} && exit 0 ;;
	--build_kernel) build_kernel && exit 0 ;;
	--install_kernel) install_kernel && exit 0 ;;
	-r|--run_docker) run_docker && exit 0 ;;
	--build_docker) build_docker && exit 0 ;;
	--flash_only) flash_only="on" ;;
	-u|--create_user) create_user && exit 0 ;;
	--setup_env) setup_env && exit 0 ;;
	-f|--flash) flash_dev=${2}; shift;;
	--) shift; break ;;
	-*) echo "Unknown option: $@" >&2 ; usage "${SCRIPT_NAME}"; exit 1 ;;
	esac
	shift
done

flash ${flash_dev} ${flash_only}