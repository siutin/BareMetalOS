int main() {
  *((int*)0xb8000)=0x0e650e48;
  *((int*)0xb8004)=0x0e6c0e6c;
  *((int*)0xb8008)=0x00000e6f;
  return 0;
}