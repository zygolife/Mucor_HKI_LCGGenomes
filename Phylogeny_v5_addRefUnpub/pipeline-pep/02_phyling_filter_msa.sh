#!/usr/bin/bash -l
#SBATCH -c 24 --mem 96gb --out logs/filter_aln_pep.%A.log
module load phyling
CPU=${SLURM_CPUS_ON_NODE}
if [ -z $CPU ]; then
    CPU=1
fi

COUNT=$(ls pep/*.fa.gz | wc -l | awk '{print $1}')
#phyling filter -I pep-align-mucoromycota-taxa_${COUNT} -t $CPU -o pep-filter-mucoromycota-taxa_${COUNT} --verbose -n 50
phyling filter -I pep-align-fungi-taxa_${COUNT} -t $CPU -o pep-filter-fungi-taxa_${COUNT} --verbose -n 50
