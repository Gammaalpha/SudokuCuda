
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "chckfnsCuda.cuh"
#include <stdio.h>

#include <iostream>
#include <fstream>
#include <chrono>
#define ORDER 9


using namespace std;

const int ntpb = 9;  //9 threads per blocks

int sudoku[ORDER][ORDER] = { 0 };
int isClueGiven[ORDER][ORDER] = { 0 };
int prevPosition[ORDER][ORDER][2];
int placeNum(int row, int column);
void reportTime(const char* msg, chrono::steady_clock::duration span);

void print(int matrix[ORDER][ORDER]) //host code use only
{
	for (int i = 0; i < ORDER; i++) {
		for (int j = 0; j < ORDER; j++)
			cout << matrix[i][j] << " ";
		cout << endl;
	}

	cout << endl;
	return;
}

//kernel 1 - store position

__global__ void storePositions() //kernel
{
	int temprow, tempcolumn;
	temprow = -1;
	tempcolumn = -1;
	int x = threadIdx.x + blockIdx.x * blockDim.x;
	int y = threadIdx.y + blockIdx.y * blockDim.y;
	
	if (isClueGiven[x][y] == 0) {
		prevPosition[x][y][0] = temprow;
		prevPosition[x][y][1] = tempcolumn;
		temprow = x;
		tempcolumn = y;
	}	
}
__device__ __host__ int goBack(int &row, int &column)
{
	int trow, tcolumn;

	if (row == 0 && column == 0)
		return 0;
	sudoku[row][column] = 0;

	trow = prevPosition[row][column][0];
	tcolumn = prevPosition[row][column][1];
	tcolumn -= 1;

	row = trow;
	column = tcolumn;

	return 1;
}
__device__ __host__ int placeNum(int row, int column)
{
	if (isClueGiven[row][column] == 1)
		return 1;

	for (int num = sudoku[row][column] + 1; num <= 9; num++) {
		if (checkRow(row, num) && checkColumn(column, num) && checkSquare(row, column, num)) {
			sudoku[row][column] = num;
			return 1;
		}
	}

	sudoku[row][column] = 0;

	return 0;
}


__device__ __host__ int solveSudoku(){

	for (int row = 0; row < 9; row++) {
		for (int column = 0; column < 9; column++) {
			if (!placeNum(row, column)) {
				sudoku[row][column] = 0;
				if (!goBack(row, column))
					return 0;
			}
		}
	}
	return 1;
}


int main(int argc, char* argv[])
{
	fstream file;
	chrono::steady_clock::time_point ts, te;

	int nblks = 9;  // hard coded makes sense right? It can only have 9 blocks.


	if (argc == 2)
	{
		file.open(argv[1], ios::in);

		if (file.is_open())
		{
			for (int row = 0; row < ORDER; row++) {
				for (int column = 0; column < ORDER; column++) {
					file >> sudoku[row][column];
					if (sudoku[row][column] != 0)
						isClueGiven[row][column] = 1;
				}
			}
			print(sudoku);
		}
		else
			cout << "Could not locate file ' " << argv[1] << "'. Enter elements manually" << endl;
	}

	if (argc > 2)
		cout << "More than one arguments. Enter elements manually\n";

	if (!file.is_open()) {
		cout << "Enter 81  elements (0s for cells without clues) :" << endl;

		for (int row = 0; row < ORDER; row++) {
			for (int column = 0; column < ORDER; column++) {
				cin >> sudoku[row][column];
				if (sudoku[row][column] != 0)
					isClueGiven[row][column] = 1;
			}
		}

		print(sudoku);
	}

	ts = chrono::steady_clock::now();
	storePositions();
	te = chrono::steady_clock::now();
	reportTime("Position storage time:", te - ts);
	ts = chrono::steady_clock::now();
	solveSudoku();
	te = chrono::steady_clock::now();
	reportTime("Time to solve:", te - ts);
	print(sudoku);
	return 0;
}
// report system time
//
void reportTime(const char* msg, chrono::steady_clock::duration span) {
	auto ms = chrono::duration_cast<chrono::milliseconds>(span);
	std::cout << msg << " - took - " <<
		ms.count() << " millisecs" << std::endl;
	std::cout << "" << std::endl;
}