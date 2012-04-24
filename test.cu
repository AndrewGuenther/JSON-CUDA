#include <stdio.h>

#include "cutil.h"
#include "culib.h"

#define TO_DEV cudaMemcpyHostToDevice
#define TO_HOST cudaMemcpyDeviceToHost

int main (void) {
   char *json, *spec;
   char *str_spec = "int, float32, int, int, float32";

   printf("%s", parseSpec(str_spec));

   return 1;
}
