#include <string.h>
#include <stdio.h>

#include "genType.h"

#define INT '0'
#define FLOAT '1'

char * parseSpec(char *str_spec) {
   char *tok;
   char *spec;
   char i = 0;

   //This is the absolute largest the spec could be
   //assuming it consisted entirely of
   //"int,int,int,int..."
   spec = (char *)malloc((unsigned int)strlen(str_spec) / 4);

   printf("%s\n", str_spec);
   fflush(stdout);

   tok = strtok(str_spec, ", ");
   while (tok != NULL) {
      if (!strcmp(tok, "int"))
         spec[i] = INT;
      else
         spec[i] = FLOAT;
      i++;
      tok = strtok(NULL, ", ");
   }

   return spec;
}

void parseObjects(char *json, char *spec) {
   
}

__global__ void jsonToObj(char *obj, char *spec) {

}

__device__ int cudaStrtoi (char *str, char **end) {
   int i = 0;
   char neg = 0;

   if (*str == '-') {
      *str++;
      neg = 1;
   }

   while (*str && *str != 'e' && *str != '.')
      i = (i << 3) + (i << 1) + ((*str++) - '0');

   *end = str;
   return neg ? -i : i;
}

__device__ int cudaAtoi (char *str) {
  return cudaStrtoi (str, &str);
}


__device__ float cudaAtof (char *str) {
   float f;

   f = cudaStrtoi(str, &str);

   if (*str == '.') {
      *str++;
      char *pos = str;
      f += (float)cudaStrtoi(str, &str) / exp10f(str - pos);
   }

   if (*str == 'e') {
      *str++;
      f *= exp10f(cudaStrtoi(str, &str));
   }

   return f;
}
