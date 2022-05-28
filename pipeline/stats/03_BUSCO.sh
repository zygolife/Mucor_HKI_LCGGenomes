#!/bin/bash -l
#SBATCH --nodes 1 --ntasks 8 --mem 16G -p short --out logs/busco.%a.log -J busco

# for augustus training
# set to a local dir to avoid permission issues and pollution in global
module unload miniconda3
module load busco
#export AUGUSTUS_CONFIG_PATH=/bigdata/stajichlab/shared/pkg/augustus/3.3/config
export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)

module load workspace/scratch

CPU=${SLURM_CPUS_ON_NODE}
N=${SLURM_ARRAY_TASK_ID}
if [ ! $CPU ]; then
     CPU=2
fi

if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi
GENOMEFOLDER=genomes
EXT=fasta
LINEAGE=ascomycota_odb10
OUTFOLDER=BUSCO
SAMPLEFILE=samples.csv
SEED_SPECIES=anidulans
SAMPLES=samples.csv
mkdir -p $OUTFOLDER

IFS=, # set the delimiter to be ,
tail -n +2 $SAMPLES | sed -n ${N}p | while read ID SAMPID BASE SAMPIDCC SPECIES PHYLUM STRAIN GEOLOC LAT LONG
do
    if [[ "$PHYLUM" == "Basidiomycota" ]]; then
	LINEAGE=basidiomycota_odb10
    fi
    for type in AAFTF shovill
    do
	GENOMEFILE=$GENOMEFOLDER/$STRAIN.$type.$EXT
	if [ -f $GENOMEFILE ]; then
	    NAME=$STRAIN
	    echo "GENOMEFILE is $GENOMEFILE"
	    GENOMEFILE=$(realpath $GENOMEFILE)
	    if [ -d "$OUTFOLDER/${NAME}" ];  then
		echo "Already have run $NAME in folder busco - do you need to delete it to rerun?"
		exit
	    else
		busco -m genome -l $LINEAGE -c $CPU -o ${NAME}.${type} --out_path ${OUTFOLDER} --offline --augustus_species $SEED_SPECIES \
		      --in $GENOMEFILE --download_path $BUSCO_LINEAGES
	    fi
	fi
    done
done
