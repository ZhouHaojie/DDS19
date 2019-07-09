all: compile simulate

compile:
	irun -f rtl.lst

simulate:
	irun -gui -access +rw -f rtl.lst

clean:
		@rm -rf INCA_libs  irun.history  *.log irun.key waves.shm 
