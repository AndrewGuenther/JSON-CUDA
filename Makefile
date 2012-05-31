NVFLAGS=-g -G -arch=compute_20 -code=sm_20
CFLAGS=-g -G -arch=compute_20 -code=sm_20 -c
ALL=culib.o test.o

all:	$(ALL) jsonCuda	

jsonCuda: $(ALL)
	nvcc $(NVFLAGS) $(ALL) -o jsonCuda 

culib.o: culib.cu culib.h
	nvcc $(CFLAGS) -o $@ $<

test.o:	test.cu genType.h dims.h
	nvcc $(CFLAGS) -o $@ $<

clean: 
	rm -f $(ALL) jsonCuda
