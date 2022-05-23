#include "peripheral.h"
#include "gpio.h"


#define PBASE PERIPHERAL_BASE
#define GPFSEL0         ((volatile unsigned int*)(PBASE+0x00200000))
#define GPFSEL1         ((volatile unsigned int*)(PBASE+0x00200004))
#define GPFSEL2         ((volatile unsigned int*)(PBASE+0x00200008))
#define GPFSEL3         ((volatile unsigned int*)(PBASE+0x0020000C))
#define GPFSEL4         ((volatile unsigned int*)(PBASE+0x00200010))
#define GPFSEL5         ((volatile unsigned int*)(PBASE+0x00200014))
#define GPSET0          ((volatile unsigned int*)(PBASE+0x0020001C))
#define GPSET1          ((volatile unsigned int*)(PBASE+0x00200020))
#define GPCLR0          ((volatile unsigned int*)(PBASE+0x00200028))
#define GPLEV0          ((volatile unsigned int*)(PBASE+0x00200034))
#define GPLEV1          ((volatile unsigned int*)(PBASE+0x00200038))
#define GPEDS0          ((volatile unsigned int*)(PBASE+0x00200040))
#define GPEDS1          ((volatile unsigned int*)(PBASE+0x00200044))
#define GPHEN0          ((volatile unsigned int*)(PBASE+0x00200064))
#define GPHEN1          ((volatile unsigned int*)(PBASE+0x00200068))
#define GPPUD           ((volatile unsigned int*)(PBASE+0x00200094))
#define GPPUDCLK0       ((volatile unsigned int*)(PBASE+0x00200098))
#define GPPUDCLK1       ((volatile unsigned int*)(PBASE+0x0020009C))


static volatile unsigned int *gpio = GPFSEL0; /* GPIO controller */


// GPIO setup macros. Always use INP_GPIO(x) before using OUT_GPIO(x) or SET_GPIO_ALT(x,y)
#define INP_GPIO(g) *(gpio+((g)/10)) &= ~(7<<(((g)%10)*3))
#define OUT_GPIO(g) *(gpio+((g)/10)) |=  (1<<(((g)%10)*3))
#define SET_GPIO_ALT(g, a) *(gpio+(((g)/10))) |= (((a)<=3?(a)+4:(a)==4?3:2)<<(((g)%10)*3))

#define GPIO_SET *(gpio+7)  // sets   bits which are 1 ignores bits which are 0
#define GPIO_CLR *(gpio+10) // clears bits which are 1 ignores bits which are 0

#define GET_GPIO(g) (*(gpio+13)&(1<<g)) // 0 if LOW, (1<<g) if HIGH

#define GPIO_PULL *(gpio+37) // Pull up/pull down
#define GPIO_PULLCLK0 *(gpio+38) // Pull up/pull down clock


void gpio_set_direction(int pin, int direction)
{
  INP_GPIO(pin);
  if (direction == GPIO_OUT) {
    OUT_GPIO(pin);
  }
}

void gpio_write(int pin, int value)
{
  if (value == 0)
    GPIO_CLR = 1 << pin;
  else
    GPIO_SET = 1 << pin;
}

int gpio_read(int pin)
{
  if (GET_GPIO(pin))
    return 1;
  else
    return 0;
}

