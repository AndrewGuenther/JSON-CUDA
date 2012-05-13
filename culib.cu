#include <string.h>
#include <stdio.h>

#include "genType.h"
#include "cutil.h"

#define INT '0'
#define FLOAT '1'

#define TO_DEV cudaMemcpyHostToDevice
#define TO_HOST cudaMemcpyDeviceToHost


char * parseSpec(char *str_spec) {
   char *tok;
   char *spec;
   char i = 0;

   //This is the absolute largest the spec could be
   //assuming it consisted entirely of
   //"int,int,int,int..."
   spec = (char *)malloc((unsigned int)strlen(str_spec) / 4);

   tok = strtok(str_spec, ", ");
   while (tok != NULL) {
      if (!strcmp(tok, "int"))
         spec[i] = INT;
      else
         spec[i] = FLOAT;
      i++;
      tok = strtok(NULL, ", ");
   }
   spec[i] = '\0';

   return spec;
}

__device__ int cudaStrtoi (char *str, char **end) {
   int i = 0;
   char neg = 0;

   while ((*str - 48 < 0 || *str - 48 > 9) && (*str != '-' && *str != '\0' && *str != '.'))
      *str++;

   if (*str == '-') {
      *str++;
      neg = 1;
   }

   while (*str && *str - 48 > 0 && *str - 48 <= 9 && *str != 'e' && *str != '.')
      i = (i << 3) + (i << 1) + ((*str++) - '0');

   *end = str;
   return neg ? -i : i;
}

__device__ float cudaStrtof (char *str, char **end) {
   float f;

   f = cudaStrtoi(str, &str);

   if (*str == '.') {
      *str++;
      char *pos = str;
      f += (f >= 0 ? 1 : -1) * (float)cudaStrtoi(str, &str) / exp10f(str - pos);
   }

   if (*str == 'e') {
      *str++;
      f *= exp10f(cudaStrtoi(str, &str));
   }

   *end = str;
   return f;
}

__device__ int cudaAtoi (char *str) {
   return cudaStrtoi (str, NULL);
}

__device__ float cudaAtof (char *str) {
   return cudaStrtof(str, NULL);
}

__global__ void jsonToObj(char *sObj, char *spec, char *obj) {
   int pos = 0;
   float fres;
   int ires;

   for (int i = 0; spec[i] != '\0'; i++) {
      if (spec[i] == INT) {
         ires = cudaStrtoi(sObj, &sObj);
         memcpy((obj + pos), &ires, sizeof(int));
         pos += sizeof(int);
      }
      else {
         fres = cudaStrtof(sObj, &sObj);
         memcpy((obj + pos), &fres, sizeof(float));
         pos += sizeof(float);
      }
   }
}

GenType parseObjects(char *json, char *spec) {
   char * dev_json;
   char * dev_obj;
   char * dev_spec;
   GenType out;

   CUDA_SAFE_CALL(cudaMalloc((void **) &dev_json, strlen(json) + 1));
   CUDA_SAFE_CALL(cudaMalloc((void **) &dev_obj, sizeof(GenType)));
   CUDA_SAFE_CALL(cudaMalloc((void **) &dev_spec, strlen(spec) + 1));

   CUDA_SAFE_CALL(cudaMemcpy(dev_spec, spec, strlen(spec) + 1, TO_DEV));
   CUDA_SAFE_CALL(cudaMemcpy(dev_json, json, strlen(json) + 1, TO_DEV));

   jsonToObj<<<1, 1>>>(dev_json, dev_spec, dev_obj);

   CUDA_SAFE_CALL(cudaMemcpy((char *) &out, dev_obj, sizeof(GenType), TO_HOST));

   CUDA_SAFE_CALL(cudaFree(dev_json));
   CUDA_SAFE_CALL(cudaFree(dev_obj));

   return out;
}
