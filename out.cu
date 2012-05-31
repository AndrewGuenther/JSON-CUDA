#include <stdio.h>
#include "genType.h"
#include "dims.h"

void print (char *uncast, FILE *fout) {
   GenType ***out = (GenType ***)uncast;
   int i,j,k;
   i = j = k = 0;
   fprintf(fout, "[");
   for (i = 0; i < C; i++) {
      fprintf(fout, "[");
      for (j = 0; j < B; j++) {
         fprintf(fout, "[");
         for (k = 0; k < A; k++) {
           fprintf(fout, "[%d,%.1lf,%d,%d,%.1lf]", out[i][j][k].a, out[i][j][k].b, out[i][j][k].c, out[i][j][k].d, out[i][j][k].e);
           if (k < A - 1) 
             fprintf(fout, ",");
         }
         fprintf(fout, "]");
         if (j < B - 1) 
           fprintf(fout, ",");
      }
      fprintf(fout, "]");
      if (i < C - 1) 
         fprintf(fout, ",");
   }
   fprintf(fout, "]");
}
