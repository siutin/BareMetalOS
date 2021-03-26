#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "multiboot2.h"
#include "vga.h"
#include "pic.h"

void keyboard_handler_int();

/*  Convert the integer D to a string and save the string in BUF. If
   BASE is equal to ’d’, interpret that D is decimal, and if BASE is
   equal to ’x’, interpret that D is hexadecimal. */
static void
itoa (char *buf, int base, int d)
{
  char *p = buf;
  char *p1, *p2;
  unsigned long ud = d;
  int divisor = 10;
  
  /*  If %d is specified and D is minus, put ‘-’ in the head. */
  if (base == 'd' && d < 0)
    {
      *p++ = '-';
      buf++;
      ud = -d;
    }
  else if (base == 'x')
    divisor = 16;

  /*  Divide UD by DIVISOR until UD == 0. */
  do
    {
      int remainder = ud % divisor;
      
      *p++ = (remainder < 10) ? remainder + '0' : remainder + 'a' - 10;
    }
  while (ud /= divisor);

  /*  Terminate BUF. */
  *p = 0;
  
  /*  Reverse BUF. */
  p1 = buf;
  p2 = p - 1;
  while (p1 < p2)
    {
      char tmp = *p1;
      *p1 = *p2;
      *p2 = tmp;
      p1++;
      p2--;
    }
}

/*  Format a string and print it on the screen, just like the libc
   function printf. */
void
printf(const char *format, ...)
{
  char **arg = (char **) &format;
  int c;
  char buf[20];

  arg++;
  
  while ((c = *format++) != 0)
    {
      if (c != '%')
        terminal_putchar (c);
      else
        {
          char *p, *p2;
          int pad0 = 0, pad = 0;
          
          c = *format++;
          if (c == '0')
            {
              pad0 = 1;
              c = *format++;
            }

          if (c >= '0' && c <= '9')
            {
              pad = c - '0';
              c = *format++;
            }

          switch (c)
            {
            case 'd':
            case 'u':
            case 'x':
              itoa (buf, c, *((int *) arg++));
              p = buf;
              goto string;
              break;

            case 's':
              p = *arg++;
              if (! p)
                p = "(null)";

            string:
              for (p2 = p; *p2; p2++);
              for (; p2 < p + pad; p2++)
                terminal_putchar (pad0 ? '0' : ' ');
              while (*p)
                terminal_putchar (*p++);
              break;

            default:
              terminal_putchar (*((int *) arg++));
              break;
            }
        }
    }
}

