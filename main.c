// original from https://wiki.osdev.org/Bare_Bones

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include "main.h"

int main() {
  /* Initialize terminal interface */
  terminal_initialize();

  terminal_writestring("ABCDEFGHIJKLMNOPQRSTUVWXYZ 1234567890\n");
  terminal_writestring("!@#$%^&*()_+{}:\"<>?-=[];',./\n");
  return 0;
}