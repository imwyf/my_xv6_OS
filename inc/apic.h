#ifndef _APIC_H_
#define _APIC_H_

/*************************************************************************
 * apic.h - 配置 cpu 的 apic
 *************************************************************************/

// Local APIC registers, divided by 4 for use as uint[] indices.
#include "inc/types.h"
#define ID (0x0020 / 4) // ID
#define VER (0x0030 / 4) // Version
#define TPR (0x0080 / 4) // Task Priority
#define EOI (0x00B0 / 4) // EOI
#define SVR (0x00F0 / 4) // Spurious Interrupt Vector
#define ENABLE 0x00000100 // Unit Enable
#define ESR (0x0280 / 4) // Error Status
#define ICRLO (0x0300 / 4) // Interrupt Command
#define INIT 0x00000500 // INIT/RESET
#define STARTUP 0x00000600 // Startup IPI
#define DELIVS 0x00001000 // Delivery status
#define ASSERT 0x00004000 // Assert interrupt (vs deassert)
#define DEASSERT 0x00000000
#define LEVEL 0x00008000 // Level triggered
#define BCAST 0x00080000 // Send to all APICs, including self.
#define BUSY 0x00001000
#define FIXED 0x00000000
#define ICRHI (0x0310 / 4) // Interrupt Command [63:32]
#define TIMER (0x0320 / 4) // Local Vector Table 0 (TIMER)
#define X1 0x0000000B // divide counts by 1
#define PERIODIC 0x00020000 // Periodic
#define PCINT (0x0340 / 4) // Performance Counter LVT
#define LINT0 (0x0350 / 4) // Local Vector Table 1 (LINT0)
#define LINT1 (0x0360 / 4) // Local Vector Table 2 (LINT1)
#define ERROR (0x0370 / 4) // Local Vector Table 3 (ERROR)
#define MASKED 0x00010000 // Interrupt masked
#define TICR (0x0380 / 4) // Timer Initial Count
#define TCCR (0x0390 / 4) // Timer Current Count
#define TDCR (0x03E0 / 4) // Timer Divide Configuration

#define CMOS_PORT 0x70
#define CMOS_RETURN 0x71
#define CMOS_STATA 0x0a
#define CMOS_STATB 0x0b
#define CMOS_UIP (1 << 7) // RTC update in progress

#define SECS 0x00
#define MINS 0x02
#define HOURS 0x04
#define DAY 0x07
#define MONTH 0x08
#define YEAR 0x09

#define IO_PIC1 0x20 // Master (IRQs 0-7)
#define IO_PIC2 0xA0 // Slave (IRQs 8-15)

#define IOAPIC_MMIO 0xFEC00000 // Default physical address of IO APIC
#define REG_ID 0x00 // Register index: ID
#define REG_VER 0x01 // Register index: version
#define REG_TABLE 0x10 // Redirection table base
// The redirection table starts at REG_TABLE and uses
// two registers to configure each interrupt.
// The first (low) register in a pair contains configuration bits.
// The second (high) register contains a bitmask telling which
// CPUs can serve that interrupt.
#define INT_DISABLED 0x00010000 // Interrupt disabled
#define INT_LEVEL 0x00008000 // Level-triggered (vs edge-)
#define INT_ACTIVELOW 0x00002000 // Active low (vs high)
#define INT_LOGICAL 0x00000800 // Destination is CPU id (vs APIC ID)

// IO APIC MMIO structure: write reg, then read or write data.
struct ioapic_mmio {
    uint32_t reg;
    uint32_t pad[3];
    uint32_t data;
};


#endif /* !_APIC_H_ */