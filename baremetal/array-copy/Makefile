# Copyright (c) 2022 Can Aknesil

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

TARGET = array-copy

CC = arm-none-eabi
#CC = arm-linux-gnueabi
#CC = arm-linux-gnueabihf

CC_LIB_DIR = /usr/lib/gcc/arm-none-eabi/9.2.1


SRCS = $(wildcard *.c)
OBJS = $(SRCS:.c=.o)
OBJS += $(CC_LIB_DIR)/libgcc.a

CC_FLAGS = -Wall -O1 -nostdlib -nostartfiles -ffreestanding -nostdinc
CC_FLAGS += -mfloat-abi=hard -mfpu=vfp
LD_FLAGS = -nostdlib -nostartfiles


all : $(TARGET).bin


%.o: %.c
	$(CC)-gcc $(CC_FLAGS) -c $< -o $@

start.o : start.s
	$(CC)-as start.s -o start.o

$(TARGET).bin : link.ld start.o $(OBJS)
	$(CC)-ld $(LD_FLAGS) start.o $(OBJS) -T link.ld -o $(TARGET).elf
	$(CC)-objdump -D $(TARGET).elf > $(TARGET).list
	$(CC)-objcopy $(TARGET).elf -O ihex $(TARGET).hex
	$(CC)-objcopy $(TARGET).elf -O binary $(TARGET).bin

clean :
	rm -f *.o
#	rm -f *.bin
#	rm -f *.hex
#	rm -f *.elf
	rm -f *.list
	rm -f *.img
	rm -f *.bc
	rm -f *.clang.s
