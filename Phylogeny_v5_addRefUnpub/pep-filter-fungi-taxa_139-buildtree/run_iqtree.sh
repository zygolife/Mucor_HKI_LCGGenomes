#!/usr/bin/bash -l
#SBATCH -p epyc -c 11 -N 1 -n 1 --mem 24gb --out iqtree.run_partition.log

module load iqtree
CPU=11
iqtree2 -s pep-muco_jena_v5.fungi-taxa_139.fa -q pep-muco_jena_v5.fungi-taxa_139.iqtree.part -nt $CPU -B 1000 --alrt 1000
