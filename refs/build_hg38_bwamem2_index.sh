#!/bin/bash
#SBATCH --job-name=build_hg38_bwamem2_index
#SBATCH --cpus-per-task=16
#SBATCH --mem=256G
#SBATCH --partition=compute
#SBATCH --time=24:00:00
#SBATCH --output=build_hg38_index_%j.log

source ~/.bashrc
conda activate wgs

cd /path/to/hg38/directory

bwa-mem2 index Homo_sapiens_assembly38.fasta
