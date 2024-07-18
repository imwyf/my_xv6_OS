#ifndef _CPU_H_
#define _CPU_H_

/*************************************************************************
 * cpu.h - 定义一些 cpu 中的寄存器相关的值，以及支持多处理器
 *************************************************************************/

#include "mem.h"
#include "proc.h"
#include "types.h"

#define MAX_CPU 8 // cpu 核心最大值

/* 下面是 cpu 相关的结构 */
struct cpu {
    uint8_t apicid; //
    struct context* scheduler; // swtch() here to enter scheduler
    struct taskstate ts; // TSS 进程切换时用
    struct segdesc gdt[NSEG_SELECTORS]; // x86 global descriptor table
    volatile uint32_t started; // cpu 是否启动
    int ncli; // Depth of pushcli nesting.
    int intena; // Were interrupts enabled before pushcli?
    struct proc* proc; // 在该 cpu 上运行的进程
};

/* 下面是两个控制寄存器的值 */
#define CR0_PE 0x00000001 // Protection Enable
#define CR0_MP 0x00000002 // Monitor coProcessor
#define CR0_EM 0x00000004 // Emulation
#define CR0_TS 0x00000008 // Task Switched
#define CR0_ET 0x00000010 // Extension Type
#define CR0_NE 0x00000020 // Numeric Errror
#define CR0_WP 0x00010000 // Write Protect
#define CR0_AM 0x00040000 // Alignment Mask
#define CR0_NW 0x20000000 // Not Writethrough
#define CR0_CD 0x40000000 // Cache Disable
#define CR0_PG 0x80000000 // Paging

#define CR4_PCE 0x00000100 // Performance counter enable
#define CR4_MCE 0x00000040 // Machine Check Enable
#define CR4_PSE 0x00000010 // Page Size Extensions
#define CR4_DE 0x00000008 // Debugging Extensions
#define CR4_TSD 0x00000004 // Time Stamp Disable
#define CR4_PVI 0x00000002 // Protected-Mode Virtual Interrupts
#define CR4_VME 0x00000001 // V86 Mode Extensions

// Eflags register
#define FL_CF 0x00000001 // Carry Flag
#define FL_PF 0x00000004 // Parity Flag
#define FL_AF 0x00000010 // Auxiliary carry Flag
#define FL_ZF 0x00000040 // Zero Flag
#define FL_SF 0x00000080 // Sign Flag
#define FL_TF 0x00000100 // Trap Flag
#define FL_IF 0x00000200 // Interrupt Flag
#define FL_DF 0x00000400 // Direction Flag
#define FL_OF 0x00000800 // Overflow Flag
#define FL_IOPL_MASK 0x00003000 // I/O Privilege Level bitmask
#define FL_IOPL_0 0x00000000 //   IOPL == 0
#define FL_IOPL_1 0x00001000 //   IOPL == 1
#define FL_IOPL_2 0x00002000 //   IOPL == 2
#define FL_IOPL_3 0x00003000 //   IOPL == 3
#define FL_NT 0x00004000 // Nested Task
#define FL_RF 0x00010000 // Resume Flag
#define FL_VM 0x00020000 // Virtual 8086 mode
#define FL_AC 0x00040000 // Alignment Check
#define FL_VIF 0x00080000 // Virtual Interrupt Flag
#define FL_VIP 0x00100000 // Virtual Interrupt Pending
#define FL_ID 0x00200000 // ID flag

/* 下面是支持多处理器架构的结构 */

struct mp { // floating pointer
    uint8_t signature[4]; // "_MP_"
    void* physaddr; // phys addr of MP config table
    uint8_t length; // 1
    uint8_t specrev; // [14]
    uint8_t checksum; // all bytes must add up to 0
    uint8_t type; // MP system config type
    uint8_t imcrp;
    uint8_t reserved[3];
};

struct mpconf { // configuration table header
    uint8_t signature[4]; // "PCMP"
    uint16_t length; // total table length
    uint8_t version; // [14]
    uint8_t checksum; // all bytes must add up to 0
    uint8_t product[20]; // product id
    uint32_t* oemtable; // OEM table pointer
    uint16_t oemlength; // OEM table length
    uint16_t entry; // entry count
    uint32_t* lapicaddr; // address of local APIC
    uint16_t xlength; // extended table length
    uint8_t xchecksum; // extended table checksum
    uint8_t reserved;
};

struct mpproc { // processor table entry
    uint8_t type; // entry type (0)
    uint8_t apicid; // local APIC id
    uint8_t version; // local APIC verison
    uint8_t flags; // CPU flags
#define MPBOOT 0x02 // This proc is the bootstrap processor.
    uint8_t signature[4]; // CPU signature
    uint32_t feature; // feature flags from CPUID instruction
    uint8_t reserved[8];
};

struct mpioapic { // I/O APIC table entry
    uint8_t type; // entry type (2)
    uint8_t apicno; // I/O APIC id
    uint8_t version; // I/O APIC version
    uint8_t flags; // I/O APIC flags
    uint32_t* addr; // I/O APIC address
};

// Table entry types
#define MPPROC 0x00 // One per processor
#define MPBUS 0x01 // One per bus
#define MPIOAPIC 0x02 // One per I/O APIC
#define MPIOINTR 0x03 // One per bus interrupt source
#define MPLINTR 0x04 // One per system interrupt source

#endif /* !_CPU_H_ */
