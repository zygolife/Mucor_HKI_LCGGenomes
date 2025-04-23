#!/usr/bin/bash -l
#SBATCH -p stajichlab -c 20 --mem 32gb 

module load raxml-ng
raxml-ng --all --msa pep_fungi_taxa_128.fa.raxml.rba --threads auto{20} --tree pars{10}  --bs-trees 300 

