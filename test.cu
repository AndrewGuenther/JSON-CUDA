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
//   int numElems = atoi(argv[2]);
//   int dims = atoi(argv[3]);
   int i,j,k;
   i = j = k = 0;
   fprintf(fout, "[\n");
//   for (i = 0; i < 3; i++) {
      fprintf(fout, "   [\n");
//      for (j = 0; j < 2; j++) {
         fprintf(fout, "      [\n");
//         for (k = 0; k < 3; k++)
           fprintf(fout, "         [%d, %.2lf, %d, %d, %.2lf],\n", out[i][j][k].a, out[i][j][k].b, out[i][j][k].c, out[i][j][k].d, out[i][j][k].e);
         fprintf(fout, "      ]\n");
//      }
      fprintf(fout, "   ]\n");
//   }
   fprintf(fout, "]\n");

   return 1;
}
