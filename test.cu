#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "culib.h"
#include "dims.h"

int main (int argc, char *argv[]) {
   char *spec;
   char str_spec[] = "int, float32, int, int, float32";
   char *json;
   GenType ***out;
   int size;
   int in;
   struct stat st;

   in = open(argv[1], O_RDONLY);
   stat(argv[1], &st);

   json = (char *)malloc(st.st_size * sizeof(char));
   read(in, json, st.st_size);

   spec = parseSpec(str_spec);
   size = objSize(spec);

   out = (GenType ***)parseObjects(json, spec, size);

   FILE *fout = fopen("/tmp/test.out", "w");

//   printf("%x\n", out);   
   
   
//   int numElems = atoi(argv[2]);
//   int dims = atoi(argv[3]);
   int i,j,k;
   i = j = k = 0;
   fprintf(fout, "[");
   for (i = 0; i < C; i++) {
      fprintf(fout, "[");
      for (j = 0; j < B; j++) {
         fprintf(fout, "[");
         for (k = 0; k < A; k++) {
           fprintf(fout, "[%d,%.1lf,%d,%d,%.1lf]", out[i][j][k].a, out[i][j][k].b, out[i][j][k].c, out[i][j][k].d, out[i][j][k].e);
           if (k < A - 1) 
             fprintf(fout, ",");
         }
         fprintf(fout, "]");
         if (j < B - 1) 
           fprintf(fout, ",");
      }
      fprintf(fout, "]");
      if (i < C - 1) 
         fprintf(fout, ",");
   }
   fprintf(fout, "]");

   return 1;
}
