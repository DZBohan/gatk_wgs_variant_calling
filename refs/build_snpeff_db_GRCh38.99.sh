#!/bin/bash
#SBATCH --job-name=snpeff_build_GRCh38.99
#SBATCH --cpus-per-task=8
#SBATCH --mem=128G
#SBATCH --partition=compute
#SBATCH --time=6:00:00
#SBATCH --output=snpeff_build_GRCh38.99_%j.log

set -eo pipefail
source ~/.bashrc
conda activate wgs

# Input
IN_FASTA="/path/to/gene.chr1Y.fasta"
IN_GTF="/path/to/genes.chr1Y.gtf"

# Output
DATA_DIR="/path/to/ref/snpeff_data"
DB="GRCh38.99"
DB_DIR="${DATA_DIR}/data/${DB}"
mkdir -p "${DB_DIR}"
CONF="${DATA_DIR}/snpEff.${DB}.config"

# Put files where snpEff expects them, with expected names
cp -f "${IN_FASTA}" "${DB_DIR}/sequences.fa"
cp -f "${IN_GTF}"   "${DB_DIR}/genes.gtf"
samtools faidx "${DB_DIR}/sequences.fa"

# snpEff config
CONF="${DATA_DIR}/snpEff.${DB}.config"
cat > "${CONF}" <<EOF
# Auto-generated config for building ${DB}
data.dir = ${DATA_DIR}/data

# Register genome key
${DB}.genome : Homo_sapiens
EOF

# Build database
export _JAVA_OPTIONS="-Xmx100g"
snpEff build -c "${CONF}" -gtf22 -v "${DB}"
