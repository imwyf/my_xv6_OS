.text
.globl    _start

_start:
  mov $0xe, %ah
  int $0x10
  hlt
