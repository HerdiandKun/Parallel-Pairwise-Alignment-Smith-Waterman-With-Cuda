# Parallel-Pairwise-Alignment-Smith-Waterman-With-Cuda
Parallel Pairwise Alignment Smith Waterman With Cuda 

how to use

you must crawling fasta file from uniprot.org and store in folder with name "Fasta"

Installation
	nvcc SW_GPU.cu -o swseq.exe

using
./swseq.exe [result.txt] [prot_list.csv] [max running sequence] [max thread]

example
./swseq.exe result.txt prot_list.csv 10 5

prot_list.csv is file with sequence id from uniprot.org.