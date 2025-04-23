#!/usr/bin/bash -l
#SBATCH -p epyc -c 11 -N 1 -n 1 --mem 24gb --out iqtree.run_partition.log

module load iqtree
IN=mucor_jena_v5.fungi-taxa_139.fa
iqtree2 -s $IN -q muco_jena_v5.fungi-taxa_139.iqtree.part -nt AUTO -B 1000 --alrt 1000
