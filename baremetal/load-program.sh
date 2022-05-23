#! /bin/bash

TTY_DEV=$1
BAUD_RATE=115200
IHEX=$2

if [ ! -f "$IHEX" ]
then
    echo "$IHEX program file does not exist !"
    exit
fi

stty -F $TTY_DEV $BAUD_RATE
echo Sending binary
cat $IHEX > $TTY_DEV
echo -n g > $TTY_DEV
#sleep 1 # Wait for bootloader to finish execution.

#echo Listening...
#cat $TTY_DEV
#screen $TTY_DEV $BAUD_RATE
#picocom $TTY_DEV --baud $BAUD_RATE
