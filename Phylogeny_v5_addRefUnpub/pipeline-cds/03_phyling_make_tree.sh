#!/usr/bin/bash -l
#SBATCH -c 24 --mem 96gb -p short --out logs/make_tree.%A.log
module load phyling
CPU=${SLURM_CPUS_ON_NODE}
if [ -z $CPU ]; then
    CPU=1
fi

COUNT=$(ls cds/*.fa | wc -l | awk '{print $1}')
phyling tree -I filter-fungi-taxa_${COUNT} -M ft -t $CPU -o tree-fungi-taxa_${COUNT} --verbose 
#phyling tree -I filter-mucoromycota-taxa_${COUNT} -M ft -t $CPU -o tree-mucoromycota-taxa_${COUNT} --verbose 
