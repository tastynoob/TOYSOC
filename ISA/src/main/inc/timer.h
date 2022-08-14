


#include <stdio.h>




typedef struct {
    int ctrl;
    int lo;
    int hi;
}TIMER_DEF;

#define TIMER_BASE 0xf1000000
#define TIMER ((volatile TIMER_DEF*)TIMER_BASE)





void timer_clear();
__UINT64_TYPE__ timer_getms();