
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <kernel_entry>:
# 我们还没有开启分页，而内核代码实际被存放在物理地址 0x00100000 处，因此手动将虚拟地址转换为其对应的物理地址：即 0x80100000 -> 0x00100000

.globl kernel_entry
kernel_entry:
# 固定页表大小 
  movl    %cr4, %eax
80100000:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax                  # 4MB/页
80100003:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100006:	0f 22 e0             	mov    %eax,%cr4
  # 将 entrypgdir 的物理地址载入 cr3 寄存器并开启分页
  movl    $(V2P_WO(entrypgdir)), %eax
80100009:	b8 00 10 10 00       	mov    $0x101000,%eax
  movl    %eax, %cr3
8010000e:	0f 22 d8             	mov    %eax,%cr3
  movl    %cr0, %eax
80100011:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100014:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100019:	0f 22 c0             	mov    %eax,%cr0

# entrypgdir 直接将虚拟地址前4Mb映射到物理地址前4Mb

# 现在的栈是bootloader设置的不处在内核中，因此把栈设为内核栈
  movl $(stack + KSTACKSIZE), %esp
8010001c:	bc 00 30 10 80       	mov    $0x80103000,%esp

# 不能用 call，其使用的是相对寻址，所以 eip 仍然会在低地址处偏移来寻址，而此时 eip 指向的是低的虚拟地址，因此通过 jmp 重置 eip 以指向高地址处
  mov $main, %eax
80100021:	b8 28 00 10 80       	mov    $0x80100028,%eax
  jmp *%eax
80100026:	ff e0                	jmp    *%eax

80100028 <main>:
#include "inc/mmu.h"
int main()
{
    
}
80100028:	b8 00 00 00 00       	mov    $0x0,%eax
8010002d:	c3                   	ret    
