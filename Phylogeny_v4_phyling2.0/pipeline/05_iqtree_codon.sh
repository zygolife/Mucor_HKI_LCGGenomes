#!/usr/bin/bash -l
#SBATCH -p short
CPU=${SLURM_CPUS_ON_NODE}
if [ -z $CPU ]; then
    CPU=1
fi


module load iqtree

COUNT=$(ls cds/*.fa | wc -l | awk '{print $1}')
for type in fungi mucoromycota
do
	pushd tree-${type}-taxa_${COUNT}
	sbatch --out ${type}.%A.log -p epyc -c 6 --mem 48gb -J iqtree${type} --wrap "iqtree2 -s mucor.${type}-taxa_${COUNT}.fa -p mucor.${type}-taxa_${COUNT}.partition --prefix mucor.${type}-taxa_${COUNT}.codon -m MF+MERGE -rcluster 10 -nt AUTO -st CODON"
	popd
done
