



fifo:
	@iverilog -g2005-sv -g2012 -o fifo_tb fifo_tb.v fifo.v
	@vvp fifo_tb

fifo_reg:
	@iverilog -DFIFO_RAM=0 -DFIFO_MEM -g2005-sv -g2012 -o fifo_tb fifo_tb.v fifo_mem.v mem_reg.v
	@vvp fifo_tb

fifo_ram:
	@iverilog -DFIFO_RAM=1 -DFIFO_MEM -g2005-sv -g2012 -o fifo_tb fifo_tb.v fifo_mem.v mem_ram.v ram.v SJKA65_512X32X1CM4.v
	@vvp fifo_tb


irun_fifo:
	@irun -gui -sv -access +rw +define+IRUN fifo_tb.v fifo.v
