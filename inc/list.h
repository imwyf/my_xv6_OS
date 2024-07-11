#ifndef _LIST_H_
#define _LIST_H_

/**
 * 双向链表节点
 */
struct list_head {
	struct list_head *next, *prev;
};


#endif /* !_LIST_H_ */