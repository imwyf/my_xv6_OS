#ifndef _TIME_H_
#define _TIME_H_

#include "types.h"

struct time_GWT {
    uint32_t second;
    uint32_t minute;
    uint32_t hour;
    uint32_t day;
    uint32_t month;
    uint32_t year;
};
#endif /* !_TIME_H_ */