void print_multiboot_struct(unsigned int addr) {
  struct multiboot_tag *tag;
  for (tag = (struct multiboot_tag *) (addr + 8);
       tag->type != MULTIBOOT_TAG_TYPE_END;
       tag = (struct multiboot_tag *) ((multiboot_uint8_t *) tag 
                                       + ((tag->size + 7) & ~7)))
    {
      printf("Tag 0x%x, Size 0x%x\n", tag->type, tag->size);
      switch (tag->type)
        {
        case MULTIBOOT_TAG_TYPE_CMDLINE:
          printf("Command line = %s\n",
                  ((struct multiboot_tag_string *) tag)->string);
          break;
        case MULTIBOOT_TAG_TYPE_BOOT_LOADER_NAME:
          printf("Boot loader name = %s\n",
                  ((struct multiboot_tag_string *) tag)->string);
          break;
        case MULTIBOOT_TAG_TYPE_MODULE:
          printf("Module at 0x%x-0x%x. Command line %s\n",
                  ((struct multiboot_tag_module *) tag)->mod_start,
                  ((struct multiboot_tag_module *) tag)->mod_end,
                  ((struct multiboot_tag_module *) tag)->cmdline);
          break;
        case MULTIBOOT_TAG_TYPE_BASIC_MEMINFO:
          printf("mem_lower = %uKB, mem_upper = %uKB\n",
                  ((struct multiboot_tag_basic_meminfo *) tag)->mem_lower,
                  ((struct multiboot_tag_basic_meminfo *) tag)->mem_upper);
          break;
        case MULTIBOOT_TAG_TYPE_BOOTDEV:
          printf("Boot device 0x%x,%u,%u\n",
                  ((struct multiboot_tag_bootdev *) tag)->biosdev,
                  ((struct multiboot_tag_bootdev *) tag)->slice,
                  ((struct multiboot_tag_bootdev *) tag)->part);
          break;
        case MULTIBOOT_TAG_TYPE_MMAP:
          {
            multiboot_memory_map_t *mmap;

            printf("mmap\n");
      
            for (mmap = ((struct multiboot_tag_mmap *) tag)->entries;
                 (multiboot_uint8_t *) mmap 
                   < (multiboot_uint8_t *) tag + tag->size;
                 mmap = (multiboot_memory_map_t *) 
                   ((unsigned long) mmap
                    + ((struct multiboot_tag_mmap *) tag)->entry_size))
              printf(" base_addr = 0x%x%x,"
                      " length = 0x%x%x, type = 0x%x\n",
                      (unsigned) (mmap->addr >> 32),
                      (unsigned) (mmap->addr & 0xffffffff),
                      (unsigned) (mmap->len >> 32),
                      (unsigned) (mmap->len & 0xffffffff),
                      (unsigned) mmap->type);
          }
          break;
        // case MULTIBOOT_TAG_TYPE_FRAMEBUFFER:
        //   {
        //     multiboot_uint32_t color;
        //     unsigned i;
        //     struct multiboot_tag_framebuffer *tagfb
        //       = (struct multiboot_tag_framebuffer *) tag;
        //     void *fb = (void *) (unsigned long) tagfb->common.framebuffer_addr;

        //     switch (tagfb->common.framebuffer_type)
        //       {
        //       case MULTIBOOT_FRAMEBUFFER_TYPE_INDEXED:
        //         {
        //           unsigned best_distance, distance;
        //           struct multiboot_color *palette;
            
        //           palette = tagfb->framebuffer_palette;

        //           color = 0;
        //           best_distance = 4*256*256;
            
        //           for (i = 0; i < tagfb->framebuffer_palette_num_colors; i++)
        //             {
        //               distance = (0xff - palette[i].blue) 
        //                 * (0xff - palette[i].blue)
        //                 + palette[i].red * palette[i].red
        //                 + palette[i].green * palette[i].green;
        //               if (distance < best_distance)
        //                 {
        //                   color = i;
        //                   best_distance = distance;
        //                 }
        //             }
        //         }
        //         break;

        //       case MULTIBOOT_FRAMEBUFFER_TYPE_RGB:
        //         color = ((1 << tagfb->framebuffer_blue_mask_size) - 1) 
        //           << tagfb->framebuffer_blue_field_position;
        //         break;

        //       case MULTIBOOT_FRAMEBUFFER_TYPE_EGA_TEXT:
        //         color = '\\' | 0x0100;
        //         break;

        //       default:
        //         color = 0xffffffff;
        //         break;
        //       }
            
        //     for (i = 0; i < tagfb->common.framebuffer_width
        //            && i < tagfb->common.framebuffer_height; i++)
        //       {
        //         switch (tagfb->common.framebuffer_bpp)
        //           {
        //           case 8:
        //             {
        //               multiboot_uint8_t *pixel = fb
        //                 + tagfb->common.framebuffer_pitch * i + i;
        //               *pixel = color;
        //             }
        //             break;
        //           case 15:
        //           case 16:
        //             {
        //               multiboot_uint16_t *pixel
        //                 = fb + tagfb->common.framebuffer_pitch * i + 2 * i;
        //               *pixel = color;
        //             }
        //             break;
        //           case 24:
        //             {
        //               multiboot_uint32_t *pixel
        //                 = fb + tagfb->common.framebuffer_pitch * i + 3 * i;
        //               *pixel = (color & 0xffffff) | (*pixel & 0xff000000);
        //             }
        //             break;

        //           case 32:
        //             {
        //               multiboot_uint32_t *pixel
        //                 = fb + tagfb->common.framebuffer_pitch * i + 4 * i;
        //               *pixel = color;
        //             }
        //             break;
        //           }
        //       }
        //     break;
        //   }

        }
    }
  tag = (struct multiboot_tag *) ((multiboot_uint8_t *) tag 
                                  + ((tag->size + 7) & ~7));
  printf("Total mbi size 0x%x\n", (unsigned) tag - addr);
}