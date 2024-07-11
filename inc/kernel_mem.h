#ifndef _KERNEL_MEM_H
#define _KERNEL_MEM_H

#include "inc/mmu.h"
#include "inc/types.h"

#define MAX_ORDER 11 // 内核管理的最大的连续物理块为2^(11-1) = 4MB
#define ORDER_SIZE(o) (1 << (o)) // 2^o，计算o阶的内存块大小

/**
 * 一个Page代表一个内存页
 */
struct Page {
    struct Page* pg_next; // next指针
    uint16_t pg_ref; // 本页的引用计数
};
static struct Page* pages; // 物理内存页的数组
static size_t n_page; // 物理内存页的数量

struct free_list {
    struct Page* head; // 指向空闲链表的头
    uint32_t order; // 阶数
};

typedef struct {
    // struct spinlock lock;
    // int use_lock;
    struct free_list free_lists[MAX_ORDER - 1]; // 每个 free_lists[i] 中存放的是内存大小为 2^i 的空闲链表
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
struct Page* alloc_onepage(uint32_t order);
/**
 * 释放p开始的n个内存页
 */
void free_page(struct Page* p);

/**
 * 将物理页的偏移转换成物理地址pa
 */
static inline paddr_t
page2pa(struct Page* page)
{
    return (page - pages) << PGSHIFT;
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
/**
 * 将物理页的偏移转换成内核虚拟地址kva
 */
static inline void*
page2kva(struct Page* page)
{
    return K_P2V(page2pa(page));
}

#endif // _KERNEL_MEM_H