#!/bin/bash
#SBATCH --job-name=sample1Alignment              # Job name
#SBATCH --mail-type=BEGIN,END,FAIL               # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=you_email_address            # Where to send mail
#SBATCH --cpus-per-task=16                       # Number of CPU cores
#SBATCH --ntasks=1                               # Number of tasks
#SBATCH --partition=compute                      # Partition (default is all if you don't specify)
#SBATCH --mem=256G                               # Amount of memory in GB
#SBATCH --time=7-00:00:00                        # Time Limit D-HH:MM:SS
#SBATCH --output=sample1_align_%j.log            # Standard output and error log

set -eo pipefail

# Check1
echo "Job started at: $(date)"
echo "Running on node: $(hostname)"
echo "SLURM_CPUS_PER_TASK = ${SLURM_CPUS_PER_TASK:-not_set}"
echo

source ~/.bashrc
conda activate wgs

# Inputs
THREADS=${SLURM_CPUS_PER_TASK:-16}
REF="/path/to/fasta/and/its/index"
SAMPLE="sample1" # Need Change
R1="/path/to/r1/fastq" # Need Change
R2="/path/to/r2/fastq" # Need Change

# Outputs
OUTDIR="/path/to/out/sample1" # Need Change
mkdir -p "${OUTDIR}"
BAM="${OUTDIR}/${SAMPLE}.hg38.sorted.bam"
FLAGSTAT="${OUTDIR}/${SAMPLE}.hg38.sorted.flagstat.txt"

# Check2
echo "Reference fasta : ${REF}"
echo "FASTQ R1        : ${R1}"
echo "FASTQ R2        : ${R2}"
echo "Output BAM      : ${BAM}"
echo "Threads         : ${THREADS}"
echo

if [[ ! -f "${REF}" ]]; then
  echo "ERROR: reference fasta not found: ${REF}" >&2
  exit 1
fi

if [[ ! -f "${R1}" ]]; then
  echo "ERROR: R1 FASTQ not found: ${R1}" >&2
  exit 1
fi

if [[ ! -f "${R2}" ]]; then
  echo "ERROR: R2 FASTQ not found: ${R2}" >&2
  exit 1
fi

# Read Group
RGID="${SAMPLE}_L4" # Need Change (flow cell lane number)
RGSM="${SAMPLE}"
RGLB="${SAMPLE}_lib1"
RGPL="ILLUMINA"
RGPU="flowcell_L4" # Need Change (flow cell id + flow cell lane number)

RG="@RG\tID:${RGID}\tSM:${RGSM}\tLB:${RGLB}\tPL:${RGPL}\tPU:${RGPU}"

# Check3
echo "Using RG: ${RG}"
echo

# Alignment (bwa-mem2 + samtools)
START_ALIGN=$(date +%s)

bwa-mem2 mem -t "${THREADS}" -R "${RG}" "${REF}" "${R1}" "${R2}" \
  | samtools sort -@ "${THREADS}" -o "${BAM}" -T "${OUTDIR}/${SAMPLE}.tmp"

END_ALIGN=$(date +%s)

# Check4
echo "Alignment + sort finished at: $(date)"
echo "Time used: $(( (END_ALIGN - START_ALIGN) / 3600 )) hours"
echo

# Index
samtools index "${BAM}"

# Check5
echo "Index created: ${BAM}.bai"
echo

# QC (flagstat)
samtools flagstat "${BAM}" > "${FLAGSTAT}"

# Check6 
echo "Flagstat written to: ${FLAGSTAT}"
echo "Job finished at: $(date)"
