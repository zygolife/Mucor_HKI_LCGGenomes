#!/usr/bin/bash -l
#SBATCH --time 3-0:00:00 --ntasks 16 --nodes 1 --mem 24G --out logs/annotate_predict.%a.log

module load funannotate
# this will define $SCRATCH variable if you don't have this on your system you can basically do this depending on
# where you have temp storage space and fast disks
module load workspace/scratch

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

BUSCO=mucoromycota_odb10
INDIR=genomes
OUTDIR=annotation
mkdir -p $OUTDIR
SAMPFILE=samples.csv

N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
MAX=$(wc -l $SAMPFILE | awk '{print $1}')

if [ $N -gt $MAX ]; then
    echo "$N is too big, only $MAX lines in $SAMPFILE"
    exit
fi

export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)
export FUNANNOTATE_DB=/bigdata/stajichlab/shared/lib/funannotate_db

SEED_SPECIES=mucor_circinelloides__nrrl_a-25893

IFS=,
SEQCENTER=Jena
PHYLUM="Mucoromycotina"
tail -n +2 $SAMPFILE | sed -n ${N}p | while read BASE FILEBASE SPECIES STRAIN LOCUSTAG BIOSAMPLE BIOPROJECT TYPE
do
    echo "STRAIN is $STRAIN BASE is $BASE LOCUSTAG is $LOCUSTAG"
    name=$BASE
    MASKED=$INDIR/${name}.masked.fasta
       echo "masked is $MASKED ($INDIR/${name}.masked.fasta)"
       if [ ! -f $MASKED ]; then
           echo "no masked file $MASKED"
           exit
       fi
      funannotate predict --cpus $CPU --keep_no_stops --SeqCenter $SEQCENTER \
				  --busco_db $BUSCO --strain $STRAIN --min_training_models 100 \
				  --AUGUSTUS_CONFIG_PATH $AUGUSTUS_CONFIG_PATH \
				  -i $MASKED --name $LOCUSTAG \
				  --protein_evidence $FUNANNOTATE_DB/uniprot_sprot.fasta \
				  -s "$SPECIES" -o $OUTDIR/${name} --busco_seed_species $SEED_SPECIES
done
