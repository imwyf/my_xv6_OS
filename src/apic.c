
#include "inc/apic.h"
#include "inc/i_kernel.h"
#include <inc/types.h>

extern volatile uint32_t* lapic;

int lapicid(void)
{
    if (!lapic)
        return 0;
    return lapic[ID] >> 24;
}
