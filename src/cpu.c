/*************************************************************************
 * cpu.c - 多处理器启动支持
 *************************************************************************/

#include "inc/cpu.h"
#include "inc/i_asm.h"
#include "inc/i_kernel.h"
#include "inc/i_lib.h"
#include "inc/types.h"

volatile uint32_t* lapic;
struct cpu cpus[MAX_CPU];
int num_cpu;
uint8_t ioapicid;

/* ****************************************** cpu 结构支持 ********************************************** */

struct cpu*
mycpu(void)
{
    int apicid, i;

    if (read_eflags() & FL_IF) {
        cprintf("mycpu called with interrupts enabled\n");
        hlt();
    }

    apicid = lapicid();
    // APIC IDs are not guaranteed to be contiguous. Maybe we should have
    // a reverse map, or reserve a register to store &cpus[i].
    for (i = 0; i < num_cpu; ++i) {
        if (cpus[i].apicid == apicid)
            return &cpus[i];
    }
}

int cpuid()
{
    return mycpu() - cpus;
}

static uint8_t
sum(uint8_t* addr, int len)
{
    int i, sum;

    sum = 0;
    for (i = 0; i < len; i++)
        sum += addr[i];
    return sum;
}

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint32_t a, int len)
{
    uint8_t *e, *p, *addr;

    addr = K_P2V(a);
    e = addr + len;
    for (p = addr; p < e; p += sizeof(struct mp))
        if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
            return (struct mp*)p;
    return 0;
}

// Search for the MP Floating Pointer Structure, which according to the
// spec is in one of the following three locations:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
    uint8_t* bda;
    uint32_t p;
    struct mp* mp;

    bda = (uint8_t*)K_P2V(0x400);
    if ((p = ((bda[0x0F] << 8) | bda[0x0E]) << 4)) {
        if ((mp = mpsearch1(p, 1024)))
            return mp;
    } else {
        p = ((bda[0x14] << 8) | bda[0x13]) * 1024;
        if ((mp = mpsearch1(p - 1024, 1024)))
            return mp;
    }
    return mpsearch1(0xF0000, 0x10000);
}
// Search for an MP configuration table.  For now,
// don't accept the default configurations (physaddr == 0).
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp** pmp)
{
    struct mpconf* conf;
    struct mp* mp;

    if ((mp = mpsearch()) == 0 || mp->physaddr == 0)
        return 0;
    conf = (struct mpconf*)K_P2V((uint32_t)mp->physaddr);
    if (memcmp(conf, "PCMP", 4) != 0)
        return 0;
    if (conf->version != 1 && conf->version != 4)
        return 0;
    if (sum((uint8_t*)conf, conf->length) != 0)
        return 0;
    *pmp = mp;
    return conf;
}

void seginit(void)
{
    struct cpu* c;

    // Map "logical" addresses to virtual addresses using identity map.
    // Cannot share a CODE descriptor for both kernel and user
    // because it would have to have DPL_USR, but the CPU forbids
    // an interrupt from CPL=0 to DPL=3.
    c = &cpus[cpuid()];
    c->gdt[SEG_SELECTOR_KCODE] = SEG(STA_X | STA_R, 0, 0xffffffff, 0);
    c->gdt[SEG_SELECTOR_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
    c->gdt[SEG_SELECTOR_UCODE] = SEG(STA_X | STA_R, 0, 0xffffffff, DPL_USER);
    c->gdt[SEG_SELECTOR_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
    lgdt(c->gdt, sizeof(c->gdt));
}

void mcpu_init(void)
{
    uint8_t *p, *e;
    int ismp;
    struct mp* mp;
    struct mpconf* conf;
    struct mpproc* proc;
    struct mpioapic* ioapic;

    conf = mpconfig(&mp);
    ismp = 1;
    lapic = (uint32_t*)conf->lapicaddr;
    for (p = (uint8_t*)(conf + 1), e = (uint8_t*)conf + conf->length; p < e;) {
        switch (*p) {
        case MPPROC:
            proc = (struct mpproc*)p;
            if (num_cpu < MAX_CPU) {
                cpus[num_cpu].apicid = proc->apicid; // apicid may differ from num_cpu
                num_cpu++;
            }
            p += sizeof(struct mpproc);
            continue;
        case MPIOAPIC:
            ioapic = (struct mpioapic*)p;
            ioapicid = ioapic->apicno;
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
    seginit();
}