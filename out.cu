#include <stdio.h>
#include "genType.h"

void print (char *uncast, FILE *fout, int A, int B, int C, int D, int E) {
   GenType *****out = (GenType *****)uncast;
   int i,j,k,l,m;
   i = j = k = l = m = 0;
   fprintf(fout, "[");
   for (i = 0; i < E; i++) {
      fprintf(fout, "[");
      for (j = 0; j < D; j++) {
         fprintf(fout, "[");
         for (k = 0; k < C; k++) {
            fprintf(fout, "[");
            for (l = 0; l < B; l++) {
               fprintf(fout, "[");
               for (m = 0; m < A; m++) {
                 fprintf(fout, "[%d,%.1lf,%d,%d,%.1lf]", out[i][j][k][l][m].a, out[i][j][k][l][m].b, out[i][j][k][l][m].c, out[i][j][k][l][m].d, out[i][j][k][l][m].e);
                 if (m < A - 1) 
                   fprintf(fout, ",");
               }
               fprintf(fout, "]");
               if (l < B - 1) 
                 fprintf(fout, ",");
            }
            fprintf(fout, "]");
            if (k < C - 1) 
               fprintf(fout, ",");
         }
         fprintf(fout, "]");
         if (j < D - 1) 
           fprintf(fout, ",");
      }
      fprintf(fout, "]");
      if (i < E - 1) 
         fprintf(fout, ",");
   }
   fprintf(fout, "]");
}
