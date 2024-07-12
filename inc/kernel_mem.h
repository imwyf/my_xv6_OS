#ifndef _KERNEL_MEM_H
#define _KERNEL_MEM_H

#include "inc/list.h"
#include "inc/mmu.h"
#include "inc/types.h"

#define MAX_ORDER 11 // 内核管理的最大的连续物理块为2^10页 = 4MB
#define IS_POWER_OF_2(x) (!((x) & ((x)-1)))
#define LEFT_LEAF(index) ((index)*2 + 1)
#define RIGHT_LEAF(index) ((index)*2 + 2)
#define PARENT(index) (((index) + 1) / 2 - 1)

/* 下面是管理物理内核页的结构： */
/**
 * 一个Page映射一个内存页
 */
struct Page {
    struct list_head lru; // 用来链接进空闲链表的指针
    uint16_t pg_ref; // 本页的引用计数
    bool reserved; // 是否被保留
};
struct Page* pages; // 物理内存页的数组
static size_t n_pages; // 物理内存页的数量

/**
 * 不同阶数的空闲链表
 */
struct buddy {
    size_t size; // 连续内存页大小
    uintptr_t* longest;
    size_t longest_num_page; // longest数组的大小
    size_t total_num_page; //
    size_t free_size; // 空闲页大小
    struct Page* start;
};

typedef struct {
    // struct spinlock lock;
    // int use_lock;
    struct buddy free_lists[MAX_ORDER]; // 每个 free_lists[i] 中存放的是内存大小为 2^i 的空闲链表
} kmem_zone; //

static kmem_zone* zone;
static struct Page* zone_mem_base;
int order = 0;
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

static size_t next_power_of_2(size_t size)
{
    size |= size >> 1;
    size |= size >> 2;
    size |= size >> 4;
    size |= size >> 8;
    size |= size >> 16;
    return size + 1;
}

#endif // _KERNEL_MEM_H