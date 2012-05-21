#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "culib.h"

int main (int argc, char *argv[]) {
   char *spec;
   char str_spec[] = "int, float32, int, int, float32";
   char *json;
   GenType *out;
   int size;
   int in;
   struct stat st;

   in = open(argv[1], O_RDONLY);
   stat(argv[1], &st);

   json = (char *)malloc(st.st_size * sizeof(char));
   read(in, json, st.st_size);

//   printf("Test Init...\n\n");

//   printf("Test Spec: %s\n", str_spec);

   spec = parseSpec(str_spec);
   size = objSize(spec);

//   printf("Parsed Spec: %s\n\n", spec);
//   printf("Test JSON:   %s\n", json);

   out = (GenType *)parseObjects(json, spec, size);

//   printf("Parsed JSON: ");
   int numElems = atoi(argv[2]);
   printf("[");
   for (int i = 0; i < numElems; i++)
      printf("[%d %.2lf %d %d %.2lf ]\n", out[i].a, out[i].b, out[i].c, out[i].d, out[i].e);
   printf("]");

   return 1;
}
