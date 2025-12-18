#!/bin/bash
set -euo pipefail

awk 'BEGIN{OFS="\t"}
     /^#/ {print; next}
     $1 ~ /^([1-9]|1[0-9]|2[0-2]|X|Y)$/ { $1="chr"$1; print }' \
  Homo_sapiens.GRCh38.99.gtf \
  > genes.chr1Y.gtf
