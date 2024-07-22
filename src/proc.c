/*************************************************************************
 * proc.c - 进程调度相关
 *************************************************************************/

#include "inc/proc.h"
#include "inc/cpu.h"
#include "inc/i_kernel.h"
#include "inc/i_lib.h"
#include "inc/lock.h"
#include "inc/types.h"

struct {
    struct spinlock lock;
    int use_lock;
    int next_pid; // 下一个新进程的 pid
    struct proc procs[MAX_PROC];
} proc_table;

static struct proc* proc_userinit;

extern void forkret(void);
extern void trapret(void);

// static void wakeup1(void* chan);

/**
 * 获取当前进程
 */
struct proc* myproc(void)
{
    struct cpu* cpu;
    struct proc* proc;
    pushcli();
    cpu = mycpu();
    proc = cpu->proc;
    popcli();
    return proc;
}

void proc_init()
{
    initlock(&proc_table.lock, "proc_table");
    proc_table.use_lock = 0;
    proc_table.next_pid = 1;
    for (struct proc* p = proc_table.procs; p < &proc_table.procs[MAX_PROC]; p++) {
        p->state = DIED;
    }
}

void proc_uselock() { proc_table.use_lock = 1; }

// static struct proc* birthproc(void)
// {
//     struct proc* p;
//     char* sp;

//     acquire(&proc_table.lock);

//     for (p = proc_table.procs; p < &proc_table.procs[MAX_PROC]; p++)
//         if (p->state == DIED) {
//             p->pid = proc_table.next_pid;
//             proc_table.next_pid++;

//             release(&proc_table.lock);

//             // Allocate kernel stack.
//             if ((p->kstack = kmem_alloc()) == 0) {
//                 p->state = DIED;
//                 return 0;
//             }
//             sp = p->kstack + K_STACKSIZE;

//             // Leave room for trap frame.
//             sp -= sizeof *p->tf;
//             p->tf = (struct trapframe*)sp;

//             // Set up new context to start executing at forkret,
//             // which returns to trapret.
//             sp -= 4;
//             *(uint32_t*)sp = (uint32_t)trapret;

//             sp -= sizeof *p->context;
//             p->context = (struct context*)sp;
//             memset(p->context, 0, sizeof *p->context);
//             p->context->eip = (uint32_t)forkret;

//             return p;
//         }

//     release(&proc_table.lock);
//     return NULL;
// }

// int fork(void)
// {
//     int i, pid;
//     struct proc* np;
//     struct proc* curproc = myproc();

//     // Allocate process.
//     if ((np = birthproc()) == 0) {
//         return -1;
//     }

//     // Copy process state from proc.
//     if ((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0) {
//         kfree(np->kstack);
//         np->kstack = 0;
//         np->state = DIED;
//         return -1;
//     }
//     np->sz = curproc->sz;
//     np->parent = curproc;
//     *np->tf = *curproc->tf;

//     // Clear %eax so that fork returns 0 in the child.
//     np->tf->eax = 0;

//     for (i = 0; i < NOFILE; i++)
//         if (curproc->ofile[i])
//             np->ofile[i] = filedup(curproc->ofile[i]);
//     np->cwd = idup(curproc->cwd);

//     safestrcpy(np->name, curproc->name, sizeof(curproc->name));

//     pid = np->pid;

//     acquire(&ptable.lock);

//     np->state = RUNNABLE;

//     release(&ptable.lock);

//     return pid;
// }
