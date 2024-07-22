#ifndef _LOCK_H_
#define _LOCK_H_

/*************************************************************************
 * lock.h - 定义锁相关的结构
 *************************************************************************/

#include "inc/types.h"

struct spinlock {
    uint32_t locked; // 是否锁住
    char* name;
    struct cpu* cpu; // 持有该锁的 cpu
    uint32_t pcs[10]; // 调用栈
};

#endif /* !_LOCK_H_ */