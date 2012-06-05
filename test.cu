#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "culib.h"
#include "out.h"

int main (int argc, char *argv[]) {
   char *spec;
   char str_spec[] = "int, float32, int, int, float32";
   char *json;
   char *out;
   int size;
   int in;
   struct stat st;

   in = open(argv[1], O_RDONLY);
   stat(argv[1], &st);

   json = (char *)malloc(st.st_size * sizeof(char));
   read(in, json, st.st_size);

   spec = parseSpec(str_spec);
   size = objSize(spec);

   out = parseObjects(json, spec, size);

   FILE *fout = fopen("/tmp/test.out", "w");

   print(out, fout, atoi(argv[2]), atoi(argv[3]), atoi(argv[4]), atoi(argv[5]), atoi(argv[6]));

   fclose(fout);
   free(json);
   close(in);

   return 1;
}
