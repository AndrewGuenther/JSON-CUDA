#JSON CUDA

##Introduction

JSON CUDA was the final project for my Parallel Computing course. The title is somewhat misleading as it does not parse all valid JSON. It is aimed at a very specific case revolving around JSON arrays.

##Input Spec

Input must include a valid JSON array and a struct definition comprised of ints and float32s in the order which they are defined in a corresponding struct

Example:
The struct:
```C
typedef struct {
int a;
float b;
int c;
int d;
float e;
} GenType;
```

Would have the following specification string:
    int, float32, int, int, float32
    
A valid JSON array for this spec would look like this:
```JSON
[[1, 1.23, 4, 5, 6.78], [2, 2.34, 5, 6, 7.89]]
```

Any nxn array of this format can be parsed.

##Output Spec

A char pointer is returned that must be cast to a struct of the specified type and dimension. The caller must know the number of rows ahead of time in order to properly cast the returned pointer. Unfortunately, this is unavoidable because the dimension of the pointer cannot be changed dynamicaaly and must be known at compile time. (If there really is a way to do this, I would love to be proven wrong.)