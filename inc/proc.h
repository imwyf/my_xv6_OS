
#include "inc/types.h"

// Task state segment（TSS）：操作系统在进行进程切换时保存原进程现场信息的段，它保存 CPU 中各寄存器的值到内存中
struct taskstate {
    uint32_t link; // Old ts selector
    uint32_t esp0; // Stack pointers and segment selectors
    uint16_t ss0; //   after an increase in privilege level
    uint16_t padding1;
    uint32_t* esp1;
    uint16_t ss1;
    uint16_t padding2;
    uint32_t* esp2;
    uint16_t ss2;
    uint16_t padding3;
    void* cr3; // Page directory base
    uint32_t* eip; // Saved state from last task switch
    uint32_t eflags;
    uint32_t eax; // More saved state (registers)
    uint32_t ecx;
    uint32_t edx;
    uint32_t ebx;
    uint32_t* esp;
    uint32_t* ebp;
    uint32_t esi;
    uint32_t edi;
    uint16_t es; // Even more saved state (segment selectors)
    uint16_t padding4;
    uint16_t cs;
    uint16_t padding5;
    uint16_t ss;
    uint16_t padding6;
    uint16_t ds;
    uint16_t padding7;
    uint16_t fs;
    uint16_t padding8;
    uint16_t gs;
    uint16_t padding9;
    uint16_t ldt;
    uint16_t padding10;
    uint16_t t; // Trap on task switch
    uint16_t iomb; // I/O map base address
};

// PAGEBREAK: 17
//  Saved registers for kernel context switches.
//  Don't need to save all the segment registers (%cs, etc),
//  because they are constant across kernel contexts.
//  Don't need to save %eax, %ecx, %edx, because the
//  x86 convention is that the caller has saved them.
//  Contexts are stored at the bottom of the stack they
//  describe; the stack pointer is the address of the context.
//  The layout of the context matches the layout of the stack in swtch.S
//  at the "Switch stacks" comment. Switch doesn't save eip explicitly,
//  but it is on the stack and allocproc() manipulates it.
struct context {
    uint32_t edi;
    uint32_t esi;
    uint32_t ebx;
    uint32_t ebp;
    uint32_t eip;
};

enum procstate { UNUSED,
    EMBRYO,
    SLEEPING,
    RUNNABLE,
    RUNNING,
    ZOMBIE };

// 一个进程由一个 proc 结构描述
struct proc {
    uint32_t sz; // Size of process memory (bytes)
    pde_t* pgdir; // 进程的页表地址
    char* kstack; // Bottom of kernel stack for this process
    enum procstate state; // 进程的状态机
    int pid; // 进程id
    struct proc* parent; // 父进程指针
    struct trapframe* tf; // 对于当前系统调用的陷阱页指针
    struct context* context; // swtch() here to run process
    void* chan; // If non-zero, sleeping on chan
    int killed; // If non-zero, have been killed
    // struct file *ofile[NOFILE];  // Open files
    // struct inode* cwd; // Current directory
    char name[16]; // Process name (debugging)
};

// Process memory is laid out contiguously, low addresses first:
//   text
//   original data and bss
//   fixed-size stack
//   expandable heap
