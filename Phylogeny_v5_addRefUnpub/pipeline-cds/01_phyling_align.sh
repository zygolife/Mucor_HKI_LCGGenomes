#!/usr/bin/bash -l
#SBATCH -p short --mem 128gb -c 64 --out logs/phyling_align.%A.log
CPU=${SLURM_CPUS_ON_NODE}
if [ -z $CPU ]; then
    CPU=1
fi

module load phyling
COUNT=$(ls cds/*.fa | wc -l | awk '{print $1}')
#time phyling align -I cds -m mucoromycota_odb10 -o align-mucoromycota-taxa_${COUNT} -t $CPU --verbose
time phyling align -I cds -m fungi_odb10 -o align-fungi-taxa_${COUNT} -t $CPU --verbose

