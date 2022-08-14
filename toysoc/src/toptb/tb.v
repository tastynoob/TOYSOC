module tb (
    // input clk,
    // input rst
);

initial begin
    // $dumpfile("wave.vcd");
    // $dumpvars(0, tb);
    // #10000000;
    // $finish;
end


reg clk=0;
reg rst=0;
always #1 clk = ~clk;

initial begin
    #1 rst = 1;
    #2 rst = 0;
end

SOC_TOP u_SOC_TOP(
    .i_clk ( clk ),
    .i_rst  ( rst  )
);




endmodule
