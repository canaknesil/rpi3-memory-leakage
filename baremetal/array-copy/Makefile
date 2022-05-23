
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
