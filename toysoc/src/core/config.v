`define xlen 32
`define xlen_def `xlen-1:0

`define ilen 32
`define ilen_def `ilen-1:0

//寄存器索引位宽
`define rfidxlen 5
`define rfidxlen_def (5-1):0

//csr寄存器索引
`define csridxlen 12
`define csridxlen_def 11:0


//当处于仿真模式时,开启下面的宏定义以取代bram的实现
`define SIMULATION 