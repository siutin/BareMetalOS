#include "vga_global.h"
#include "vga.h"

uint8_t vga_entry_color(enum vga_color fg, enum vga_color bg)
{
  return fg | bg << 4;
}

uint16_t vga_entry(unsigned char uc, uint8_t color)
{
  return (uint16_t) uc | (uint16_t) color << 8;
}

extern void terminal_initialize(void)
{
  terminal_row = 0;
  terminal_column = 0;
  terminal_color = vga_entry_color(VGA_COLOR_LIGHT_BROWN, VGA_COLOR_BLACK);
  terminal_buffer = (uint16_t*) 0xB8000;
  for (size_t y = 0; y < VGA_HEIGHT; y++) {
    for (size_t x = 0; x < VGA_WIDTH; x++) {
      const size_t index = y * VGA_WIDTH + x;
      terminal_buffer[index] = vga_entry(' ', terminal_color);
    }
  }
}

extern void terminal_setpos(size_t x, size_t y) {
  terminal_row = y;
  terminal_column = x;
}

void terminal_setcolor(uint8_t color)
{
  terminal_color = color;
}

void terminal_putentryat(char c, uint8_t color, size_t x, size_t y)
{
  const size_t index = y * VGA_WIDTH + x;
  terminal_buffer[index] = vga_entry(c, color);
}

extern void terminal_putchar(char c)
{
  if (c == '\n' || c == '\r') {
    terminal_column = 0;
    if (++terminal_row >= VGA_HEIGHT)
      terminal_row = 0;
  } else if (c == '\b')  {
    if (terminal_column == 0 && terminal_row > 0) {
      terminal_row--;
      terminal_column = VGA_WIDTH;
    } else if (terminal_column > 0) {
      terminal_column--;
    }
    terminal_putentryat(' ', terminal_color, terminal_column, terminal_row);
  } else {
    terminal_putentryat(c, terminal_color, terminal_column, terminal_row);
    if (++terminal_column >= VGA_WIDTH) {
      terminal_column = 0;
      if (++terminal_row >= VGA_HEIGHT)
        terminal_row = 0;
    }
  }
}