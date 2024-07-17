/*************************************************************************
 * kernel_mem.c - 负责内存分配、地址映射、页表建立等初始化工作
 *************************************************************************/
// TODO:加锁
#include "inc/mmu.h"
#include "inc/proc.h"
#include "inc/types.h"
#include <inc/lib.h>
// #include "inc/lock.h"

extern char* end; // 内核的 ELF 文件结束后的第一个虚拟地址，定义于 kernel.ld
extern char* edata; // 数据段结尾
extern char* data; // 数据段开始

pde_t* kernel_pgdir; // 内核页表(一级页表的基址)

/* 下面是本文件使用的函数的声明 */
void kmem_free_pages(void* start, void* end);
void kmem_free(char* v);
pde_t* set_kernel_pgdir(void);
void switch_pgdir(struct proc* p);

/**
 * 初始化内存分配器、页表
 */
void kmem_init()
{
    // initlock(&kmem.lock, "kmem");
    // kmem.use_lock = 0;
    memset(edata, 0, end - edata); // 初始化数据段保证静态变量初始化为0
    kmem_free_pages(end, K_P2V(P_ADDR_LOWMEM)); // 释放[end, 4MB]部分给新的内核页表使用
    kernel_pgdir = set_kernel_pgdir(); // 设置内核页表
    switch_pgdir(NULL); // NULL 代表切换为内核页表
}

void kinit2(void* vstart, void* vend)
{
    kmem_free_pages(vstart, vend);
    // kmem.use_lock = 1;
}

/* ********************************************** 物理内存分配器 ******************************************** */

// 链表节点，用于维护空闲页表
struct list_node {
    struct list_node* next;
};

struct {
    // struct spinlock lock;
    // int use_lock;
    struct list_node* freelist;
} kmem; // 内存分配管理器

/**
 * 释放虚拟地址[start, end]之间的内存
 */
void kmem_free_pages(void* start, void* end)
{
    for (char* pg = (char*)PGROUNDUP((uint32_t)start); pg + PGSIZE <= (char*)end; pg += PGSIZE)
        kmem_free(pg);
}

/**
 *  释放虚拟地址v指向的内存
 */
void kmem_free(char* vaddr)
{
    // if ((uint32_t)v % PGSIZE || v < end || K_V2P(v) >= PHYSTOP)
    //     // panic("kfree");

    memset(vaddr, 1, PGSIZE); // 清空该页内存

    // if (kmem.use_lock)
    //     acquire(&kmem.lock);
    struct list_node* node = (struct list_node*)vaddr;
    node->next = kmem.freelist;
    kmem.freelist = node;
    // if (kmem.use_lock)
    //     release(&kmem.lock);
}

/**
 * 分配一页内存，返回指向内存的指针，失败返回NULL
 */
char* kmem_alloc(void)
{
    struct list_node* node = NULL;

    // if (kmem.use_lock)
    //     acquire(&kmem.lock);
    node = kmem.freelist;
    if (node)
        kmem.freelist = node->next;
    // if (kmem.use_lock)
    //     release(&kmem.lock);
    return (char*)node;
}

/* ********************************************** 设置页表 ******************************************** */

/* 接下来还是声明设置内核页表的函数 */

void free_pgdir(struct proc* p);
static int kmmap(pde_t* pgdir, void* vaddr, uint32_t size, paddr_t paddr, int perm);
static pte_t* get_pte(pde_t* pgdir, const void* va, int alloc, int perm);
int deallocuvm(pde_t* pgdir, uint32_t oldsz, uint32_t newsz);

/**
 * 设置内核页表：先分配一页内存作为一级页表页（即页目录），然后在页表中映射 K_ADDR_BASE 之上的虚拟内核
 */
pde_t* set_kernel_pgdir(void)
{
    pde_t* kernel_pgdir;

    if ((kernel_pgdir = (pde_t*)kmem_alloc()) == 0) // 分配一页内存作为一级页表页（即页目录）
        return 0;
    memset(kernel_pgdir, 0, PGSIZE);
    // if (K_P2V(PHYSTOP) > (void*)DEVSPACE)
    //     panic("PHYSTOP too high");
    /* 以下内存映射可以参照 memlayout.h 中的图理解 */
    if (kmmap(kernel_pgdir, (void*)K_ADDR_BASE, P_ADDR_EXTMEM - 0, (paddr_t)0, PTE_W) < 0) { // 映射低1MB内存
        goto bad;
    }
    if (kmmap(kernel_pgdir, (void*)K_ADDR_LOAD, K_V2P(data) - (paddr_t)P_ADDR_EXTMEM, (paddr_t)P_ADDR_EXTMEM, 0) < 0) { // 映射内核代码段和数据段占据的内存
        goto bad;
    }
    if (kmmap(kernel_pgdir, (void*)data, P_ADDR_PHYSTOP - K_V2P(data), K_V2P(data), PTE_W) < 0) { // 映射内核数据段后面的内存
        goto bad;
    }
    if (kmmap(kernel_pgdir, (void*)P_ADDR_DEVSPACE, 0 - P_ADDR_DEVSPACE, (paddr_t)P_ADDR_DEVSPACE, PTE_W) < 0) { // 映射设备内存（直接映射）
        goto bad;
    }
    return kernel_pgdir;

bad:
    kmem_free((char*)kernel_pgdir);
    return 0;
}

