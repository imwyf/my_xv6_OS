/*************************************************************************
 * interrupt.c - 中断相关
 *************************************************************************/
#include "inc/interrupt.h"
#include "inc/apic.h"
#include "inc/i_asm.h"
#include "inc/i_kernel.h"
#include "inc/i_lib.h"
#include "inc/mem.h"
#include "inc/time.h"
#include <inc/types.h>

volatile uint32_t* lapic; // 在 mcpu_init()中被设置
volatile uint8_t ioapic_id; // 在 mcpu_init()中被设置
volatile struct ioapic_mmio* ioapic_mmio;

/* 下面是函数前向声明 */
static void lapic_write(int index, int value);
static uint32_t ioapic_read(int reg);
static void ioapic_write(int reg, uint32_t data);

void interrupt_init(void)
{
    if (!lapic)
        return;

    // Enable local APIC; set spurious interrupt vector.
    lapic_write(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));

    // The timer repeatedly counts down at bus frequency
    // from lapic[TICR] and then issues an interrupt.
    // If xv6 cared more about precise timekeeping,
    // TICR would be calibrated using an external time source.
    lapic_write(TDCR, X1);
    lapic_write(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
    lapic_write(TICR, 10000000);

    // Disable logical interrupt lines.
    lapic_write(LINT0, MASKED);
    lapic_write(LINT1, MASKED);

    // Disable performance counter overflow interrupts
    // on machines that provide that interrupt entry.
    if (((lapic[VER] >> 16) & 0xFF) >= 4)
        lapic_write(PCINT, MASKED);

    // Map error interrupt to IRQ_ERROR.
    lapic_write(ERROR, T_IRQ0 + IRQ_ERROR);

    // Clear error status register (requires back-to-back writes).
    lapic_write(ESR, 0);
    lapic_write(ESR, 0);

    // Ack any outstanding interrupts.
    lapic_write(EOI, 0);

    // Send an Init Level De-Assert to synchronise arbitration ID's.
    lapic_write(ICRHI, 0);
    lapic_write(ICRLO, BCAST | INIT | LEVEL);
    while (lapic[ICRLO] & DELIVS)
        ;

    // Enable interrupts on the APIC (but not on the processor).
    lapic_write(TPR, 0);

    /* Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware. */
    outb(IO_PIC1 + 1, 0xFF);
    outb(IO_PIC2 + 1, 0xFF);

    /* ioapic */
    int i,
        id, maxintr;

    ioapic_mmio = (volatile struct ioapic_mmio*)IOAPIC_MMIO;
    maxintr = (ioapic_read(REG_VER) >> 16) & 0xFF;
    id = ioapic_read(REG_ID) >> 24;
    if (id != ioapic_id)
        cprintf("ioapic_init: id isn't equal to ioapic_id; not a MP\n");

    // Mark all interrupts edge-triggered, active high, disabled,
    // and not routed to any CPUs.
    for (i = 0; i <= maxintr; i++) {
        ioapic_write(REG_TABLE + 2 * i, INT_DISABLED | (T_IRQ0 + i));
        ioapic_write(REG_TABLE + 2 * i + 1, 0);
    }
}

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void lapic_startap(uint8_t apicid, paddr_t addr)
{
    int i;
    uint16_t* wrv;

    // "The BSP must initialize CMOS shutdown code to 0AH
    // and the warm reset vector (DWORD based at 40:67) to point at
    // the AP startup code prior to the [universal startup algorithm]."
    outb(CMOS_PORT, 0xF); // offset 0xF is shutdown code
    outb(CMOS_PORT + 1, 0x0A);
    wrv = (uint16_t*)K_P2V((0x40 << 4 | 0x67)); // Warm reset vector
    wrv[0] = 0;
    wrv[1] = addr >> 4;

    // "Universal startup algorithm."
    // Send INIT (level-triggered) interrupt to reset other CPU.
    lapic_write(ICRHI, apicid << 24);
    lapic_write(ICRLO, INIT | LEVEL | ASSERT);
    spin(200);
    lapic_write(ICRLO, INIT | LEVEL);
    spin(100); // should be 10ms, but too slow in Bochs!

    // Send startup IPI (twice!) to enter code.
    // Regular hardware is supposed to only accept a STARTUP
    // when it is in the halted state due to an INIT.  So the second
    // should be ignored, but it is part of the official Intel algorithm.
    // Bochs complains about the second one.  Too bad for Bochs.
    for (i = 0; i < 2; i++) {
        lapic_write(ICRHI, apicid << 24);
        lapic_write(ICRLO, STARTUP | (addr >> 12));
        spin(200);
    }
}

/**
 * 写入 lapic
 */
static void lapic_write(int index, int value)
{
    lapic[index] = value;
    lapic[ID]; // wait for write to finish, by reading
}

int lapic_id(void)
{
    if (!lapic)
        return 0;
    return lapic[ID] >> 24;
}

void lapic_eoi(void)
{
    if (lapic)
        lapic_write(EOI, 0);
}

static uint32_t
cmos_read(uint32_t reg)
{
    outb(CMOS_PORT, reg);
    spin(200);

    return inb(CMOS_RETURN);
}

static void
fill_rtcdate(struct time_GWT* r)
{
    r->second = cmos_read(SECS);
    r->minute = cmos_read(MINS);
    r->hour = cmos_read(HOURS);
    r->day = cmos_read(DAY);
    r->month = cmos_read(MONTH);
    r->year = cmos_read(YEAR);
}

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmos_time(struct time_GWT* r)
{
    struct time_GWT t1, t2;
    int sb, bcd;

    sb = cmos_read(CMOS_STATB);

    bcd = (sb & (1 << 2)) == 0;

    // make sure CMOS doesn't modify time while we read it
    for (;;) {
        fill_rtcdate(&t1);
        if (cmos_read(CMOS_STATA) & CMOS_UIP)
            continue;
        fill_rtcdate(&t2);
        if (memcmp(&t1, &t2, sizeof(t1)) == 0)
            break;
    }

    // convert
    if (bcd) {
#define CONV(x) (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
        CONV(second);
        CONV(minute);
        CONV(hour);
        CONV(day);
        CONV(month);
        CONV(year);
#undef CONV
    }

    *r = t1;
    r->year += 2000;
}

/* ioapic_mmio */

static uint32_t ioapic_read(int reg)
{
    ioapic_mmio->reg = reg;
    return ioapic_mmio->data;
}

static void ioapic_write(int reg, uint32_t data)
{
    ioapic_mmio->reg = reg;
    ioapic_mmio->data = data;
}

void ioapic_enable(int irq, int cpunum)
{
    // Mark interrupt edge-triggered, active high,
    // enabled, and routed to the given cpunum,
    // which happens to be that cpu's APIC ID.
    ioapic_write(REG_TABLE + 2 * irq, T_IRQ0 + irq);
    ioapic_write(REG_TABLE + 2 * irq + 1, cpunum << 24);
}