NVFLAGS=-g -G -arch=compute_20 -code=sm_20
CFLAGS=-g -G -arch=compute_20 -code=sm_20 -c
#NVFLAGS=-O3 -arch=compute_20 -code=sm_20
#CFLAGS=-O3 -arch=compute_20 -code=sm_20 -c
ALL=culib.o out.o test.o
BENCH=culib.o out.o 

all:	$(ALL) jsonCuda

jsonCuda: $(ALL)
	nvcc $(NVFLAGS) $(ALL) -o jsonCuda 

culib.o: culib.cu culib.h
	nvcc $(CFLAGS) -o $@ $<

test.o:	test.cu genType.h dims.h printOut.h
	nvcc $(CFLAGS) -o $@ $<

out.o:	out.cu printOut.h dims.h
	nvcc $(CFLAGS) -o $@ $<

clean: 
	rm -f $(ALL) jsonCuda
