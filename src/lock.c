/*************************************************************************
 * lock.c - 锁相关
 *************************************************************************/

#include "inc/lock.h"
#include "inc/cpu.h"
#include "inc/i_asm.h"
#include "inc/i_kernel.h"
#include "inc/i_lib.h"
#include "inc/mem.h"
#include "inc/types.h"

void initlock(struct spinlock* lock, char* name)
{
    lock->name = name;
    lock->locked = 0;
    lock->cpu = 0;
}

/**
 * 循环（旋转），直到获得锁
 */
void acquire(struct spinlock* lock)
{
    pushcli(); // disable interrupts to avoid deadlock.
    if (holding(lock)) {
        return;
    }

    while (xchg(&lock->locked, 1) != 0) // 获取锁
        ;

    __sync_synchronize(); // 防止编译优化

    // 记录锁信息
    lock->cpu = mycpu();
    getcallerpcs(&lock, lock->pcs);
}

/**
 * 释放锁
 */
void release(struct spinlock* lock)
{
    if (!holding(lock)) {
        return;
    }

    lock->pcs[0] = 0;
    lock->cpu = 0;

    __sync_synchronize();

    // Release the lock, equivalent to lock->locked = 0.
    // This code can't use a C assignment, since it might
    // not be atomic. A real OS would use C atomics here.
    asm volatile("movl $0, %0"
                 : "+m"(lock->locked)
                 :);

    popcli();
}

/**
 * 通过 %ebp 链，在 pcs[ ] 中记录当前调用栈
 */
void getcallerpcs(void* v, uint32_t pcs[])
{
    uint32_t* ebp;
    int i;

    ebp = (uint32_t*)v - 2;
    for (i = 0; i < 10; i++) {
        if (ebp == 0 || ebp < (uint32_t*)K_ADDR_BASE || ebp == (uint32_t*)0xffffffff)
            break;
        pcs[i] = ebp[1]; // saved %eip
        ebp = (uint32_t*)ebp[0]; // saved %ebp
    }
    for (; i < 10; i++)
        pcs[i] = 0;
}

/**
 * 检查该 cpu 是否已经持有该锁
 */
int holding(struct spinlock* lock)
{
    int ret;
    pushcli();
    ret = lock->locked && lock->cpu == mycpu();
    popcli();
    return ret;
}

void pushcli(void)
{
    int eflags;

    eflags = read_eflags();
    cli();
    if (mycpu()->ncli == 0)
        mycpu()->intena = eflags & FL_IF;
    mycpu()->ncli += 1;
}

void popcli(void)
{
    if (read_eflags() & FL_IF || --mycpu()->ncli < 0) {
        cprintf("popcli error: ");
        hlt();
    }
    if (mycpu()->ncli == 0 && mycpu()->intena)
        sti();
}
