#!/bin/bash -l
#SBATCH --nodes 1 --ntasks 32 --mem 64gb -p intel --out logs/fasttree_run.%A.log

module load fasttree
module load miniconda3
conda activate /bigdata/stajichlab/shared/condaenv/phyling
NUM=$(wc -l Phylogeny/prefix.tab | awk '{print $1}')
source Phylogeny/config.txt

ALN=Phylogeny/$PREFIX.${NUM}_taxa.$HMM.aa.fasaln
TREE1=Phylogeny/$PREFIX.${NUM}_taxa.$HMM.aa.ft_lg.tre
TREE2=Phylogeny/$PREFIX.${NUM}_taxa.$HMM.aa.ft_lg_long.tre

if [ ! -s $TREE1 ]; then
	FastTreeMP -lg -gamma < $ALN > $TREE1
fi
if [ -s $TREE1 ]; then
	perl PHYling_Unified/util/rename_tree_nodes.pl $TREE1 prefix.tab > $TREE2
fi
