# TOY SOC

该soc是启明星智能组暑期培训所用样例      

toysoc使用toycore内核,可以使用verilator或者iverilog进行仿真      

toycore内核使用rv32I指令集，采用三级状态机实现（取指，译码，访存）          


## coremark跑分     
仿真工作频率1Mhz,平均0.258Coremark/Mhz
![1](https://s2.loli.net/2022/08/14/P168FC94QOtIjZv.png)            

## SOC外设（冯诺依曼结构）

ITCM:0x00000000
DTCM:0x01000000
串口输出:0xf0000000
TIMER定时器:0xf1000000
固件代码见ISA

## 仿真与运行程序 

修改ITCM_CTRL内riscv可执行二进制文件填充地址(mem.list)
该文件可由ISA固件项目生成
ISA项目需要EIDE插件支持
如何编写固件请见ISA目录下readme

### 使用iverilog    
运行toysoc下的run.bat脚本

### 使用verilator       
使用make运行toysoc下的makefile      
```sh   
make gen
make build
make run
```