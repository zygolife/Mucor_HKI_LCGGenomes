#!/usr/bin/bash -l
#SBATCH -p short -c 48 --mem 48gb  --out logs/pep_raxmlng.log


CPU=${SLURM_CPUS_ON_NODE}
if [ -z $CPU ]; then
    CPU=1
fi

module load raxml-ng
module load modeltest-ng
PREFIX=pep-muco_jena
COUNT=$(ls pep/*.fa.gz | wc -l | awk '{print $1}')
for type in fungi
	#mucoromycota
do
	STEM=${type}-taxa_${COUNT}
	TREEDIR=pep-filter-${STEM}-buildtree
	if [ ! -d $TREEDIR ]; then
		echo "no $TREEDIR folder"
		continue
	fi
	if [ ! -s $TREEDIR/${PREFIX}.${STEM}.fa.part.aic ]; then
		echo "no $TREEDIR/${PREFIX}.${STEM}.fa.part.aic"
		continue
	fi

	pushd $TREEDIR
	for MODELSCORE in aic bic
	do
		raxml-ng --parse --msa ${PREFIX}.${STEM}.fa --model ${PREFIX}.${STEM}.fa.part.${MODELSCORE} --prefix=${PREFIX}.${STEM}.${MODELSCORE}
		CPURUN=$(grep 'Recommended number of threads' ${PREFIX}.${STEM}.${MODELSCORE}.raxml.log | cut -d: -f2 | tail -n 1 | awk '{print $1}')
		sbatch --out ${PREFIX}.${STEM}.${MODELSCORE}.%A.log -J ${PREFIX}.${STEM}.${MODELSCORE} -p epyc -c $CPURUN --mem 48gb --wrap "module load raxml-ng; raxml-ng --all --msa ${PREFIX}.${STEM}.${MODELSCORE}.raxml.rba --threads auto{$CPURUN} --tree pars{10}  --bs-trees 100"
	done
	popd
done
