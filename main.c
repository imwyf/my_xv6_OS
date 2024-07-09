#include "inc/mmu.h"
int main()
{
    
}

pde_t entrypgdir[];
/**
 * 临时页表，用于内核启动时直接映射物理内存到虚拟内存（4MB）：[0x80000000-0x80400000] -> [0x00000000-0x00400000]
 * __aligned__：舍入到最接近的 PGSIZE 的倍数
 */
__attribute__((__aligned__(PGSIZE)))
pde_t entrypgdir[NPDENTRIES]
    = {
          [0] = (0) | PTE_P | PTE_W | PTE_PS,
          [KERNBASE >>
              PDXSHIFT]
          = (0) | PTE_P | PTE_W | PTE_PS,
      };