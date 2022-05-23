#include "gpio.h"


#define TRIGGER_PIN 4


// 1024 is the largest that oscilloscope can run a script (because of an insufficient memory error)

#define ARRAY_SIZE 1024 // multiple of 256


void array_copy(int *dst, int *src, int size)
{
  for (int i=0; i<size; i++) {
    dst[i] = src[i];
  }
}


void init_array_all_values_for_byte(int *arr, int size, int byte)
{
  int class_size = size / 256;

  for (int i=0; i<256; i++) {
    for (int j=0; j<class_size; j++) {
      arr[i * class_size + j] = i << (8 * byte);
    }
  }
}


// https://en.wikipedia.org/wiki/Linear_congruential_generator
int randint()
{
  static int seed = 123456789;
  static int a = 1103515245;
  static int c = 12345;
  static int m = 1 << 31;
  
  seed = (a * seed + c) % m;
  return seed;
}


void init_array_all_values_for_byte__others_random(int *arr, int size, int byte)
{
  int class_size = size / 256;

  for (int i=0; i<256; i++) {
    for (int j=0; j<class_size; j++) {
      int n = i << (8 * byte);
      n += randint() & ~(0xff << (8 * byte));
	
      arr[i * class_size + j] = n;
    }
  }
}


int main()
{
  gpio_set_direction(TRIGGER_PIN, GPIO_OUT);
  gpio_write(TRIGGER_PIN, 0);

  int src[ARRAY_SIZE];
  int dst[ARRAY_SIZE];
  
  init_array_all_values_for_byte(src, ARRAY_SIZE, 0);

  while (1) {
    //init_array_all_values_for_byte__others_random(src, ARRAY_SIZE, 3);
    gpio_write(TRIGGER_PIN, 1);
    array_copy(dst, src, ARRAY_SIZE);
    gpio_write(TRIGGER_PIN, 0);
  }
    
  return 0;
}

