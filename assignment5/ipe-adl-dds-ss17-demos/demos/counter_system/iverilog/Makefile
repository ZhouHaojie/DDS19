
JAVA_MAIN=kit/ipe/adl/dds/demo/CounterDemoVPI


##  Determine Java Locations quite correctely
ifeq ($(OS),Windows_NT)
	JDK_BASE="$$(which javac)/../.."
	JDK_INC="$$(which javac)/../../include"
	JDK_LIB="$$(which javac)/../../lib"
else
	JDK_BASE=$$(dirname $$(readlink -e $$(which javac)))/..
	JDK_INC=$(JDK_BASE)/include
	JDK_LIB=$(JDK_BASE)/lib
endif

## On Linux, add JDK server folder to path, on windows it should be done from outside MSYS
## The Folder location of the Java software project must be in C:\...\..\app format
## Also the path separator is ":" on Linux and ";" on windows
ifeq ($(OS),Windows_NT)
	PATHADD=
	APP_COMPILATION_OUTPUT=$$(realpath ../../../app/target/classes/ |sed s%/c/%C:\\\\%g | sed s%/%\\\\%g);
else
	PATHADD=$(JDK_BASE)/jre/lib/amd64/server/
	APP_COMPILATION_OUTPUT=$$(realpath ../../../app/target/classes/):
endif

## Single Counter
########################

single_counter: single_counter/run/single_counter_tb
	@cd single_counter/run/ && vvp single_counter_tb
	
single_counter/run/single_counter_tb: single_counter/single_counter_tb.v
	@mkdir -p single_counter/run
	@iverilog -f single_counter_tb.f -o single_counter/run/single_counter_tb
	
## System  -M../../../sw/jvpi/ ../../../sw/jvpi/ -mjvpi
###################
system: jvpi $(JAVA_MAIN) classpath.cp system/run/system
	@echo -n $(APP_COMPILATION_OUTPUT) > system/run/classpath.cp
	@cat classpath.cp >> system/run/classpath.cp
	@echo -n "$(JAVA_MAIN)" > system/run/main.txt
	@cd system/run/ && LD_LIBRARY_PATH="$(PATHADD)" vvp  -M../../../sw/jvpi -mjvpi system
	
system/run/system: system/system_tb.v ../hw/system/counter_system.v
	@mkdir -p system/run
	@iverilog -g2005-sv -f counter_system.f -o system/run/system
	
## VPI
#######################
jvpi:
	@make -C ../sw/jvpi all
	

$(JAVA_MAIN): ../../../app/target/classes/$(JAVA_MAIN).class
	
../../../app/target/classes/$(JAVA_MAIN).class:
	@cd ../../../app && mvn -U compile

classpath.cp: ../../../app/pom.xml
	@mvn -U -f ../../../app/pom.xml dependency:build-classpath -Dmdep.outputFile=$$(pwd)/classpath.cp
	
../../../app/target/classes/:
	@cd ../../../app && mvn -U compile