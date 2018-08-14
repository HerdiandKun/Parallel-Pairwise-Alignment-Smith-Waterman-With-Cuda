// reading a text file
#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <cuda.h>
#include <math.h>
#include "define.h"

#define MATCH       +1
#define MISMATCH    -1
#define GAP         -1
using namespace std;

__global__ void FillMatrix(char **sequence,int *s_length,int n, short int *score,short int **c)
{
  int a = threadIdx.x + blockIdx.x*blockDim.x;
  int b = threadIdx.y + blockIdx.y*blockDim.y;
  int letak,kiri,atas,miring, n_letak, n_atas, n_kiri,x=0,y=0,i;
  const int rows = s_length[a],cols = s_length[b];
    //printf("Masuk %d, %d\n",a,b);
      char *X = sequence[a];
      char *Y = sequence[b];
      
       const int jum = (cols + 1)*(rows + 1);
       
      //printf(" got C pointer: %p\n" , c[(a*(n)) + b]);
      score[(a*(n)) + b] = 0;
      if(b < n && a < n){
        if(b >= a){
          for(i = 0; i < jum;i++)
          {   
            if(i > (cols + 1 )  && (i % (cols+1) != 0))
            {
                y = (i/(cols + 1) - 1);
                x = (i-1) % (cols + 1);
            
                letak = i ;
                kiri  = letak - 1;
                atas  = (letak - cols) - 1 ;
                miring = atas - 1;
                int scoring = scoringsMatrix[X[y] - 'A'][Y[x] - 'A'];    
                n_letak = c[(a*(n)) + b][miring] + scoring;
                n_kiri = c[(a*(n)) + b][kiri] + GAP;
                n_atas = c[(a*(n)) + b][atas] + GAP;
                //c[(a*(n)) + b][miring] = i;
                //c[(a*(n)) + b][letak] = 5;
                if (n_letak > n_atas && n_letak > n_kiri && n_letak > 0) {
                  c[(a*(n)) + b][letak] = n_letak;
                }
                else if (n_atas > n_kiri && n_atas > 0) {
                  c[(a*(n)) + b][letak] = n_atas;
                }
                else if (n_kiri > 0 ){
                  c[(a*(n)) + b][letak] = n_kiri;
                }else {
                  c[(a*(n)) + b][letak] = 0;
                }
                if(score[(a*(n)) + b] < c[(a*(n)) + b][letak]){
                  score[(a*(n)) + b] = c[(a*(n)) + b][letak];
                }
                
            }
            else{
              c[(a*(n)) + b][i] = 0;
            }
          }
        }
      }
}

int main (int argc, char **argv) {
  cudaError_t err = cudaSuccess;
  string line,y, line2, x;
  int i = 0, n,j;

  int *len;
  short int *score;
  short int *dscore;
  int *dlen;

  vector<string> sequence_id;
  vector<string>::iterator it;

  

  ifstream myfile (argv[2]);
  if (myfile.is_open())
  {
    while ( getline (myfile,line) )
    { 
        sequence_id.push_back(line);
    }
    
    myfile.close();
  }
  int size = sequence_id.size();
  n = atoi(argv[3]);
  cout << "Jumlah data : " << n << "\n";
  
  if(n == 0)
    n = size;
     char **sequence = new  char*[size];
     char **dsequence = new  char*[size];

     score    = (short int*)malloc((n *n) * sizeof(short int));
     len    = (int*)malloc(size * sizeof(int));
     
    for(it = sequence_id.begin(); it < sequence_id.end(); it++){
        ifstream myfile2 ("Fasta/" + *it + ".fasta");
        if (myfile2.is_open())
        {
            x = "";
            while ( getline (myfile2,line2) )
            {
            if(line2[0] != '>')  
                    x += line2;
            }
            char *tem = new char[x.length()];
            strcpy(tem,x.c_str());
            sequence[i] = tem;
            delete []tem;
            len[i] = x.length();
            myfile2.close();
        }else{
          sequence_id.erase(it);
        }
        i++;
    }



    cudaMalloc((void**)&dscore, (n *n) * sizeof(short int));
    cudaMalloc((void**)&dlen,size * sizeof(int));

    cudaMallocManaged(&dsequence, size*sizeof(char *));
  
    // initialize dynamic array array
    for (int i = 0; i < size; i++)
    {
      cudaMallocManaged(&(dsequence[i]), len[i]*sizeof(char));
      memcpy(dsequence[i], sequence[i], len[i]);
    }

    err = cudaMemcpy(dscore, score, ((n) *  (n)) * sizeof(short int), cudaMemcpyHostToDevice);
    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy vector B from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
    err = cudaMemcpy(dlen, len,size * sizeof(int), cudaMemcpyHostToDevice);
    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy vector B from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
    short int **dc;
    cudaMallocManaged(&dc, (n + 1) * (n + 1) * sizeof(short int *));
    for(int i = 0; i< n ; i++){
      for(int j = 0; j < n; j++){
         cudaMallocManaged(&(dc[(i*(n)) + j]), (len[i] + 1) * (len[j] + 1) *sizeof(short int));
      }
    }
    
    int t = atoi(argv[4]);
    cout << "Jumlah Thread : " << t << "\n";
    
    //FillMatrix(sequence,n);
    float elapsed=0;
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

     cudaEventRecord(start, 0);

    dim3 threadsPerBlock(t,t);
    int block = n/t!=0?n/t:1;
    block += n%t>0?1:0;
    cout << "Jumlah Block : " << block << "\n" << "Start Calculation \n";
    dim3 blocksPerGrid(block,block);
    int threadsPerLunch((t * t) * (block * block));
    //for(j= 0; j < threadsPerBlock; j++){
    //cudaDeviceSetLimit(cudaLimitMallocHeapSize, threadsPerLunch * (35000 * 35000) * sizeof(int));
    FillMatrix <<<blocksPerGrid, threadsPerBlock>>>(dsequence,dlen,n,dscore,dc);
    //cudaDeviceSynchronize();
    //}
    cudaEventRecord(stop, 0);
    cudaEventSynchronize (stop);

    cudaEventElapsedTime(&elapsed, start, stop);

    cudaEventDestroy(start);
    cudaEventDestroy(stop);


    err = cudaMemcpy(score, dscore, (n*n) * sizeof(short int), cudaMemcpyDeviceToHost);
    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy score from device to host (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    cudaFree(dsequence); cudaFree(dscore); cudaFree(dlen);
    

    ofstream savefile (argv[1]);
    if (savefile.is_open())
    {
      for(int i = 0; i< n ; i++){
        for(int j = 0; j < n; j++){
          if(j >= i)
            savefile << sequence_id.at(i) << "," << sequence_id.at(j) << "," << score[(i*(n)) + j]  << "\n";
          else
            savefile << sequence_id.at(i) << "," << sequence_id.at(j) << "," << score[(j*(n)) + i]  << "\n";
        }
      }
      //savefile << "Waktu Eksekusi " <<  extime; 
      savefile.close();
    }
    else cout << "Unable to open file";
    free(score);free(len);delete[] sequence;
    
    printf("\nwaktu : %f seconds\n ", elapsed/1000);
    return 0;
}