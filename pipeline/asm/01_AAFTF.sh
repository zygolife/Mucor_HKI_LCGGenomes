#!/bin/bash -l
#SBATCH -p batch -N 1 -n 24 --mem 256gb --out logs/AAFTF.%a.log

MEM=256
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
ASM=asm/AAFTF
WORKDIR=working_AAFTF
mkdir -p $ASM $WORKDIR
if [ -z $CPU ]; then
    CPU=1
fi
IFS=, # set the delimiter to be ,
tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read ID BASE SPECIES STRAIN LOCUSTAG TYPESTRAIN
do
    ASMFILE=$ASM/${ID}.spades.fasta
    VECCLEAN=$ASM/${ID}.vecscreen.fasta
    PURGE=$ASM/${ID}.sourpurge.fasta
    CLEANDUP=$ASM/${ID}.rmdup.fasta
    PILON=$ASM/${ID}.pilon.fasta
    SORTED=$ASM/${ID}.sorted.fasta
    STATS=$ASM/${ID}.sorted.stats.txt
    LEFTIN=$FASTQ/${BASE}_R1_001.fastq.gz
    RIGHTIN=$FASTQ/${BASE}_R2_001.fastq.gz

    if [ ! -f $LEFTIN ]; then
     echo "no $LEFTIN file for $ID/$BASE in $FASTQ dir"
     exit
    fi
    LEFTTRIM=$WORKDIR/${BASE}_1P.fastq.gz
    RIGHTTRIM=$WORKDIR/${BASE}_2P.fastq.gz
    LEFTF=$WORKDIR/${BASE}_filtered_1.fastq.gz
    RIGHTF=$WORKDIR/${BASE}_filtered_2.fastq.gz
    LEFT=$WORKDIR/${BASE}_fastp_1.fastq.gz
    RIGHT=$WORKDIR/${BASE}_fastp_2.fastq.gz

    echo "$BASE $ID $STRAIN"
    if [ ! -f $ASMFILE ]; then # can skip we already have made an assembly
	if [ ! -f $LEFT ]; then
	    if [ ! -f $LEFTF ]; then # can skip filtering if this exists means already processed
		if [ ! -f $LEFTTRIM ]; then
		    AAFTF trim --method bbduk --memory $MEM --left $LEFTIN --right $RIGHTIN -c $CPU -o $WORKDIR/${BASE}
		fi
		AAFTF filter -c $CPU --memory $MEM -o $WORKDIR/${BASE} --left $LEFTTRIM --right $RIGHTTRIM --aligner bbduk
		if [ -f $LEFTF ]; then
		    #rm $LEFTTRIM $RIGHTTRIM # remove intermediate file
		    echo "found $LEFTF"
		fi
	    fi
	    fastp --in1 $LEFTF --in2 $RIGHTF --out1 $LEFT --out2 $RIGHT -w $CPU --dedup \
		  --dup_calc_accuracy 6 -y --detect_adapter_for_pe \
		  -j $WORKDIR/${BASE}.json -h $WORKDIR/${BASE}.html
	fi
	
	AAFTF assemble -c $CPU --left $LEFT --right $RIGHT  --memory $MEM \
	      -o $ASMFILE -w $WORKDIR/spades_${ID}
	
	if [ -s $ASMFILE ]; then
	    rm -rf $WORKDIR/spades_${ID}/K?? $WORKDIR/spades_${ID}/tmp
	fi
	
	if [ ! -f $ASMFILE ]; then
	    echo "SPADES must have failed, exiting"
	    exit
	fi
    fi
    
    if [ ! -f $VECCLEAN ]; then
	AAFTF vecscreen -i $ASMFILE -c $CPU -o $VECCLEAN
    fi
    if [ ! -f $PURGE ]; then
	AAFTF sourpurge -i $VECCLEAN -o $PURGE -c $CPU --phylum $PHYLUM --left $LEFT --right $RIGHT
    fi
    
    if [ ! -f $CLEANDUP ]; then
    	AAFTF rmdup -i $PURGE -o $CLEANDUP -c $CPU -m 500
    fi
    
    if [ ! -f $PILON ]; then
    	AAFTF pilon -i $CLEANDUP -o $PILON -c $CPU --left $LEFT  --right $RIGHT
    fi
    
    if [ ! -f $PILON ]; then
    	echo "Error running Pilon, did not create file. Exiting"
    	exit
    fi
    
    if [ ! -f $SORTED ]; then
	 AAFTF sort -i $PILON -o $SORTED
	# AAFTF sort -i $CLEANDUP -o $SORTED
    fi
    
    if [ ! -f $STATS ]; then
	AAFTF assess -i $SORTED -r $STATS
    fi
done
