#include <stdio.h>

#include "culib.h"

int main (void) {
   char *spec;
   char str_spec[] = "int, float32, int, int, float32";
   char json[] = "[[[12, 1.5, 6, 7, -1.5],[1, 2.0, 3, 4, 5.0]],[[6, 7.0, 8, 9, 10.0],[11, 12.0, 13, 14, 15.0]]]";
   GenType *out;
   int size;

   printf("Test Init...\n\n");

   printf("Test Spec: %s\n", str_spec);

   spec = parseSpec(str_spec);
   size = objSize(spec);

   printf("Parsed Spec: %s\n\n", spec);
   printf("Test JSON: %s\n", json);

   out = (GenType *)parseObjects(json, spec, size);

   for (int i = 0; i < 4; i++)
      printf("Parsed JSON: %d, %lf, %d, %d, %lf\n", out[i].a, out[i].b, out[i].c, out[i].d, out[i].e);

   return 1;
}
