/*************************************************************************
 * kernel_mem.c - 负责内存分配、地址映射、页表建立等初始化工作
 *************************************************************************/
// TODO:加锁
#include "inc/kernel_mem.h"
#include "inc/mmu.h"
#include "inc/types.h"
#include <inc/lib.h>
// #include "inc/lock.h"

extern char* end; // 内核的 ELF 文件结束后的第一个虚拟地址，定义于 kernel.ld
extern char* edata; // 数据段结尾

/**
 * 初始化内存管理
 */
void kmem_init()
{
    // initlock(&kmem.lock, "kmem");
    // kmem.use_lock = 0;
    memset(edata, 0, end - edata); // 先将bss段清零，确保所有静态/全局变量从零开始

    /* 现在的 entry_pgdir 只映射了低4MB内存，不够用，下面重新设置页表 */
    memset(end, 0, K_P2V_WO(P_ADDR_LOWMEM)); // 由于只映射了低 4MB 内存，先初始化 [end, 4MB] 的空间来为新的页表腾出空间
    kernel_pgdir = (pde_t*)tmp_alloc(PGSIZE); // 分配一页内存作为页目录
    // kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P; // 递归地将PD作为页表插入其自身，以在虚拟地址UVPT处形成页表。

    /* 伙伴系统初始化（页分配器），之后只能使用该系统管理内存 */
    page_init();
}

/**
 * 仅在设置页表时使用的简单的物理内存分配器，之后使用alloc_pages()分配,
 * 分配一个足以容纳n字节的内存区间：用一个地址nextfree来确定可以使用的内存的顶部，并且返回可以使用的内存的底部地址result
 * 可使用内存区间为[result, nextfree], 且区间长度是页对齐的
 */
static void*
tmp_alloc(uint32_t n)
{
    static char* nextfree; // static意味着nextfree不会随着函数返回被重置，是静态变量
    char* result;

    if (!nextfree) // nextfree初始化，只有第一次运行会执行
    {
        nextfree = ROUNDUP((char*)end, PGSIZE); // 内核使用的第一块内存必须远离内核代码结尾
    }

    if (n == 0) // 不分配内存，直接返回
    {
        return nextfree;
    }

    // n是无符号数，不考虑<0情形
    result = nextfree; // 将更新前的nextfree赋给result
    nextfree += ROUNDUP(n, PGSIZE); // +=:在原来的基础上再分配

    // 如果内存不足，boot_alloc应该会死机
    if (nextfree > (char*)0xC0400000) // >4MB
    {
        // panic("out of memory(4MB) : boot_alloc() in pmap.c \n"); // 调用预先定义的assert
        nextfree = result; // 分配失败，回调nextfree
        return NULL;
    }
    return result;
}

/**
 * 释放一页内存，与 alloc_page() 配合使用
 */
// void free_page(char* vaddr)
// {
// }

/**
 * * 分配一页内存，在 kernel_pgdir 建立之后与 free_page() 配合使用
 */
// char* alloc_page(char* vaddr)
// {
// }

void page_init()
{
    /* 先为 pages 分配空间，以便映射每一页物理内存 */
    pages = (struct Page*)tmp_alloc(n_pages * sizeof(struct Page));
    memset(pages, 0, n_pages * sizeof(struct Page));
    for (int i = 0; i < n_pages; i++) {
        (pages + i)->reserved = true;
    }
    /* 伙伴系统初始化 */
    zone_mem_base = (struct Page*)tmp_alloc(0); // 可管理区域的起始地址
    struct buddy* buddy = &zone->free_lists[order++];
    size_t n_page_allocable = n_pages - PGNUM(page2pa(zone_mem_base)); // 可分配的页数量
    size_t v_size = next_power_of_2(n_page_allocable);
    size_t excess = v_size - n_page_allocable;
    size_t v_alloced_size = next_power_of_2(excess);

    buddy->size = v_size;
    buddy->free_size = v_size - v_alloced_size;
    buddy->longest = page2kva(zone_mem_base);
    buddy->start = pa2page(K_V2P(ROUNDUP(buddy->longest + 2 * v_size * sizeof(uintptr_t), PGSIZE)));
    buddy->longest_num_page = buddy->start - zone_mem_base;
    buddy->total_num_page = n_page_allocable - buddy->longest_num_page;

    size_t node_size = buddy->size * 2;

    for (int i = 0; i < 2 * buddy->size - 1; i++) {
        if (IS_POWER_OF_2(i + 1)) {
            node_size /= 2;
        }
        buddy->longest[i] = node_size;
    }

    int index = 0;
    while (1) {
        if (buddy->longest[index] == v_alloced_size) {
            buddy->longest[index] = 0;
            break;
        }
        index = RIGHT_LEAF(index);
    }

    while (index) {
        index = PARENT(index);
        buddy->longest[index] = MAX(buddy->longest[LEFT_LEAF(index)], buddy->longest[RIGHT_LEAF(index)]);
    }

    struct Page* p = buddy->start;
    for (; p != zone_mem_base + buddy->free_size; p++) {
        p->reserved = false;
        p->pg_ref = 0;
    }
}