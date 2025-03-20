# Jetson Docs

- Jetson Developer Guide
    - r35.4.1
        https://docs.nvidia.com/jetson/archives/r35.4.1/DeveloperGuide/index.html
    - r36.4.3
        https://docs.nvidia.com/jetson/archives/r36.4.3/DeveloperGuide/
- JetPack Doc
  https://docs.nvidia.com/jetson/jetpack/index.html
- Jetson API Documents
  https://docs.nvidia.com/jetson/l4t-multimedia/index.html
- Jetson Soft Documents
  https://docs.nvidia.com/jetson/index.html
- Jetson VPI Documents
  https://docs.nvidia.com/vpi/index.html
- Jetson Linux Download
  https://developer.nvidia.com/embedded/jetson-linux
- Jetson Download Center
  https://developer.nvidia.com/embedded/downloads
- JetPack SDK
  https://developer.nvidia.com/embedded/jetpack

## Download SDK

- jetpack 6.2
  ```bash
  https://developer.download.nvidia.cn/embedded/L4T/r36_Release_v4.3/sources/public_sources.tbz2
  https://developer.download.nvidia.cn/embedded/L4T/r36_Release_v4.3/release/Jetson_Linux_R36.4.3_aarch64.tbz2
  https://developer.download.nvidia.cn/embedded/L4T/r36_Release_v4.3/release/Tegra_Linux_Sample-Root-Filesystem_R36.4.3_aarch64.tbz2
  https://developer.download.nvidia.cn/embedded/L4T/r36_Release_v4.3/release/WebRTC_R36.4.3_aarch64.tbz2
  https://developer.nvidia.com/embedded/L4T/r36_release_v4.3/Release/Jetson_Multimedia_API_r36.4.3_aarch64.tbz2
  https://developer.nvidia.com/downloads/embedded/l4t/r36_release_v3.0/toolchain/aarch64--glibc--stable-2022.08-1.tar.bz2
  ```

# TODO

- Add Cross Compiler Envriment

# Device Usb Num

```bash
lsusb
Bus <bbb> Device <ddd>: ID 0955: <nnnn> Nvidia Corp.
Where:
= <bbb> is any three-digit number
= <ddd> is any three-digit number
= <nnnn> is a four-digit number that represents the type of your Jetson module:
    7023 for Jetson AGX Orin                    (P3701-0000 with 32GB)
    7023 for Jetson AGX Orin                    (P3701-0005 with 64GB)
    7023 for Jetson AGX Orin Industrial         (P3701-0008 with 64GB)
    7223 for Jetson AGX Orin                    (P3701-0004 with 32GB)
    7323 for Jetson Orin NX                     (P3767-0000 with 16GB)
    7423 for Jetson Orin NX                     (P3767-0001 with 8GB)
    7523 for Jetson Orin Nano                   (P3767-0003 and P3767-0005 with 8GB)
    7623 for Jetson Orin Nano                   (P3767-0004 with 4GB)
    7019 for Jetson AGX Xavier                  (P2888-0001 with 16GB)
    7019 for Jetson AGX Xavier                  (P2888-0004 with 32GB)
    7019 for Jetson AGX Xavier                  (P2888-0005 with 64GB)
    7019 for Jetson AGX Xavier Industrial       (P2888-0008)
    7e19 for Jetson Xavier NX                   (P3668)
```
