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
#define ARRS_SIZE 1024

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

   CUDA_SAFE_CALL(cudaMalloc((void **) &dev_obj, size * numElements));

   dim3 dimBlock(numElements / THREADS_PER_BLOCK + 1);
   dim3 dimThread(THREADS_PER_BLOCK);

   jsonToObj<<<dimBlock, dimThread>>>(dev_json, dev_spec, dev_obj, dev_starts, size, numElements);

   out = (char *)malloc(size * numElements);

   CUDA_SAFE_CALL(cudaMemcpy(out, dev_obj, size * numElements, TO_HOST));

   return out;
}

int depth;

char * setupArray(char *json, char *pos, char **newpos) {
   unsigned int *starts, *dev_starts;
   char *out;
   int balance = 0;
   unsigned int numElements = 0;
   unsigned int startsSize = INITIAL_SIZE;  
//   GenType * debug_out;
   
   starts = (unsigned int *)malloc(sizeof(int) * INITIAL_SIZE);

//   printf("setupArray: ");
   do {
      if (*pos == '[') {
         balance++;
         starts[numElements] = pos - json;
         numElements++;
         if (numElements >= startsSize) {
            startsSize += INITIAL_SIZE;
            starts = (unsigned int *)realloc(starts, (sizeof(int) * startsSize));
         }
      }
      else if (*pos == ']')
         balance--;
//      printf("%c", *pos);
      fflush(stdout);
   } while (*++pos != '\0' && balance >= 0);

//   printf("\n");
   *newpos = pos - 1;

   CUDA_SAFE_CALL(cudaMalloc((void **) &dev_starts, numElements * size));
   CUDA_SAFE_CALL(cudaMemcpy(dev_starts, starts, numElements * sizeof(int), TO_DEV));

   out = parseArray(dev_starts, numElements);
//   debug_out = (GenType *)out;
//   for (int i = 0; i < numElements; i++)
//      printf("%d, %.2lf, %d, %d, %.2lf\n", debug_out[i].a, debug_out[i].b, debug_out[i].c, debug_out[i].d, debug_out[i].e);

   CUDA_SAFE_CALL(cudaFree(dev_starts));

   return out;
}

char * findArrays(char *json, char *pos, char **newpos) {
   char *out;
   char **arrs;
   unsigned int arrs_size = ARRS_SIZE;
   int i = 0, balance = 0;
   char parsed = 0;

   arrs = (char **)malloc(arrs_size * sizeof(char **));

   pos++;
//   printf("Find arrays %d: ", depth);
   if (*pos == '[') {
      if(*(pos + 1) != '[') {
  
//         printf("%c", *pos);
//         printf("\n");
         out = setupArray(json, pos, &pos);
//         printf("%x\n", out);
//         printf("%c", *pos);
         parsed = 1;
      }
      else {
         do {
            if (*pos == '[') {
               balance++;
//               printf("\n");
               depth++;
//               printf("down\n");
               arrs[i] = findArrays(json, pos, &pos);
               i++;
               if (i >= arrs_size) {
                  printf("resizing\n");
                  arrs_size += ARRS_SIZE;
                  arrs = (char **)realloc(arrs, (arrs_size * sizeof(char **)));
               }
//               printf("up\n");
               depth--;
            }
            if (*pos == ']')
               balance--;
//            printf("%c", *pos);
            fflush(stdout);
         } while (*++pos != '\0' && balance >= 0);
      }
   }

//   printf("\n");
   *newpos = pos;


   if (parsed)
      return out;
   else {
//      printf("%x: ", arrs);
//      for (int j = 0; j < i; j++)
//         printf("%x, ", arrs[j]);
//      printf("\n");

      return (char *)arrs;
   }
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
