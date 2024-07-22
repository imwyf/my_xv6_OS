#ifndef _I_KERNEL_H_
#define _I_KERNEL_H_

/*************************************************************************
 * i_kernel.h - 声明内核函数接口
 *************************************************************************/

#include "lock.h"
#include "types.h"

/* kernel_mem.c */
void kmem_init();
void kmem_uselock();
char* kmem_alloc(void);
void kmem_free(char* vaddr);
void conf_gdt();

/* cpu.c */
void conf_mcpu();
struct cpu* mycpu(void);
int cpuid();

/* proc.c */
void proc_init();
void proc_uselock();
struct proc* myproc(void);

/* interrupt.c */
void interrupt_init();
int lapic_id(void);

/* lock.c */
void initlock(struct spinlock* lk, char* name);
void acquire(struct spinlock* lk);
void release(struct spinlock* lk);
void getcallerpcs(void* v, uint32_t pcs[]);
int holding(struct spinlock* lock);
void pushcli(void);
void popcli(void);

#endif /* !_I_KERNEL_H_ */
