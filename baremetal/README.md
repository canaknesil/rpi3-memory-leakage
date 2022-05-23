`rpi3-boot-files` directory contains files required to boot a program
from micro-SD card. They are put at SD-card root together with the
kernel image.

`bootloader` directory contains a simple bootloader program that sets
up UART communication and reads a program in Intel HEX format followed
by character 'g', loads it in memory, and jumps to it.

Bootloader is taken from
[github.com/dwelch67/raspberrypi](https://github.com/dwelch67/raspberrypi).

Workflow:
* Create MBR partition table on micro-SD card with 1 partition, format
  the partition as FAT32.
* Put content of `rpi3-boot-files` and `bootloader/kernel7.img` to
  root directory of the SD-card. 
* Connect RaspberryPi to the computer with Serial debug cable.
* Power on the RaspberryPi and run `load-program.sh` with the TTY
  device file of the serial debugger (ex. /dev/ttyUSB0) and the
  program formatted in Intel HEX format. 



