#ifndef CHECKFNS_H
#define CHECKFNS_H
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
__device__ __host__ int checkRow(int row, int num);
__device__ __host__ int checkColumn(int column, int num);
__device__ __host__ int checkSquare(int row, int column, int num);
__device__ __host__ int checkSolution();

#endif /* CHECKS_H */
