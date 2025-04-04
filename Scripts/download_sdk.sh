#!/bin/bash
set -e
top_dir="$(dirname "$(readlink -f "$0")")"

# shellcheck disable=SC1091
source "${top_dir}/../args.sh"

# shellcheck disable=SC1090
source "${top_dir}/download_r${VERSION}.sh"

if [[ -z "${bsp_url}" || -z "${rootfs_url}" || -z "${sources_url}" || -z "${toolchain_url}" ]]; then
    echo "Error: Invalid version or URLs not found for version $VERSION."
    exit 1
fi

mkdir -p "$1/Packages"
[ -e "$1/Packages/Jetson_Linux_R${VERSION}_aarch64.tbz2" ] || \
    wget --show-progress --progress=bar:force:noscroll "${bsp_url}" -O "$1/Packages/Jetson_Linux_R${VERSION}_aarch64.tbz2"

[ -e "$1/Packages/Tegra_Linux_Sample-Root-Filesystem_R${VERSION}_aarch64.tbz2" ] || \
    wget --show-progress --progress=bar:force:noscroll "${rootfs_url}" -O "$1/Packages/Tegra_Linux_Sample-Root-Filesystem_R${VERSION}_aarch64.tbz2"

[ -e "$1/Packages/public_sources_R${VERSION}.tbz2" ] || \
    wget --show-progress --progress=bar:force:noscroll "${sources_url}" -O "$1/Packages/public_sources_R${VERSION}.tbz2"

[ -e "$1/Packages/aarch64--glibc--stable-2022.08-1_R${VERSION}.tar.bz2" ] || \
    wget --show-progress --progress=bar:force:noscroll "${toolchain_url}" -O "$1/Packages/aarch64--glibc--stable-2022.08-1_R${VERSION}.tar.bz2"

tar -x -p -f "$1/Packages/Jetson_Linux_R${VERSION}_aarch64.tbz2" -C "$1"
sudo tar -x -p -f "$1/Packages/Tegra_Linux_Sample-Root-Filesystem_R${VERSION}_aarch64.tbz2" -C "$1/Linux_for_Tegra/rootfs/"
tar -x -p -f "$1/Packages/public_sources_R${VERSION}.tbz2" -C "$1"

[ -d "$1/toolchains" ] || mkdir -p "$1/toolchains"
tar -x -p -f "$1/Packages/aarch64--glibc--stable-2022.08-1_R${VERSION}.tar.bz2" -C "$1/Toolchains"

tar -I lbzip2 -xf "$1/Packages/public_sources_R${VERSION}.tbz2" -C "$1"

pushd "$1/Linux_for_Tegra/source/" > /dev/null || exit
public_sources_dir="${PWD}/../public_sources" 
mkdir "${public_sources_dir}"
tar -I lbzip2 -C "${public_sources_dir}" -xf kernel_src.tbz2
tar -I lbzip2 -C "${public_sources_dir}" -xf kernel_oot_modules_src.tbz2
tar -I lbzip2 -C "${public_sources_dir}" -xf nvidia_kernel_display_driver_source.tbz2
popd > /dev/null  || exit


pushd "$1/Linux_for_Tegra/" > /dev/null || exit
sudo ./apply_binaries.sh
popd > /dev/null || exit