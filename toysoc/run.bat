iverilog -o wave -y src/core/ -y src/periph -y src/top -I ./src/core ./src/toptb/tb.v
vvp wave