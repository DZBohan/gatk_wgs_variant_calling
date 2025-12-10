#!/bin/bash
set -euo pipefail

REF_BASE="https://storage.googleapis.com/genomics-public-data/references/hg38/v0"
RES_BASE="https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0"

echo "===== Downloading dbSNP (dbsnp138) ====="
wget -c "${REF_BASE}/Homo_sapiens_assembly38.dbsnp138.vcf"

echo "===== Downloading Mills indels ====="
wget -c "${RES_BASE}/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz"

echo "===== Downloading 1000G phase1 high-confidence SNPs ====="
wget -c "${RES_BASE}/1000G_phase1.snps.high_confidence.hg38.vcf.gz"
