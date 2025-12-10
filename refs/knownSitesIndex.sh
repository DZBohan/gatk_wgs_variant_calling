#!/bin/bash
#SBATCH --job-name=known_sites_index
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --partition=compute
#SBATCH --time=4:00:00
#SBATCH --output=known_sites_index_%j.log

set -eo pipefail

KNOWN_DIR="/path/to/known/sites/directory"
cd "${KNOWN_DIR}"

source ~/.bashrc
conda activate wgs

# dbSNP 138 (.vcf) -> .idx
DBSNP_VCF="Homo_sapiens_assembly38.dbsnp138.vcf"
if [[ -f "${DBSNP_VCF}" ]]; then
    echo "Indexing dbSNP: ${DBSNP_VCF}"
    gatk IndexFeatureFile -I "${DBSNP_VCF}"
else
    echo "WARNING: ${DBSNP_VCF} not found, skip."
fi

# Mills indels（.vcf.gz） -> .tbi
MILLS_VCF="Mills_and_1000G_gold_standard.indels.hg38.vcf.gz"
if [[ -f "${MILLS_VCF}" ]]; then
    echo "Indexing Mills indels: ${MILLS_VCF}"
    gatk IndexFeatureFile -I "${MILLS_VCF}"
else
    echo "WARNING: ${MILLS_VCF} not found, skip."
fi

# 5. 1000G phase1 high-confidence SNPs（.vcf.gz） -> .tbi
PHASE1_VCF="1000G_phase1.snps.high_confidence.hg38.vcf.gz"
if [[ -f "${PHASE1_VCF}" ]]; then
    echo "Indexing 1000G phase1 SNPs: ${PHASE1_VCF}"
    gatk IndexFeatureFile -I "${PHASE1_VCF}"
else
    echo "WARNING: ${PHASE1_VCF} not found, skip."
fi
