#!/usr/bin/bash -l
#SBATCH -p short -c 24 --mem 16gb  --out logs/ITSx_on_extracted_regions.log

module load ITSx

CPU=24
OUTDIR=extracted_ITSx__combined
INDIR=extract_ITS__nofilter

mkdir -p $OUTDIR

EXTENSION=ITS2.regions.fasta

for query in $(find $INDIR -name "*.${EXTENSION}")
do
	sp=$(dirname $query)
	sp=$(basename $sp)
	ITSx -t F -cpu $CPU --save_regions all -o $OUTDIR/$sp -i $query --table T 
done

