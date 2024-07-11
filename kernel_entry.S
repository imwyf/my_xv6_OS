# *************************************************************************
# * kernel_entry.S - 内核的入口，负责开启分页机制，然后跳到 main 以实现系统初始化
# *************************************************************************

#include <inc/mmu.h>

.text
.globl _start
_start = V2P_WO(kernel_entry) 
# 我们还没有开启分页，而内核代码实际被存放在物理地址 0x00100000 处，因此手动将虚拟地址转换为其对应的物理地址：即 0x80100000 -> 0x00100000

.globl kernel_entry
kernel_entry:
# 固定页表大小 
  movl    %cr4, %eax
  orl     $(CR4_PSE), %eax                  # 4MB/页
  movl    %eax, %cr4
  # 将 entry_pgdir 的物理地址载入 cr3 寄存器并开启分页
  movl    $(V2P_WO(entry_pgdir)), %eax
  movl    %eax, %cr3
  movl    %cr0, %eax
  orl     $(CR0_PG|CR0_WP), %eax
  movl    %eax, %cr0

# entrypgdir 直接将虚拟地址前4Mb映射到物理地址前4Mb

# 现在的栈是bootloader设置的不处在内核中，因此把栈设为内核栈
  movl $(stack + KSTACKSIZE), %esp

# 不能用 call，其使用的是相对寻址，所以 eip 仍然会在低地址处偏移来寻址，而此时 eip 指向的是低的虚拟地址，因此通过 jmp 重置 eip 以指向高地址处
  mov $main, %eax
  jmp *%eax

.comm stack, KSTACKSIZE