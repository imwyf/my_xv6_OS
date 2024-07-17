#ifndef _I_ASM_H_
#define _I_ASM_H_

/*************************************************************************
 * i_asm.h - 接口文件：声明定义一些 x86 中常用的内联汇编指令为函数接口
 *************************************************************************/

#include "types.h"

static inline void
hlt(void)
{
    asm volatile("hlt");
}

static inline void
breakpoint(void)
{
    asm volatile("int3");
}

static inline void
stosb(void* addr, int data, int cnt)
{
    asm volatile("cld; rep stosb"
                 : "=D"(addr), "=c"(cnt)
                 : "0"(addr), "1"(cnt), "a"(data)
                 : "memory", "cc");
}

static inline void
stosl(void* addr, int data, int cnt)
{
    asm volatile("cld; rep stosl"
                 : "=D"(addr), "=c"(cnt)
                 : "0"(addr), "1"(cnt), "a"(data)
                 : "memory", "cc");
}

static inline uint8_t
inb(int port)
{
    uint8_t data;
    asm volatile("inb %w1,%0"
                 : "=a"(data)
                 : "d"(port));
    return data;
}

static inline void
insb(int port, void* addr, int cnt)
{
    asm volatile("cld\n\trepne\n\tinsb"
                 : "=D"(addr), "=c"(cnt)
                 : "d"(port), "0"(addr), "1"(cnt)
                 : "memory", "cc");
}

static inline uint16_t
inw(int port)
{
    uint16_t data;
    asm volatile("inw %w1,%0"
                 : "=a"(data)
                 : "d"(port));
    return data;
}

static inline void
insw(int port, void* addr, int cnt)
{
    asm volatile("cld\n\trepne\n\tinsw"
                 : "=D"(addr), "=c"(cnt)
                 : "d"(port), "0"(addr), "1"(cnt)
                 : "memory", "cc");
}

static inline uint32_t
inl(int port)
{
    uint32_t data;
    asm volatile("inl %w1,%0"
                 : "=a"(data)
                 : "d"(port));
    return data;
}

/**
 * insl(port,addr,cnt) : 从port读cnt个dword到addr中去
 */
static inline void
insl(int port, void* addr, int cnt)
{
    asm volatile("cld\n\trepne\n\tinsl"
                 : "=D"(addr), "=c"(cnt)
                 : "d"(port), "0"(addr), "1"(cnt)
                 : "memory", "cc");
}

/**
 * outb(port,data): 向port写入1字节数据data
 */
static inline void
outb(int port, uint8_t data)
{
    asm volatile("outb %0,%w1"
                 :
                 : "a"(data), "d"(port));
}

static inline void
outsb(int port, const void* addr, int cnt)
{
    asm volatile("cld\n\trepne\n\toutsb"
                 : "=S"(addr), "=c"(cnt)
                 : "d"(port), "0"(addr), "1"(cnt)
                 : "cc");
}

static inline void
outw(int port, uint16_t data)
{
    asm volatile("outw %0,%w1"
                 :
                 : "a"(data), "d"(port));
}

static inline void
outsw(int port, const void* addr, int cnt)
{
    asm volatile("cld\n\trepne\n\toutsw"
                 : "=S"(addr), "=c"(cnt)
                 : "d"(port), "0"(addr), "1"(cnt)
                 : "cc");
}

static inline void
outsl(int port, const void* addr, int cnt)
{
    asm volatile("cld\n\trepne\n\toutsl"
                 : "=S"(addr), "=c"(cnt)
                 : "d"(port), "0"(addr), "1"(cnt)
                 : "cc");
}

static inline void
outl(int port, uint32_t data)
{
    asm volatile("outl %0,%w1"
                 :
                 : "a"(data), "d"(port));
}

static inline void
invlpg(void* addr)
{
    asm volatile("invlpg (%0)"
                 :
                 : "r"(addr)
                 : "memory");
}

static inline void
lidt(void* p)
{
    asm volatile("lidt (%0)"
                 :
                 : "r"(p));
}

static inline void
lgdt(void* p)
{
    asm volatile("lgdt (%0)"
                 :
                 : "r"(p));
}

static inline void
lldt(uint16_t sel)
{
    asm volatile("lldt %0"
                 :
                 : "r"(sel));
}

static inline void
ltr(uint16_t sel)
{
    asm volatile("ltr %0"
                 :
                 : "r"(sel));
}

static inline void
lcr0(uint32_t val)
{
    asm volatile("movl %0,%%cr0"
                 :
                 : "r"(val));
}

static inline uint32_t
rcr0(void)
{
    uint32_t val;
    asm volatile("movl %%cr0,%0"
                 : "=r"(val));
    return val;
}

static inline uint32_t
rcr2(void)
{
    uint32_t val;
    asm volatile("movl %%cr2,%0"
                 : "=r"(val));
    return val;
}

static inline void
lcr3(uint32_t val)
{
    asm volatile("movl %0,%%cr3"
                 :
                 : "r"(val));
}

static inline uint32_t
rcr3(void)
{
    uint32_t val;
    asm volatile("movl %%cr3,%0"
                 : "=r"(val));
    return val;
}

static inline void
lcr4(uint32_t val)
{
    asm volatile("movl %0,%%cr4"
                 :
                 : "r"(val));
}

static inline uint32_t
rcr4(void)
{
    uint32_t cr4;
    asm volatile("movl %%cr4,%0"
                 : "=r"(cr4));
    return cr4;
}

static inline void
tlbflush(void)
{
    uint32_t cr3;
    asm volatile("movl %%cr3,%0"
                 : "=r"(cr3));
    asm volatile("movl %0,%%cr3"
                 :
                 : "r"(cr3));
}

static inline uint32_t
read_eflags(void)
{
    uint32_t eflags;
    asm volatile("pushfl; popl %0"
                 : "=r"(eflags));
    return eflags;
}

static inline void
write_eflags(uint32_t eflags)
{
    asm volatile("pushl %0; popfl"
                 :
                 : "r"(eflags));
}

static inline uint32_t
read_ebp(void)
{
    uint32_t ebp;
    asm volatile("movl %%ebp,%0"
                 : "=r"(ebp));
    return ebp;
}

static inline uint32_t
read_esp(void)
{
    uint32_t esp;
    asm volatile("movl %%esp,%0"
                 : "=r"(esp));
    return esp;
}

static inline void
cpuid(uint32_t info, uint32_t* eaxp, uint32_t* ebxp, uint32_t* ecxp, uint32_t* edxp)
{
    uint32_t eax, ebx, ecx, edx;
    asm volatile("cpuid"
                 : "=a"(eax), "=b"(ebx), "=c"(ecx), "=d"(edx)
                 : "a"(info));
    if (eaxp)
        *eaxp = eax;
    if (ebxp)
        *ebxp = ebx;
    if (ecxp)
        *ecxp = ecx;
    if (edxp)
        *edxp = edx;
}

static inline uint64_t
read_tsc(void)
{
    uint64_t tsc;
    asm volatile("rdtsc"
                 : "=A"(tsc));
    return tsc;
}

static inline uint32_t
xchg(volatile uint32_t* addr, uint32_t newval)
{
    uint32_t result;

    // The + in "+m" denotes a read-modify-write operand.
    asm volatile("lock; xchgl %0, %1"
                 : "+m"(*addr), "=a"(result)
                 : "1"(newval)
                 : "cc");
    return result;
}

#endif /* !_I_ASM_H_ */
