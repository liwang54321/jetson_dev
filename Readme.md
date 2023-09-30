# Jetson Docs
- Jetson Doc
https://docs.nvidia.com/jetson/archives/r35.4.1/DeveloperGuide/index.html

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

- JetPack Download
https://developer.nvidia.com/embedded/jetpack

# TODO
- Add SD Card Image partitions
- Add minimal rootfs 
    - https://docs.nvidia.com/jetson/archives/r35.4.1/DeveloperGuide/text/SD/StorageOptimization.html
    - https://nvidia-ai-iot.github.io/jetson-min-disk/

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