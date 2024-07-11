#ifndef _KERNEL_MEM_H
#define _KERNEL_MEM_H

#include "inc/mmu.h"
#include "inc/types.h"
#include "inc/list.h"

#define MAX_ORDER 11 // 内核管理的最大的连续物理块为2^10页 = 4MB
// #define MEM2ORDER(size) (ROUNDUP(size)) // 计算内存块的阶

/* 下面是管理物理内核页的结构： */
/**
 * 一个Page映射一个内存页
 */
struct Page {
    struct list_head lru; // 用来链接进空闲链表的指针
    uint16_t pg_ref; // 本页的引用计数
    uint32_t index; // 该页在整个内存空间的偏移
};
static struct Page* pages; // 物理内存页的数组
static size_t n_page; // 物理内存页的数量

/**
 * 不同阶数的空闲链表
 */
struct free_list {
    struct list_head list_head[1]; // 表头节点
    uint32_t n_block; // 链表元素（内存块）个数
    uint8_t order; // 本链表的阶数
};

typedef struct {
    // struct spinlock lock;
    // int use_lock;
    struct free_list free_lists[MAX_ORDER]; // 每个 free_lists[i] 中存放的是内存大小为 2^i 的空闲链表
} kmem_manager; // 内核内存管理器

pde_t* kernel_pgdir;

static void* tmp_alloc(uint32_t n);
/**
 * 分配n个内存页，尽量分配连续的内存页
 */
struct Page* alloc_pages(uint32_t n);
/**
 * 分配一个内存页，order指定阶数
 */
struct Page* alloc_page(uint32_t order);
/**
 * 释放p开始的n个内存页
 */
void free_page(struct Page* p);

void page_init();





/**
 * 将物理页的偏移转换成物理地址pa
 */
static inline paddr_t
page2pa(struct Page* page)
{
    return (page - pages) << PGSHIFT;
}
/**
 * 将物理页的偏移转换成内核虚拟地址kva
 */
static inline void*
page2kva(struct Page* page)
{
    return K_P2V(page2pa(page));
}
/**
 * 将物理地址pa转换成物理页的偏移
 */
static inline struct Page*
pa2page(paddr_t pa)
{
    // if (PGNUM(pa) >= n_page)
    //     panic("pa2page called with invalid pa");
    return &pages[PGNUM(pa)];
}

#endif // _KERNEL_MEM_H