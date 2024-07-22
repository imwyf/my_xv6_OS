/*************************************************************************
 * cpu.c - 多处理器启动支持
 *************************************************************************/

#include "inc/cpu.h"
#include "inc/i_asm.h"
#include "inc/i_kernel.h"
#include "inc/i_lib.h"
#include "inc/types.h"

extern volatile uint32_t* lapic; // 定义于 interrupt.c
extern volatile uint8_t ioapic_id; // 定义于 interrupt.c
struct cpu cpus[MAX_CPU];
int num_cpu;

/* ****************************************** cpu 结构支持 ********************************************** */

struct cpu* mycpu(void)
{
    int apicid, i;

    if (read_eflags() & FL_IF) {
        cprintf("mycpu called with interrupts enabled\n");
        hlt();
    }

    apicid = lapic_id();
    // APIC IDs are not guaranteed to be contiguous. Maybe we should have
    // a reverse map, or reserve a register to store &cpus[i].
    for (i = 0; i < num_cpu; ++i) {
        if (cpus[i].apicid == apicid)
            return &cpus[i];
    }
    return NULL;
}

int cpuid()
{
    return mycpu() - cpus;
}

static uint8_t sum(uint8_t* addr, int len)
{
    int i, sum;

    sum = 0;
    for (i = 0; i < len; i++)
        sum += addr[i];
    return sum;
}

/* ****************************************** 多处理器支持 ********************************************** */

/**
 * 在 [a,a+len] 这一段内存寻找 floating pointer 结构
 */
static struct mp*
search_fp(uint32_t a, int len)
{
    uint8_t *e, *p, *addr;

    addr = K_P2V(a);
    e = addr + len;
    for (p = addr; p < e; p += sizeof(struct mp))
        if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
            return (struct mp*)p;
    return 0;
}

/**
 * 寻找 floating pointer 结构
 */
static struct mp*
find_fp(void)
{
    uint8_t* bda;
    uint32_t p;
    struct mp* mp;

    bda = (uint8_t*)K_P2V(0x400); // BIOS Data Area地址
    if ((p = ((bda[0x0F] << 8) | bda[0x0E]) << 4)) { //在EBDA中最开始1K中寻找
        if ((mp = search_fp(p, 1024)))
            return mp;
    } else { //在基本内存的最后1K中查找
        p = ((bda[0x14] << 8) | bda[0x13]) * 1024;
        if ((mp = search_fp(p - 1024, 1024)))
            return mp;
    }
    return search_fp(0xF0000, 0x10000); //在0xf0000~0xfffff中查找
}

/**
 * 寻找 MP Configuration Table
 */
static struct mpconf*
find_mpct(struct mp** pmp)
{
    struct mpconf* conf;
    struct mp* mp;

    if ((mp = find_fp()) == 0 || mp->physaddr == 0)
        return 0;
    conf = (struct mpconf*)K_P2V((uint32_t)mp->physaddr); // 根据 floating pointer 找到 MP Configuration Table
    if (memcmp(conf, "PCMP", 4) != 0)
        return 0;
    if (conf->version != 1 && conf->version != 4)
        return 0;
    if (sum((uint8_t*)conf, conf->length) != 0)
        return 0;
    *pmp = mp;
    return conf;
}

/**
 * 检测其他处理器，并将其配置写入 cpu 结构
 */
void conf_mcpu(void)
{
    uint8_t *p, *e;
    int ismp;
    struct mp* mp;
    struct mpconf* conf;
    struct mpproc* proc;
    struct mpioapic* ioapic;

    /* 寻找有多少个处理器表项，多少个处理器表项就代表有多少个处理器，然后将相关信息填进全局的 CPU 数据结构 */
    conf = find_mpct(&mp);
    ismp = 1;
    lapic = (uint32_t*)conf->lapicaddr;
    for (p = (uint8_t*)(conf + 1), e = (uint8_t*)conf + conf->length; p < e;) { // 跳过表头，从第一个表项开始for循环
        switch (*p) { //选取当前表项
        case MPPROC: //如果是处理器
            proc = (struct mpproc*)p;
            if (num_cpu < MAX_CPU) {
                cpus[num_cpu].apicid = proc->apicid; // apic id可以标识一个CPU
                num_cpu++; //找到一个CPU表项，CPU数量加1
            }
            p += sizeof(struct mpproc); //跳过当前CPU表项继续循环
            continue;
        case MPIOAPIC:
            ioapic = (struct mpioapic*)p;
            ioapic_id = ioapic->apicno;
            p += sizeof(struct mpioapic);
            continue;
        case MPBUS:
        case MPIOINTR:
        case MPLINTR:
            p += 8;
            continue;
        default:
            ismp = 0;
            break;
        }
    }
    if (!ismp) {
        cprintf("Didn't find a suitable machine");
        hlt();
    }

    if (mp->imcrp) {
        // Bochs doesn't support IMCR, so this doesn't run on Bochs.
        // But it would on real hardware.
        outb(0x22, 0x70); // Select IMCR
        outb(0x23, inb(0x23) | 1); // Mask external interrupts.
    }
}