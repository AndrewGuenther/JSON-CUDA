#include <stdio.h>

#include "culib.h"

int main (void) {
   char *spec;
   char str_spec[] = "int, float32, int, int, float32";
   char json[] = "[12, 1.5, 6, 7, -1.5]";
   GenType out;

   printf("Test Init...\n\n");

   printf("Test Spec: %s\n", str_spec);

   spec = parseSpec(str_spec);

   printf("Parsed Spec: %s\n\n", spec);
   printf("Test JSON: %s\n", json);

   out = parseObjects(json, spec);

   printf("Parsed JSON: %d, %lf, %d, %d, %lf\n", out.i, out.f, out.j, out.k, out.g);

   return 1;
}
