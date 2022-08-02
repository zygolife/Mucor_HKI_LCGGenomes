#!/bin/bash -l
#SBATCH -p batch -N 1 -n 24 --mem 64gb --out logs/AAFTF_mito.%a.log

# requires AAFTF 0.3.1 or later for full support of fastp options used

MEM=64
CPU=$SLURM_CPUS_ON_NODE
N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi

module load AAFTF
module load fastp

FASTQ=input
SAMPLEFILE=samples.csv
ASM=asm/mito
WORKDIR=working_AAFTF
PHYLUM=Mucoromycota
mkdir -p $ASM $WORKDIR
if [ -z $CPU ]; then
    CPU=1
fi
IFS=, # set the delimiter to be ,
tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read ID BASE SPECIES STRAIN LOCUSTAG TYPESTRAIN
do
    ASMFILE=$ASM/${ID}.mitochondria.fasta
    CLEANDUP=$ASM/${ID}.rmdup.fasta
    PILON=$ASM/${ID}.pilon.fasta
    SORTED=$ASM/${ID}.sorted.fasta
    STATS=$ASM/${ID}.sorted.stats.txt
    LEFTIN=$FASTQ/${BASE}_R1.fastq.gz
    RIGHTIN=$FASTQ/${BASE}_R2.fastq.gz

    if [ ! -f $LEFTIN ]; then
     echo "no $LEFTIN file for $ID/$BASE in $FASTQ dir"
     exit
    fi
    LEFTTRIM=$WORKDIR/${BASE}_mito_1P.fastq.gz
    RIGHTTRIM=$WORKDIR/${BASE}_mito_2P.fastq.gz

    echo "$BASE $ID $STRAIN"
    if [ ! -f $ASMFILE ]; then # can skip we already have made an assembly
	if [ ! -f $LEFT ]; then
	    if [ ! -f $LEFTTRIM ]; then
		AAFTF trim --method fastp --dedup --memory $MEM --left $LEFTIN --right $RIGHTIN -c $CPU -o $WORKDIR/${BASE}_fastp
		AAFTF trim --method fastp --cutright -c $CPU --memory $MEM --left $WORKDIR/${BASE}_fastp_1P.fastq.gz --right $WORKDIR/${BASE}_fastp_2P.fastq.gz -o $WORKDIR/${BASE}_fastp2
		AAFTF trim --method bbduk -c $CPU --memory $MEM --left $WORKDIR/${BASE}_fastp2_1P.fastq.gz --right $WORKDIR/${BASE}_fastp2_2P.fastq.gz -o $WORKDIR/${BASE}
	    fi
	    AAFTF filter -c $CPU --memory $MEM -o $WORKDIR/${BASE} --left $LEFTTRIM --right $RIGHTTRIM --aligner bbduk
	    if [ -f $LEFT ]; then
		rm -f $LEFTTRIM $RIGHTTRIM $WORKDIR/${BASE}_fastp* 
		echo "found $LEFT"
	    else
		echo "did not create left file ($LEFT $RIGHT)"
		exit
	    fi
	    
	fi
	
	AAFTF mito -c $CPU --left $LEFT --right $RIGHT --memory $MEM \
	      -o $ASMFILE -w $WORKDIR/mito_${ID}
	
	if [ ! -f $ASMFILE ]; then
	    echo "mito must have failed, exiting"
	    exit
	fi
    fi
    
    
    if [ ! -f $CLEANDUP ]; then
    	AAFTF rmdup -i $ASMFILE -o $CLEANDUP -c $CPU -m 500
    fi
    
    if [ ! -f $PILON ]; then
    	AAFTF pilon -i $CLEANDUP -o $PILON -c $CPU --left $LEFT  --right $RIGHT --mem $MEM
    fi
    
    if [ ! -f $PILON ]; then
    	echo "Error running Pilon, did not create file. Exiting"
    	exit
    fi
    
    if [ ! -f $SORTED ]; then
	 AAFTF sort -i $PILON -o $SORTED
    fi
    
    if [ ! -f $STATS ]; then
	AAFTF assess -i $SORTED -r $STATS
    fi
done
