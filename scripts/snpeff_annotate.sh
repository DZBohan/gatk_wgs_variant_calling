#!/bin/bash
#SBATCH --job-name=snpeff_annotate               # Job name
#SBATCH --mail-type=BEGIN,END,FAIL               # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=your_email_address           # Where to send mail
#SBATCH --cpus-per-task=16                       # Number of CPU cores
#SBATCH --ntasks=1                               # Number of tasks
#SBATCH --partition=compute                      # Partition (default is all if you don't specify)
#SBATCH --mem=256G                               # Amount of memory in GB
#SBATCH --time=24:00:00                        # Time Limit D-HH:MM:SS
#SBATCH --output=snpeff_annotate_%j.log           # Standard output and error log

set -eo pipefail
source ~/.bashrc
conda activate wgs
THREADS="${SLURM_CPUS_PER_TASK:-16}"

# Input
DB="GRCh38.99"
IN_VCF="/path/to/wgs/out/joint/filter/cohort.filtered.vcf.gz"

# Output
OUTDIR="/path/to/wgs/out/joint/snpeff"
mkdir -p "${OUTDIR}"
PREFIX="cohort.filtered"
TMP_VCF="${OUTDIR}/${PREFIX}.snpeff.vcf"
OUT_VCF_GZ="${TMP_VCF}.gz"
OUT_HTML="${OUTDIR}/${PREFIX}.snpeff.summary.html"
OUT_CSV="${OUTDIR}/${PREFIX}.snpeff.summary.csv"
DATA_DIR="/path/to/ref/snpeff_data"
CONF="${DATA_DIR}/snpEff.${DB}.config"

# Step1 Run snpEff
snpEff \
  -Xmx100g \
  -c "${CONF}" \
  -stats "${OUT_HTML}" \
  -csvStats "${OUT_CSV}" \
  -canon \
  "${DB}" \
  "${IN_VCF}" \
  > "${TMP_VCF}"

# Step2 Compressing & Indexing
bgzip -f -@ "${THREADS}" "${TMP_VCF}"
tabix -f -p vcf "${OUT_VCF_GZ}"
