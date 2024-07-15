/*************************************************************************
 * kernel_mem.c - 负责内存分配、地址映射、页表建立等初始化工作
 *************************************************************************/
// TODO:加锁
#include "inc/mmu.h"
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
    switch_to_kernel_pgdir();
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
 * 分配一页内存，返回指向内存的指针
 */
char* kmem_alloc(void)
{
    struct list_node* node;

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

// There is one page table per process, plus one that's used when
// a CPU is not running any process (kpgdir). The kernel uses the
// current process's page table during system calls and interrupts;
// page protection bits prevent user code from using the kernel's
// mappings.
//
// setupkvm() and exec() set up every page table like this:
//
//   0..KERNBASE: user memory (text+data+stack+heap), mapped to
//                phys memory allocated by the kernel
//   KERNBASE..KERNBASE+EXTMEM: mapped to 0..EXTMEM (for I/O space)
//   KERNBASE+EXTMEM..data: mapped to EXTMEM..V2P(data)
//                for the kernel's instructions and r/o data
//   data..KERNBASE+PHYSTOP: mapped to V2P(data)..PHYSTOP,
//                                  rw data + free physical memory
//   0xfe000000..0: mapped direct (devices such as ioapic)
//
// The kernel allocates physical memory for its heap and for user memory
// between V2P(end) and the end of physical memory (PHYSTOP)
// (directly addressable from end..P2V(PHYSTOP)).

// This table defines the kernel's mappings, which are present in
// every process's page table.

/* 接下来还是声明设置内核页表的函数 */
void freevm(pde_t* pgdir);
static int kmmap(pde_t* pgdir, void* va, uint32_t size, uint32_t pa, int perm);
static pte_t* walkpgdir(pde_t* pgdir, const void* va, int alloc);

pde_t* set_kernel_pgdir(void)
{
    pde_t* kernel_pgdir;

    if ((kernel_pgdir = (pde_t*)kmem_alloc()) == 0)
        return 0;
    memset(kernel_pgdir, 0, PGSIZE);
    // if (K_P2V(PHYSTOP) > (void*)DEVSPACE)
    //     panic("PHYSTOP too high");
    if (kmmap(kernel_pgdir, (void*)K_ADDR_BASE, P_ADDR_EXTMEM - 0, (paddr_t)0, PTE_W) < 0) {
        freevm(kernel_pgdir);
        return 0;
    }
    if (kmmap(kernel_pgdir, (void*)K_ADDR_LOAD, K_V2P(data) - K_V2P(K_ADDR_LOAD), K_V2P(K_ADDR_LOAD), 0) < 0) {
        freevm(kernel_pgdir);
        return 0;
    }
    if (kmmap(kernel_pgdir, (void*)data, P_ADDR_PHYSTOP - K_V2P(data), K_V2P(data), PTE_W) < 0) {
        freevm(kernel_pgdir);
        return 0;
    }
    if (kmmap(kernel_pgdir, (void*)P_ADDR_DEVSPACE, 0 - P_ADDR_DEVSPACE, P_ADDR_DEVSPACE, PTE_W) < 0) {
        freevm(kernel_pgdir);
        return 0;
    }
    return kernel_pgdir;
}
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int kmmap(pde_t* pgdir, void* va, uint32_t size, paddr_t pa, int perm)
{
    char *a, *last;
    pte_t* pte;

    a = (char*)PGROUNDDOWN((uint32_t)va);
    last = (char*)PGROUNDDOWN(((uint32_t)va) + size - 1);
    for (;;) {
        if ((pte = walkpgdir(pgdir, a, 1)) == 0)
            return -1;
        // if (*pte & PTE_P)
        //     panic("remap");
        *pte = pa | perm | PTE_P;
        if (a == last)
            break;
        a += PGSIZE;
        pa += PGSIZE;
    }
    return 0;
}

// Free a page table and all the physical memory pages
// in the user part.
void freevm(pde_t* pgdir)
{
    uint32_t i;

    if (pgdir == 0)
        panic("freevm: no pgdir");
    deallocuvm(pgdir, KERNBASE, 0);
    for (i = 0; i < NPDENTRIES; i++) {
        if (pgdir[i] & PTE_P) {
            char* v = P2V(PTE_ADDR(pgdir[i]));
            kfree(v);
        }
    }
    kfree((char*)pgdir);
}

// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t*
walkpgdir(pde_t* pgdir, const void* va, int alloc)
{
    pde_t* pde;
    pte_t* pgtab;

    pde = &pgdir[PDX(va)];
    if (*pde & PTE_P) {
        pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
    } else {
        if (!alloc || (pgtab = (pte_t*)kalloc()) == 0)
            return 0;
        // Make sure all those PTE_P bits are zero.
        memset(pgtab, 0, PGSIZE);
        // The permissions here are overly generous, but they can
        // be further restricted by the permissions in the page table
        // entries, if necessary.
        *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
    }
    return &pgtab[PTX(va)];
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
        pte = walkpgdir(pgdir, (char*)a, 0);
        if (!pte)
            a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
        else if ((*pte & PTE_P) != 0) {
            pa = PTE_ADDR(*pte);
            if (pa == 0)
                panic("kfree");
            char* v = P2V(pa);
            kfree(v);
            *pte = 0;
        }
    }
    return newsz;
}