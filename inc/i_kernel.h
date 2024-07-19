#ifndef _I_KERNEL_H_
#define _I_KERNEL_H_

/*************************************************************************
 * i_kernel.h - 声明内核函数接口
 *************************************************************************/

/* kernel_mem.c */
void kmem_init();

/* mcpu.c */
void mcpu_init();
struct cpu* mycpu(void);
int cpuid();

/* apic.c */
int lapicid(void);

#endif /* !_I_KERNEL_H_ */
