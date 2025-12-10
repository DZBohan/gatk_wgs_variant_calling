#!/bin/bash
#SBATCH --job-name=joint_calling                 # Job name
#SBATCH --mail-type=BEGIN,END,FAIL               # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=your/email/address           # Where to send mail
#SBATCH --cpus-per-task=16                       # Number of CPU cores
#SBATCH --ntasks=1                               # Number of tasks
#SBATCH --partition=compute                      # Partition (default is all if you don't specify)
#SBATCH --mem=256G                               # Amount of memory in GB
#SBATCH --time=4-00:00:00                        # Time Limit D-HH:MM:SS
#SBATCH --output=joint_calling_%j.log            # Standard output and error log

set -eo pipefail
source ~/.bashrc
conda activate wgs
THREADS=${SLURM_CPUS_PER_TASK:-16}
JAVA_MEM_GB=128

# Input (Input GVCF in Step1)
REF="path/to/fasta/and/its/index"
SAMPLES=(
  "sample1"
  "sample2"
  "sample3"
  "sample4"
  "sample5"
  "sample6"
)
INTERVAL_ARGS=(
  --intervals chr1
  --intervals chr2
  --intervals chr3
  --intervals chr4
  --intervals chr5
  --intervals chr6
  --intervals chr7
  --intervals chr8
  --intervals chr9
  --intervals chr10
  --intervals chr11
  --intervals chr12
  --intervals chr13
  --intervals chr14
  --intervals chr15
  --intervals chr16
  --intervals chr17
  --intervals chr18
  --intervals chr19
  --intervals chr20
  --intervals chr21
  --intervals chr22
  --intervals chrX
  --intervals chrY
)

# Output
JOINT_OUT="/path/to/alignment/out/joint"
mkdir -p "${JOINT_OUT}"
DB_DIR="${JOINT_OUT}/genomicsdb"
SAMPLE_MAP="${JOINT_OUT}/joint.samples.map"
COHORT_VCF="${JOINT_OUT}/cohort.raw.vcf.gz"

# Check1
echo "Job started at: $(date)"
echo "Running on node: $(hostname)"
echo "THREADS = ${THREADS}"
echo

# Step1 Sample Name Map (Need Change Path)
rm -f "${SAMPLE_MAP}"
for S in "${SAMPLES[@]}"; do
    GVCF="/path/to/alignment/out/${S}/gatk/${S}.hg38.g.vcf.gz"
    if [[ ! -f "${GVCF}" ]]; then
        echo "ERROR: GVCF not found for sample ${S}: ${GVCF}" >&2
        exit 1
    fi
    printf "%s\t%s\n" "${S}" "${GVCF}" >> "${SAMPLE_MAP}"
done

# Check2
echo "Sample-name map content:"
cat "${SAMPLE_MAP}"
echo

# Step2 GenomicsDBImport
START_DB=$(date +%s)
gatk --java-options "-Xmx${JAVA_MEM_GB}g" \
    GenomicsDBImport \
    -R "${REF}" \
    --genomicsdb-workspace-path "${DB_DIR}" \
    --sample-name-map "${SAMPLE_MAP}" \
    --reader-threads "${THREADS}" \
    "${INTERVAL_ARGS[@]}"
END_DB=$(date +%s)

# Check3
echo "GenomicsDBImport finished at: $(date)"
echo "Time used (DB): $(((END_DB - START_DB)/3600)) hours"
echo

# Step3 GenotypeGVCFs (cohort-level VCF generation)
START_GT=$(date +%s)
gatk --java-options "-Xmx${JAVA_MEM_GB}g" \
    GenotypeGVCFs \
    -R "${REF}" \
    -V "gendb://${DB_DIR}" \
    -O "${COHORT_VCF}" \
    "${INTERVAL_ARGS[@]}"
END_GT=$(date +%s)

# Check4
echo "GenotypeGVCFs finished at: $(date)"
echo "Time used (GT): $(((END_GT - START_GT)/3600)) hours"
TOTAL_END=${END_GT}
TOTAL_START=${START_DB}
echo "All joint-calling steps finished at: $(date)"
echo "Total pipeline time: $(((TOTAL_END - TOTAL_START)/3600)) hours"
