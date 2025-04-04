## Jetson Sdk Version Map
- JetPack 6.2 -- L4t r36.4.3

## Jetson Documents

- Jetson Developer Guide
    - [r35.4.1](https://docs.nvidia.com/jetson/archives/r35.4.1/DeveloperGuide/index.html)
    - [r36.4.3](https://docs.nvidia.com/jetson/archives/r36.4.3/DeveloperGuide/)
- [Jetson MultiMedia API Documents](https://docs.nvidia.com/jetson/l4t-multimedia/index.html)
- [Jetson VPI Documents](https://docs.nvidia.com/vpi/index.html)
- [Jetson Software Documentation Center](https://docs.nvidia.com/jetson/index.html)
- [Jetson Sensor Processing Engine (SPE) Developer Guide](https://docs.nvidia.com/jetson/archives/r36.4.3/spe/index.html)
- [Jetson Linux Download](https://developer.nvidia.com/embedded/jetson-linux)
- [Jetson Download Center](https://developer.nvidia.com/embedded/downloads)
- [JetPack SDK](https://developer.nvidia.com/embedded/jetpack)
- [JetPack SDK Documentation](https://docs.nvidia.com/jetson/jetpack/index.html)
- [Jetson Archives](https://docs.nvidia.com/jetson/archives/)
- [Jetson Repo Download](https://repo.download.nvidia.com/jetson/)

## TODO

- Add Cross Compiler Envriment

## Device Usb Num

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
