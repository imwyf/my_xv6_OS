/*************************************************************************
 * main.c - 负责内核的各项功能的初始化
 *************************************************************************/
#include "inc/i_asm.h"
#include "inc/i_kernel.h"
#include "inc/i_lib.h"
#include "inc/mem.h"
#include "inc/proc.h"
#include "inc/types.h"

extern pde_t* kernel_pgdir;

pde_t entry_pgdir[];
/**
 * 临时页表，用于内核启动时直接映射物理内存到虚拟内存（4MB）：[0x80000000-0x80400000] -> [0x00000000-0x00400000]
 * __aligned__：舍入到最接近的 PGSIZE 的倍数
 */
__attribute__((__aligned__(PGSIZE)))
pde_t entry_pgdir[NPDENTRIES]
    = {
          [0] = (0) | PTE_P | PTE_W | PTE_PS,
          [K_ADDR_BASE >>
              PDXSHIFT]
          = (0) | PTE_P | PTE_W | PTE_PS,
      };

void use_lock();

int main()
{
    cons_init();
    cprintf("\n");
    cprintf("------> Hello, OS World!\n");
    kmem_init(); // 内存管理初始化
    cprintf("------> kmem_init() finish!\n");
    conf_mcpu();
    cprintf("------> conf_mcpu() finish!\n");
    conf_gdt();
    cprintf("------> conf_gdt() finish!\n");
    interrupt_init();
    cprintf("------> interrupt_init() finish!\n");
    proc_init();
    cprintf("------> proc_init() finish!\n");
    hlt();
}

void use_lock()
{
    cons_uselock();
    kmem_uselock();
}
