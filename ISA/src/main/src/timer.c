#include "timer.h"







void timer_clear() {

}
//1Mhz
__UINT64_TYPE__ timer_getms() {
    unsigned lo = TIMER->lo;
    unsigned hi = TIMER->hi;
    return (((__UINT64_TYPE__)hi << 32) | lo) / 1000;
}