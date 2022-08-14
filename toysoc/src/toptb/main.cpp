#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "Vtb.h"  
#include <verilated_vcd_c.h>
#include <verilated.h>
#include "myEmu.hpp"
#include <iostream>
using namespace std;


int pass_cnt = 0;
int fail_cnt = 0;

//sim是verilog仿真输出,real是模拟器输出的真实正确值
void difftest(uint32_t sim, uint32_t real) {
    if (sim == real) {
        pass_cnt++;
        std::cout << "pass!" << std::endl;
    }
    else {
        fail_cnt++;
        std::cout << "fail! sim:" << sim << ";real:" << real << std::endl;
    }
}


vluint64_t main_time = 0;
uint64_t sim_tick = 0;

#define finish_sim 100
int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    //这里Vtb是V+模块的名字,比如模块名叫TEST,那么这里就是VTEST
    Vtb* top = new Vtb("top");
    top->trace(tfp, 0);
    tfp->open("wave.vcd");

    //初始化一次
    {
        top->clk = 1;
        top->rst = 1;
        top->eval();
        top->clk = 0;
        top->rst = 0;
        top->eval();
    }
    int cnt = 0;
    uint8_t rnum;
    //时序仿真
    while (!Verilated::gotFinish() && sim_tick < finish_sim) {
        //高电平触发
        if (main_time % 2 == 0) {
            top->clk = 1;
        }
        else {//时钟低电平
            top->clk = 0;
        }
        top->eval();
        tfp->dump(main_time);
        main_time++;
    }
    top->final();
    tfp->close();
    cout<<"pass_cnt:"<<pass_cnt<<";fail_cnt:"<<fail_cnt<<endl;
    delete top;
    return 0;
}