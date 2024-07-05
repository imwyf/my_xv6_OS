
kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start>:
.text
.globl    _start

_start:
  mov $0xe, %ah
f0100000:	b4 0e                	mov    $0xe,%ah
  int $0x10
f0100002:	cd 10                	int    $0x10
  hlt
f0100004:	f4                   	hlt    
