

SHELL=/bin/bash

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



CXXFLAGS=-Wno-write-strings -std=c++11 -I$(JDK_INC) -I$(JDK_INC) 
LDFLAGS=-L$(JDK_LIB) -shared -fpic -lvpi -ljvm 

##  Add Compilation flags depending on System
ifeq ($(OS),Windows_NT)
	CXXFLAGS+=-I$(JDK_INC)/win32 
else
	CXXFLAGS+=-I$(JDK_INC)/linux 
	LDFLAGS+=-L$(JDK_BASE)/jre/lib/amd64/server/

endif

all: jvpi.vpi

jvpi.vpi: jvpi.cpp
	@echo "JDK...$(JDK_BASE)"
	@echo "CXXFLAGS=$(CXXFLAGS)"
	@g++ $(CXXFLAGS) jvpi.cpp $(LDFLAGS)  -o jvpi.vpi
	