/**
 * 切换页表为进程 p 的页表，当 p 为 NULL 时切换回内核页表
 */
void switch_pgdir(struct proc* p)
{
    if (p == NULL) {
        lcr3(K_V2P(kernel_pgdir));
    } else {
        // pushcli();
        // cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts) - 1, 0);
        // cpu->gdt[SEG_TSS].s = 0;
        // cpu->ts.ss0 = SEG_KDATA << 3;
        // cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
        // // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
        // // forbids I/O instructions (e.g., inb and outb) from user space
        // cpu->ts.iomb = (ushort)0xFFFF;
        // ltr(SEG_TSS << 3);
        // if (p->pgdir == 0)
        //     panic("switchuvm: no pgdir");
        // lcr3(K_V2P(p->pgdir)); // switch to process's address space
        // popcli();
    }
}

/**
 * 在页表 pgdir 中进行虚拟内存到物理内存的映射：虚拟地址 vaddr -> 物理地址 paddr，映射长度为 size，权限为 perm，成功返回0，不成功返回-1
 */
static int kmmap(pde_t* pgdir, void* vaddr, uint32_t size, paddr_t paddr, int perm)
{
    char *va_start, *va_end;
    pte_t* pte;

    // if (size == 0)
    //     panic("mappages: size = 0");

    /* 先对齐，并求出需要映射的虚拟地址范围 */
    va_start = (char*)PGROUNDDOWN((vaddr_t)vaddr);
    va_end = (char*)PGROUNDDOWN(((vaddr_t)vaddr) + size - 1);
    /* 对于其中每一页，调用 get_pte 找到所需的页表项，然后将此虚拟页对应的物理地址、权限位填入相应的页表项 pte */
    while (va_start < va_end) {
        if ((pte = get_pte(pgdir, va_start, 1, perm)) == NULL) // 找到 pte
            return -1;
        // if (*pte & PTE_P)
        //     panic("remap");
        *pte = paddr | perm | PTE_P; // 填写 pte
        va_start += PGSIZE;
        paddr += PGSIZE;
    }
    return 0;
}

/**
 * 释放进程 p 的页表，以及其映射的所有物理内存
 */
void free_pgdir(struct proc* p)
{
    // if (p->pgdir == 0)
    //     panic("freevm: no pgdir");
    deallocuvm(p->pgdir, K_ADDR_BASE, 0); // 将 0 到 K_ADDR_BASE 的虚拟地址空间回收
    /* 释放二级页表占据的空间 */
    for (int i = 0; i < NPDENTRIES; i++) {
        if (p->pgdir[i] & PTE_P) {
            char* v = K_P2V(PTE_ADDR(p->pgdir[i]));
            kmem_free(v);
        }
    }
    kmem_free((char*)p->pgdir); // 释放页目录
}

/**
 * 在页表 pgdir 中查找虚拟地址 vaddr 对应的页表项，如果 need_alloc 为 1 且页目录项不存在，则分配一个二级页表，权限位perm，成功返回页表项指针，不成功返回 NULL
 */
static pte_t* get_pte(pde_t* pgdir, const void* vaddr, int need_alloc, int perm)
{
    pde_t* pde; // 页目录项（一级）
    pte_t* pte; // 页表项（二级）

    pde = &pgdir[PDX(vaddr)]; // 根据 vaddr 获取对应的页目录项
    if (*pde & PTE_P) { // 页目录项存在
        pte = (pte_t*)K_P2V(PTE_ADDR(*pde)); // 取出 PPN 所对应的二级页表（即 pte 数组）的地址
    } else {
        if (!need_alloc || (pte = (pte_t*)kmem_alloc()) == NULL) // 不需要分配或分配失败
            return NULL;

        memset(pte, 0, PGSIZE);
        *pde = K_V2P(pte) | perm | PTE_P; // 将二级页表的物理地址写入页目录项
    }
    return &pte[PTX(vaddr)]; // 从二级页表中取出对应的页表项
}

// Deallocate user pages to bring the process size from oldsz to
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int deallocuvm(pde_t* pgdir, uint32_t oldsz, uint32_t newsz)
{
    pte_t* pte;
    uint32_t a, pa;

    if (newsz >= oldsz)
        return oldsz;

    a = PGROUNDUP(newsz);
    for (; a < oldsz; a += PGSIZE) {
        pte = get_pte(pgdir, (char*)a, 0);
        if (!pte)
            a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
        else if ((*pte & PTE_P) != 0) {
            pa = PTE_ADDR(*pte);
            // if (pa == 0)
            //     panic("kfree");
            char* v = K_P2V(pa);
            kmem_free(v);
            *pte = 0;
        }
    }
    return newsz;
}