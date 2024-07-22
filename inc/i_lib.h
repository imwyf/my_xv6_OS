#ifndef _I_LIB_H_
#define _I_LIB_H_

/*************************************************************************
 * i_lib.h - 声明本 OS 会使用的辅助函数接口
 *************************************************************************/

#include "types.h"

void* memset(void* dst, int c, uint32_t n);
int memcmp(const void* v1, const void* v2, uint32_t n);
void* memmove(void* dst, const void* src, uint32_t n);
void* memcpy(void* dst, const void* src, uint32_t n);
int strncmp(const char* p, const char* q, uint32_t n);
char* strncpy(char* s, const char* t, int n);
char* safestrcpy(char* s, const char* t, int n);
int strlen(const char* s);

void cons_init(void);
void cons_uselock();
void cprintf(char* fmt, ...);

void spin(int ms);

#endif /* !_I_LIB_H_ */