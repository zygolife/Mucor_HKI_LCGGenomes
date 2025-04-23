#!/usr/bin/bash -l
#SBATCH -p short

CPU=${SLURM_CPUS_ON_NODE}
if [ -z $CPU ]; then
    CPU=1
fi

module load iqtree
PREFIX=mucor_jena
COUNT=$(ls cds/*.fa | wc -l | awk '{print $1}')
for type in fungi mucoromycota
do
	pushd filter-${type}-taxa_${COUNT}-buildtree
	sbatch --out iqtree.${type}.bic.%A.log -p epyc -c 6 --mem 48gb -J iqtree${type} --wrap "iqtree2 -s ${PREFIX}.${type}-taxa_${COUNT}.fa -p ${PREFIX}.${type}-taxa_${COUNT}.fa.part.bic -m MF+MERGE -rcluster 10 -nt AUTO"
	sbatch --out iqtree.${type}.aic.%A.log -p epyc -c 6 --mem 48gb -J iqtree${type} --wrap "iqtree2 -s ${PREFIX}.${type}-taxa_${COUNT}.fa -p ${PREFIX}.${type}-taxa_${COUNT}.fa.part.aic -m MF+MERGE -rcluster 10 -nt AUTO"
	popd
done
