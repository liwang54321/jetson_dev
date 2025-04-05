# Jetson Dev Into Recovery
sudo reboot --force forced-recovery

# Fan Control
cat /sys/devices/pwm-fan/target_pwm
echo 255 > /sys/devices/pwm-fan/target_pwm

# Power Mode Config File /etc/nvpmodel.conf
# Set Full Power Mode 
sudo /usr/bin/jetson_clocks

# Query Power Mode
sudo nvpmodel --query verbose

# Set Full Power Mode
sudo nvpmodel -m 0


# Query System Status
tegrastats  
# RAM
# CPU
# EMC – external memory controller, bus%@MHz
# AVP – audio/video processor, ASIC Processor, Unit processor%@MHz
# VDE – videodecoder engine, Codec hevc  %MHz
# GR3D – GPU processor， %@MHz


# Backup SD Image
sudo parted -l
sudo dd if=/dev/sdX conv=sync,noerror bs=64K | gzip -c > ~/backup_image.img.gz
gunzip -c ~/backup_image.img.gz | dd of=/dev/sdX bs=64K

# Raw Image, System Image
dd if=/dev/mmcblk0p1 of=testimage.raw
./mksparse -v --fillpattern=0 ~/testimage.raw system.img


# Group Control  -- access to serial ports
sudo usermod -a -G dialout $USER

# Disable Uart Console
systemctl stop nvgetty
systemctl disable nvgetty
udevadm trigger

# v4l2 camera   sudo apt install v4l-utils
# List attached devices
v4l2-ctl --list-devices
# List all info about a given device
v4l2-ctl --all -d /dev/videoX
# List the cameras pixel formats, images sizes, frame rates
v4l2-ctl --list-formats-ext -d /dev/videoX



# Udev -> /usr/lib/udev
sudo cp /opt/nvidia/jetson-gpio/etc/99-gpio.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger
