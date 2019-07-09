 
 # Windows MSYS installations
 
 - Install Java JDK
 - Install MSYS2
 - Open the file C:\msys64\mingw64.ini
 - Add a line with content: MSYS2_PATH_TYPE=inherit
 - Start MSYS2 MINGW64: C:\msys64\mingw64.exe
 - Install Make, gcc:  pacman -S make mingw-w64-x86_64-gcc
 - Install ICarus verilog
 
 # Start simulation:
 
 - make single_counter : simple counter test bench
 - make system: System simulation

 # System simulation:
 
 - system/system_tb.v
 - system/instructions.list: Instructions loaded by the testbench when it starts, useful for simple tests
 - At the end of the main "initial", look for the $finish() Line
 	- Activate it  to just run the initial instruction and close the simulation
 	- Comment it out to leave the simulation running and use the Web GUI
 	- Always keep the  $dumpoff(); call, it stops saving the waveform and prevents the simulation to create a large file when running with he software GUI 
 	