#!/bin/bash
#SBATCH --job-name=variant_filter                # Job name
#SBATCH --mail-type=BEGIN,END,FAIL               # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=your_email_address           # Where to send mail
#SBATCH --cpus-per-task=16                       # Number of CPU cores
#SBATCH --ntasks=1                               # Number of tasks
#SBATCH --partition=compute                      # Partition (default is all if you don't specify)
#SBATCH --mem=128G                               # Amount of memory in GB
#SBATCH --time=2-00:00:00                        # Time Limit D-HH:MM:SS
#SBATCH --output=variant_filter_%j.log           # Standard output and error log

set -eo pipefail
source ~/.bashrc
conda activate wgs
THREADS=${SLURM_CPUS_PER_TASK:-16}
JAVA_MEM_GB=32

# Input
JOINT_DIR="/path/to/alignment/out/joint"
IN_VCF="${JOINT_DIR}/cohort.raw.vcf.gz"
REF="/path/to/fasta/and/its/index"

# Output
OUT_DIR="${JOINT_DIR}/filter"
mkdir -p "${OUT_DIR}"
SNP_VCF="${OUT_DIR}/cohort.raw.snps.vcf.gz"
INDEL_VCF="${OUT_DIR}/cohort.raw.indels.vcf.gz"
SNP_FILT_VCF="${OUT_DIR}/cohort.snps.filtered_tagged.vcf.gz"
INDEL_FILT_VCF="${OUT_DIR}/cohort.indels.filtered_tagged.vcf.gz"
SNP_PASS_VCF="${OUT_DIR}/cohort.snps.PASS.vcf.gz"
INDEL_PASS_VCF="${OUT_DIR}/cohort.indels.PASS.vcf.gz"
MERGED_PASS_VCF="${OUT_DIR}/cohort.filtered.vcf.gz"

# Check1
echo "Job started at: $(date)"
echo "Running on node: $(hostname)"
echo "THREADS: ${THREADS}"
echo "IN_VCF:  ${IN_VCF}"
echo "REF:     ${REF}"
echo "OUT_DIR: ${OUT_DIR}"

for f in "${IN_VCF}" "${REF}"; do
  if [[ ! -f "${f}" ]]; then
    echo "ERROR: file not found: ${f}" >&2
    exit 1
  fi
done

if [[ ! -f "${IN_VCF}.tbi" ]]; then
  echo "INFO: VCF index not found, creating: ${IN_VCF}.tbi"
  gatk IndexFeatureFile -I "${IN_VCF}"
fi

# Step1 Split SNPs / INDELs
gatk --java-options "-Xmx${JAVA_MEM_GB}g" SelectVariants \
  -R "${REF}" \
  -V "${IN_VCF}" \
  --select-type-to-include SNP \
  --create-output-variant-index true \
  -O "${SNP_VCF}"
gatk --java-options "-Xmx${JAVA_MEM_GB}g" SelectVariants \
  -R "${REF}" \
  -V "${IN_VCF}" \
  --select-type-to-include INDEL \
  --create-output-variant-index true \
  -O "${INDEL_VCF}"

# Step2 Hard filters
gatk --java-options "-Xmx${JAVA_MEM_GB}g" VariantFiltration \
  -R "${REF}" \
  -V "${SNP_VCF}" \
  --filter-name "SNP_QD_lt2"        --filter-expression "QD < 2.0" \
  --filter-name "SNP_FS_gt60"       --filter-expression "FS > 60.0" \
  --filter-name "SNP_SOR_gt3"       --filter-expression "SOR > 3.0" \
  --filter-name "SNP_MQ_lt40"       --filter-expression "MQ < 40.0" \
  --filter-name "SNP_MQRankSum_lt-12.5" --filter-expression "MQRankSum < -12.5" \
  --filter-name "SNP_ReadPosRankSum_lt-8" --filter-expression "ReadPosRankSum < -8.0" \
  --create-output-variant-index true \
  -O "${SNP_FILT_VCF}"

gatk --java-options "-Xmx${JAVA_MEM_GB}g" VariantFiltration \
  -R "${REF}" \
  -V "${INDEL_VCF}" \
  --filter-name "INDEL_QD_lt2"        --filter-expression "QD < 2.0" \
  --filter-name "INDEL_FS_gt200"      --filter-expression "FS > 200.0" \
  --filter-name "INDEL_SOR_gt10"      --filter-expression "SOR > 10.0" \
  --filter-name "INDEL_ReadPosRankSum_lt-20" --filter-expression "ReadPosRankSum < -20.0" \
  --create-output-variant-index true \
  -O "${INDEL_FILT_VCF}"

# Step3 Keep only PASS
gatk --java-options "-Xmx${JAVA_MEM_GB}g" SelectVariants \
  -R "${REF}" \
  -V "${SNP_FILT_VCF}" \
  --exclude-filtered \
  --create-output-variant-index true \
  -O "${SNP_PASS_VCF}"

gatk --java-options "-Xmx${JAVA_MEM_GB}g" SelectVariants \
  -R "${REF}" \
  -V "${INDEL_FILT_VCF}" \
  --exclude-filtered \
  --create-output-variant-index true \
  -O "${INDEL_PASS_VCF}"

# Step4 Merge PASS SNP+INDEL (cohort.filtered.vcf.gz)
gatk --java-options "-Xmx${JAVA_MEM_GB}g" MergeVcfs \
  -I "${SNP_PASS_VCF}" \
  -I "${INDEL_PASS_VCF}" \
  -O "${MERGED_PASS_VCF}" \
  --CREATE_INDEX true

# Check2
echo "Final output: ${MERGED_PASS_VCF}"
echo "Finished at: $(date)"
