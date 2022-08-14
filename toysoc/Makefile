# Makefile for Verilator
gen:
	verilator -y src/core -y src/top -y src/periph --cc src/toptb/tb.v --exe src/toptb/main.cpp  \
	--top-module tb --trace  
build:
	make -C obj_dir -f Vtb.mk 
run:
	./obj_dir/Vtb
wave:
	gtkwave wave.vcd &

clean:
	rm -rf obj_dir wave.vcd