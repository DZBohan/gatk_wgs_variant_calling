#!/bin/bash
set -euo pipefail

for f in \
  Homo_sapiens_assembly38.fasta \
  Homo_sapiens_assembly38.fasta.fai \
  Homo_sapiens_assembly38.dict \
  Homo_sapiens_assembly38.fasta.amb \
  Homo_sapiens_assembly38.fasta.ann \
  Homo_sapiens_assembly38.fasta.bwt \
  Homo_sapiens_assembly38.fasta.pac \
  Homo_sapiens_assembly38.fasta.sa
do
  echo "Downloading $f ..."
  wget -c https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/$f
done

echo "Done."
