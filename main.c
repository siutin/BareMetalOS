#include "main.h"

int main() {
  printExample();
  return 0;
}

void printExample() {
  *((int*)0xb8000) = 0x0e650e48;
  *((int*)0xb8004) = 0x0e6c0e6c;
  *((int*)0xb8008) = 0x0e200e6f;
  *((int*)0xb800c) = 0x0e6f0e57;
  *((int*)0xb8010) = 0x0e6c0e72;
  *((int*)0xb8014) = 0x00000e64;
}