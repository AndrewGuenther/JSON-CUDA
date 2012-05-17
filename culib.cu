#include <string.h>
#include <stdio.h>

#include "genType.h"
#include "cutil.h"

#define INT '0'
#define FLOAT '1'

#define TO_DEV cudaMemcpyHostToDevice
#define TO_HOST cudaMemcpyDeviceToHost

int objSize(char *spec) {
   int i = 0, size = 0;

   while (spec[i])
      size += (spec[i++] == INT ? sizeof(int) : sizeof(float));

   return size;
}

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

   while (*str && *str - 48 >= 0 && *str - 48 <= 9 && *str != 'e' && *str != '.')
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

#define THREADS_PER_BLOCK 512
#define INITIAL_SIZE 128

__global__ void jsonToObj(char *sObj, char *spec, char *obj, int * starts, int objSize, int numElements) {
   int pos = 0;
   float fres;
   int ires;
   int offset = blockIdx.x * THREADS_PER_BLOCK + threadIdx.x;

   if (offset > numElements)
      return;

   obj += offset * objSize;
   sObj += starts[offset];

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

char * parseObjects(char *json, char *spec, int size) {
   char * dev_json;
   char * dev_obj;
   char * dev_spec;
   int * dev_starts;
   char * out;
   unsigned int numElements = 0;
   unsigned int * starts;
   char * pos = json;

   starts = (unsigned int *)malloc(sizeof(int) * INITIAL_SIZE);
   while (*++pos != '\0') {
      if (*pos == '[' && *(pos + 1) != '[') {
         starts[numElements] = pos - json;
         numElements++;
      }
   }

   printf("%d\n", numElements);
   for (int i = 0; i < numElements; i++)
      printf("%d ", starts[i]);
   printf("\n");
   fflush(stdout);

   out = (char *)malloc(size * numElements);

   CUDA_SAFE_CALL(cudaMalloc((void **) &dev_starts, numElements * sizeof(int)));
   CUDA_SAFE_CALL(cudaMalloc((void **) &dev_json, strlen(json) + 1));
   CUDA_SAFE_CALL(cudaMalloc((void **) &dev_obj, size * numElements));
   CUDA_SAFE_CALL(cudaMalloc((void **) &dev_spec, strlen(spec) + 1));

   CUDA_SAFE_CALL(cudaMemcpy(dev_starts, starts, numElements * sizeof(int), TO_DEV));
   CUDA_SAFE_CALL(cudaMemcpy(dev_spec, spec, strlen(spec) + 1, TO_DEV));
   CUDA_SAFE_CALL(cudaMemcpy(dev_json, json, strlen(json) + 1, TO_DEV));

   dim3 dimBlock(numElements / THREADS_PER_BLOCK + 1);
   dim3 dimThread(THREADS_PER_BLOCK);
   jsonToObj<<<dimBlock, dimThread>>>(dev_json, dev_spec, dev_obj, dev_starts, size, numElements);

   CUDA_SAFE_CALL(cudaMemcpy(out, dev_obj, size * numElements, TO_HOST));

   CUDA_SAFE_CALL(cudaFree(dev_json));
   CUDA_SAFE_CALL(cudaFree(dev_obj));

   return out;
}
