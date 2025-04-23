#!/usr/bin/bash -l
#SBATCH -p short --mem 128gb -c 64 --out logs/phyling_align_pep.%A.log
CPU=${SLURM_CPUS_ON_NODE}
if [ -z $CPU ]; then
    CPU=1
fi
module load phyling
COUNT=$(ls pep/*.fa.gz | wc -l | awk '{print $1}')
phyling align -I pep -m mucoromycota_odb10 -o pep-align-mucoromycota-taxa_${COUNT} -t $CPU
time phyling align -I pep -m fungi_odb10 -o pep-align-fungi-taxa_${COUNT} -t $CPU 
