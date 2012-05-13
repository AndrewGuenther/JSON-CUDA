NVFLAGS=-g -G -arch=compute_20 -code=sm_20
# list .c and .cu source files here
SRCFILES=culib.cu test.cu

all:	jsonCuda	

jsonCuda: $(SRCFILES) 
	nvcc $(NVFLAGS) -o jsonCuda $^

clean: 
		rm -f *.o jsonCuda
