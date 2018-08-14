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

void FillMatrix(const string *sequence, int n, int *scoring)
{
  int rows,cols;
  int *c;
  for(int a = 0; a< n; a++){
    for(int b = 0; b < n; b++){
      string X = sequence[a];
      string Y = sequence[b];
      rows = X.length();
      cols = Y.length();
      c = (int*)malloc(((cols + 1)*(rows + 1)) * sizeof(int));

      int score = 0;
        int letak,kiri,atas,miring, n_letak, n_atas, n_kiri,x=0,y=0,i;
        int jum = (cols + 1)*(rows + 1);
      
        for(i = 0; i< jum;i++)
        {   
          if(i > (cols + 1 )  && (i % (cols+1) != 0))
          {
          y = (i/(cols + 1) - 1);
          x = (i-1) % (cols + 1);
      
          letak = i ;
          kiri  = letak - 1;
          atas  = (letak - cols) - 1 ;
          miring = atas - 1;    
                //c[letak] = atas;
                //printf("%d - %d = %.0f \n", X[y]  - 'A', Y[x]  - 'A' , scoringsMatrixHost[X[y] - 'A'][Y[x] - 'A']);
                n_letak = c[miring] + scoringsMatrixHost[X[y] - 'A'][Y[x] - 'A'];
                n_kiri = c[kiri] + GAP;
                n_atas = c[atas] + GAP;
                //printf("MIRING %d - KIRI %d - ATAS %d\n", c[miring], c[kiri], c[atas]);
          
                if (n_letak > n_atas && n_letak > n_kiri && n_letak > 0) {
                  c[letak] = n_letak;
                }
                else if (n_atas > n_kiri && n_atas > 0) {
                  c[letak] = n_atas;
                }
                else if (n_kiri > 0 ){
                  c[letak] = n_kiri;
                }else {
                  c[letak] = 0;
                }
                if(score < c[letak]){
                  score = c[letak];
                }
            }
            else{
                c[i] = 0;
            }
        } 
        scoring[(a*(n)) + b] = score;
        //cout << "Score "<< a <<"-"<<b<<" : " << score << "\n";
        free(c);
        //return score;
    }
  }
}

int main (int argc, char **argv) {
  string line,x,y,line2;
  int i = 0, n;
  int *score;

  vector<string> sequence_id;
  vector<string>::iterator it;

  ifstream myfile ("prot_list.csv");
  if (myfile.is_open())
  {
    while ( getline (myfile,line) )
    { 
        sequence_id.push_back(line);
    }
    
    myfile.close();
  }
  //else cout << "Unable to open file";
  cin >> n;
  if(n == 0)
    n = sequence_id.size();
    int size = sequence_id.size();
    string *sequence =  new string[size];

    score    = (int*)malloc((n *n) * sizeof(int));
    
    for(it = sequence_id.begin(); it < sequence_id.end(); it++){
        ifstream myfile2 ("Fasta/" + *it + ".fasta");
        if (myfile2.is_open())
        {
            x="";
            while ( getline (myfile2,line2) )
            {
            if(line2[0] != '>')  
                    x += line2;
            }
            sequence[i] = x;
            //cout << "X : " <<  x << "\n"; 
            myfile2.close();
        }else{
          sequence_id.erase(it);
        }
        //else cout << *it << " Unable to open file \n"; 
        i++;
    }

    cout << sequence_id.size();
    clock_t start, end;
    start = clock();
    FillMatrix(sequence,n,score);
    end = clock();
  	double extime = (double)(end - start) / CLOCKS_PER_SEC;
    //free(score);free(sequence);

    ofstream savefile (argv[1]);
    if (savefile.is_open())
    {
      for(int i = 0; i< n ; i++){
        for(int j = 0; j < n; j++){
          savefile << sequence_id.at(i) << "," << sequence_id.at(j) << "," << score[(i*(n)) + j]  << "\n";
        }
      }
      savefile.close();
    }
    else cout << "Unable to open file";
    //free(score);free(sequence);
    printf("\nwaktu : %f seconds\n ", extime);
    return 0;

}