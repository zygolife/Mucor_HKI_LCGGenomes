#!/usr/bin/bash -l
#SBATCH -p short -c 2 --mem 16gb --out logs/make_mfa_cds.%A.log

CPU=${SLURM_CPUS_ON_NODE}
if [ -z $CPU ]; then
    CPU=1
fi


module load phykit
PREFIX=mucor_jena
COUNT=$(ls cds/*.fa | wc -l | awk '{print $1}')

for type in fungi mucoromycota
do
	STEM=${type}-taxa_${COUNT}
	FILTERDIR=filter-${STEM}
	if [ ! -d $FILTERDIR/selected_MSAs ]; then
		echo "no $FILTERDIR/selected_MSAs folder"
		continue
	fi
	pushd $FILTERDIR/selected_MSAs
	ls *.mfa > filenames
	mkdir -p ../../${FILTERDIR}-buildtree
	phykit create_concat -a filenames -p ../../$FILTERDIR-buildtree/${PREFIX}.${STEM}
	popd
	pushd $FILTERDIR-buildtree
	perl -i -p -e 's/AUTO/DNA/' ${PREFIX}.${STEM}.partition
	sbatch -p epyc -c 48 --mem 128gb -J modeltest$type --out modeltest-${type}.%A.log --wrap "module load modeltest-ng; modeltest-ng -i ${PREFIX}.${STEM}.fa -q ${PREFIX}.${STEM}.partition --processes 48 -T raxml"
	popd
done