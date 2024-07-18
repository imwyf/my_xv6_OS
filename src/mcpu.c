/*************************************************************************
 * mcpu.c - 多处理器启动支持
 *************************************************************************/

#include "inc/cpu.h"
#include "inc/i_asm.h"
#include "inc/i_lib.h"
#include "inc/types.h"

extern volatile uint32_t* lapic;
struct cpu cpus[MAX_CPU];
int num_cpu;
uint8_t ioapicid;

static struct mpconf* mpconfig(struct mp** pmp);

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