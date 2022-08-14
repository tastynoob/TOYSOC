#pragma once

class tbEmu {
public:
    unsigned char a, c;
    int delay = 0;
    tbEmu():a(0), c(0) {}
    //模拟一个时钟上升沿
    void tick() {
        c += a;
        delay++;
    }
    bool finish() {
        if (delay >= 1) {
            delay = 0;
            return true;
        }
        return false;
    }
};







