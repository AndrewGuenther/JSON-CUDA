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
   GenType **out;
   int size;
   int in;
   struct stat st;

   in = open(argv[1], O_RDONLY);
   stat(argv[1], &st);

   json = (char *)malloc(st.st_size * sizeof(char));
   read(in, json, st.st_size);

   spec = parseSpec(str_spec);
   size = objSize(spec);

   out = (GenType **)parseObjects(json, spec, size);

   FILE *fout = fopen("/tmp/test.out", "w");
   int numElems = atoi(argv[2]);
   int dims = atoi(argv[3]);
   fprintf(fout, "[");
   for (int i = 0; i < dims; i++)
      for (int j = 0; j < (numElems / dims); j++)
         fprintf(fout, "[%d %.2lf %d %d %.2lf ]\n", out[i][j].a, out[i][j].b, out[i][j].c, out[i][j].d, out[i][j].e);
   fprintf(fout, "]");

   return 1;
}
