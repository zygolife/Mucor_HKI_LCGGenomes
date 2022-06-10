#!/bin/bash -l
#SBATCH -p short -N 1 -n 96 --mem 64gb  -N 1 --out logs/make_CDS_trees.%A.log
module load fasttree
module load IQ-TREE/2.2.0

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
  CPU=$SLURM_CPUS_ON_NODE
fi

make -f PHYling_unified/util/makefiles/Makefile.trees HMM=fungi_odb10 -j $CPU PEP
