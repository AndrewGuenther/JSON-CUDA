#include <string.h>
#include <stdio.h>

#include "genType.h"
#include "cutil.h"

#define INT '0'
#define FLOAT '1'

#define TO_DEV cudaMemcpyHostToDevice
#define TO_HOST cudaMemcpyDeviceToHost

int objSize(char *spec) {
   int i = 0, objSize = 0;

   while (spec[i])
      objSize += (spec[i++] == INT ? sizeof(int) : sizeof(float));

   return objSize;
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
   char neg = 0;

   while ((*str - 48 < 0 || *str - 48 > 9) && (*str != '-' && *str != '\0' && *str != '.'))
      *str++;

   if (*str == '-') {
      *str++;
      neg = 1;
   }

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
   return neg ? -f : f;
}

__device__ int cudaAtoi (char *str) {
   return cudaStrtoi (str, NULL);
}

__device__ float cudaAtof (char *str) {
   return cudaStrtof(str, NULL);
}

#define THREADS_PER_BLOCK 512
#define INITIAL_SIZE 1024

__global__ void jsonToObj(char *sObj, char *spec, char *obj, unsigned int * starts, int objSize, int numElements) {
   float fres;
   int ires;
   unsigned int offset = blockIdx.x * blockDim.x + threadIdx.x;

   if (offset >= numElements)
      return;

   obj += offset * objSize;
   sObj += starts[offset];

   for (int i = 0; spec[i] != '\0'; i++) {
      if (spec[i] == INT) {
         ires = cudaStrtoi(sObj, &sObj);
         memcpy(obj, &ires, sizeof(int));
         obj += sizeof(int);
      }
      else {
         fres = cudaStrtof(sObj, &sObj);
         memcpy(obj, &fres, sizeof(float));
         obj += sizeof(float);
      }
   }
}

char *dev_json, *dev_spec;
int size;

char * parseArray(unsigned int *dev_starts, int numElements) {
   char * dev_obj;
   char * out;

   printf("called\n");

   CUDA_SAFE_CALL(cudaMalloc((void **) &dev_obj, size * numElements));

   dim3 dimBlock(numElements / THREADS_PER_BLOCK + 1);
   dim3 dimThread(THREADS_PER_BLOCK);

   jsonToObj<<<dimBlock, dimThread>>>(dev_json, dev_spec, dev_obj, dev_starts, size, numElements);

   out = (char *)malloc(size * numElements);

   CUDA_SAFE_CALL(cudaMemcpy(out, dev_obj, size * numElements, TO_HOST));

   return out;
}

int depth;

char * findArrays(char *json, char *pos, char **newpos) {
   unsigned int *starts, *dev_starts;
   char *out;
   char **arrs;
   int i = 0;
   char parsing = 1;
   unsigned int numElements = 0;
   unsigned int startsSize = INITIAL_SIZE;

   printf("depth: %d\n", depth);
   depth++;

   starts = (unsigned int *)malloc(sizeof(int) * INITIAL_SIZE);
   arrs = (char **)malloc(5 * sizeof(char **));

   do {
      if (*pos == '[') {
         if (*(pos + 2) != '[') {
            starts[numElements] = pos - json;
            numElements++;
            if (numElements >= startsSize) {
               startsSize += INITIAL_SIZE;
               starts = (unsigned int *)realloc(starts, (sizeof(int) * startsSize));
            }
         }
         else {
            arrs[i] = findArrays(json, pos + 1, &pos);
            i++;
            printf("%c\n", *pos);
            parsing = 0; 
         }
      }
   } while (*++pos != '\0');

   *newpos = pos;
   depth--;

   if (parsing) {
      CUDA_SAFE_CALL(cudaMalloc((void **) &dev_starts, numElements * size));
      CUDA_SAFE_CALL(cudaMemcpy(dev_starts, starts, numElements * sizeof(int), TO_DEV));

      out = parseArray(dev_starts, numElements);

      CUDA_SAFE_CALL(cudaFree(dev_starts));

      return out;
   }
   else
      return (char *)arrs;

}

char * parseObjects(char *json, char *spec, int objSize) {
   char *out;
   char *pos = json;

   size = objSize;
   depth = 0;

   CUDA_SAFE_CALL(cudaMalloc((void **) &dev_json, strlen(json) + 1));
   CUDA_SAFE_CALL(cudaMalloc((void **) &dev_spec, strlen(spec) + 1)); //Make this constant mem

   CUDA_SAFE_CALL(cudaMemcpy(dev_spec, spec, strlen(spec) + 1, TO_DEV));
   CUDA_SAFE_CALL(cudaMemcpy(dev_json, json, strlen(json) + 1, TO_DEV));

   out = findArrays(json, pos, &pos);

   CUDA_SAFE_CALL(cudaFree(dev_spec));
   CUDA_SAFE_CALL(cudaFree(dev_json));

   return out;
}
