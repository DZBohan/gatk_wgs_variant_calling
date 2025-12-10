#!/bin/bash
#SBATCH --job-name=sample1gvcf                   # Job name
#SBATCH --mail-type=BEGIN,END,FAIL               # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=your_email_address           # Where to send mail
#SBATCH --cpus-per-task=16                       # Number of CPU cores
#SBATCH --ntasks=1                               # Number of tasks
#SBATCH --partition=compute                      # Partition (default is all if you don't specify)
#SBATCH --mem=256G                               # Amount of memory in GB
#SBATCH --time=7-00:00:00                        # Time Limit D-HH:MM:SS
#SBATCH --output=sample1_gvcf_%j.log             # Standard output and error log

set -eo pipefail
source ~/.bashrc
conda activate wgs
THREADS=${SLURM_CPUS_PER_TASK:-16}
JAVA_MEM_GB=128

# Input
SAMPLE="sample1" # Need Change
IN_BAM="/path/to/alignment/out/${SAMPLE}/${SAMPLE}.hg38.sorted.bam"
REF="/path/to/fasta/and/its/index"
KNOWN_DIR="/path/to/known_sites/and/their/index"
DBSNP="${KNOWN_DIR}/Homo_sapiens_assembly38.dbsnp138.vcf"
MILLS="${KNOWN_DIR}/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz"
PHASE1="${KNOWN_DIR}/1000G_phase1.snps.high_confidence.hg38.vcf.gz"

# Output
OUTDIR="/path/to/alignment/out/${SAMPLE}/gatk"
mkdir -p "${OUTDIR}"
DEDUP_BAM="${OUTDIR}/${SAMPLE}.hg38.dedup.bam"
DEDUP_METRICS="${OUTDIR}/${SAMPLE}.hg38.dedup.metrics.txt"
RECAL_TABLE="${OUTDIR}/${SAMPLE}.hg38.recal.table"
BQSR_BAM="${OUTDIR}/${SAMPLE}.hg38.dedup.bqsr.bam"
GVCF="${OUTDIR}/${SAMPLE}.hg38.g.vcf.gz"

# Check1
echo "Job started at: $(date)"
echo "Running on node: $(hostname)"
echo "Threads: ${THREADS}"
echo "Input BAM : ${IN_BAM}"
echo "REF       : ${REF}"
echo "DBSNP     : ${DBSNP}"
echo "MILLS     : ${MILLS}"
echo "PHASE1    : ${PHASE1}"
echo
for f in "${IN_BAM}" "${REF}" "${DBSNP}" "${MILLS}" "${PHASE1}"; do
  if [[ ! -f "$f" ]]; then
    echo "ERROR: file not found: $f" >&2
    exit 1
  fi
done

# Step1 MarkDuplicates
START_MD=$(date +%s)
TMP_MARKDUP="${OUTDIR}/tmp_markdup"
mkdir -p "${TMP_MARKDUP}"
gatk --java-options "-Xmx${JAVA_MEM_GB}g" \
  MarkDuplicates \
  -I "${IN_BAM}" \
  -O "${DEDUP_BAM}" \
  -M "${DEDUP_METRICS}" \
  --CREATE_INDEX true \
  --VALIDATION_STRINGENCY LENIENT \
  --TMP_DIR "${TMP_MARKDUP}"
END_MD=$(date +%s)

# Check2
echo "MarkDuplicates finished at: $(date)"
echo "Time used (MD): $(((END_MD-START_MD)/3600)) hours"
echo

# Step2 BaseRecalibrator (recal.table)
START_BQSR1=$(date +%s)
gatk --java-options "-Xmx${JAVA_MEM_GB}g" \
  BaseRecalibrator \
  -R "${REF}" \
  -I "${DEDUP_BAM}" \
  --known-sites "${DBSNP}" \
  --known-sites "${MILLS}" \
  --known-sites "${PHASE1}" \
  -O "${RECAL_TABLE}"
END_BQSR1=$(date +%s)

# Check3
echo "BaseRecalibrator finished at: $(date)"
echo "Time used (BR): $(((END_BQSR1-START_BQSR1)/3600)) hours"
echo

# Step3 ApplyBQSR (BAM after BQSR refinement)
START_BQSR2=$(date +%s)
gatk --java-options "-Xmx${JAVA_MEM_GB}g" \
  ApplyBQSR \
  -R "${REF}" \
  -I "${DEDUP_BAM}" \
  --bqsr-recal-file "${RECAL_TABLE}" \
  --create-output-bam-index true \
  -O "${BQSR_BAM}"
END_BQSR2=$(date +%s)

# Check4
echo "ApplyBQSR finished at: $(date)"
echo "Time used (ApplyBQSR): $(((END_BQSR2-START_BQSR2)/3600)) hours"
echo

# Step4 HaplotypeCaller (GVCF)
START_HC=$(date +%s)
gatk --java-options "-Xmx${JAVA_MEM_GB}g" \
  HaplotypeCaller \
  -R "${REF}" \
  -I "${BQSR_BAM}" \
  -O "${GVCF}" \
  -ERC GVCF \
  --native-pair-hmm-threads "${THREADS}"
END_HC=$(date +%s)

# Check5
echo "HaplotypeCaller finished at: $(date)"
echo "Time used (HC): $(((END_HC-START_HC)/3600)) hours"
echo "All steps finished at: $(date)"
TOTAL_END=$END_HC
TOTAL_START=$START_MD
echo "Total pipeline time: $(((TOTAL_END-TOTAL_START)/3600)) hours"
