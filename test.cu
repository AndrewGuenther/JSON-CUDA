#include <stdio.h>

#include "culib.h"

int main (void) {
   char *spec;
   char str_spec[] = "int, float32, int, int, float32";
   char json[] = "[12, 1.5, 6, 7, -1.4]";

   printf("Test Init...\n");

   printf("Test Spec: %s\n", str_spec);

   spec = parseSpec(str_spec);

   printf("Parsed Spec: %s\n", spec);

   

   return 1;
}
