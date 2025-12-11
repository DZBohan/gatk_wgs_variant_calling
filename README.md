# GATK WGS Variant Calling

This repository provides a complete GATK Best Practices Germline Variant Calling Pipeline for WGS (Whole Genome Sequencing) data. It covers alignment, variant calling, joint genotyping, filtering, annotation, and variant extraction for specific genes.

1. Alignment

Align raw FASTQ reads to the reference genome (hg38) using BWA-MEM2 and generate sorted BAM files.

2. MarkDuplicates

Identify and mark duplicate reads (PCR/optical) to improve variant calling accuracy.

3. BQSR (Base Quality Score Recalibration)

Recalibrate base quality scores using known variant sites (dbSNP, Mills) to reduce systematic sequencing errors.

4. HaplotypeCaller (GVCF mode)

Call variants per sample and generate GVCF files.
GVCF mode is required for multi-sample joint genotyping.

5. GenomicsDBImport

Import all sample GVCFs into a GenomicsDB workspace for joint calling.

6. GenotypeGVCFs

Perform cohort-level joint genotyping, producing cohort.raw.vcf.gz.

7. Variant Filtering (Hard Filter / VQSR)

Remove low-quality variants and generate the final high-confidence cohort.filtered.vcf.gz.

8. SnpEff Annotation

Annotate variants with gene information, amino acid changes, predicted impact, etc.

9. Extract Coding Variants for specific genes

Select variants within the coding region of specific genes and output them in VCF or TSV format.

![flowchart1](https://github.com/DZBohan/gatk_wgs_variant_calling/blob/main/images/flowchart1.png?raw=true)

### Dependencies

```
conda 25.5.1
samtools 1.22.1
bwa-mem2 2.2.1
gatk 4.6.2.0
```

Use the following command to create a conda environment `wgs`, including samtools, bwa-mem2, and gatk.

```
conda create -n wgs -c bioconda -c conda-forge bwa-mem2 samtools gatk4
```

Use the following commands to activate the environment and check the tool versions.

```
conda activate wgs
samtools --version
bwa-mem2 version
gatk --version
```

### References

Run the bash script [`download_hg38.sh`](https://github.com/DZBohan/gatk_wgs_variant_calling/blob/main/refs/download_hg38.sh) to download the following fasta references and index files.

```
Homo_sapiens_assembly38.fasta
Homo_sapiens_assembly38.fasta.fai
Homo_sapiens_assembly38.dict
Homo_sapiens_assembly38.fasta.amb
Homo_sapiens_assembly38.fasta.ann
Homo_sapiens_assembly38.fasta.bwt
Homo_sapiens_assembly38.fasta.pac
Homo_sapiens_assembly38.fasta.sa
```

Submit the Slurm script [`build_hg38_bwamem2_index.sh`](https://github.com/DZBohan/gatk_wgs_variant_calling/blob/main/refs/build_hg38_bwamem2_index.sh) to generate the following index files for running bwa-mem2 alignment.

```
Homo_sapiens_assembly38.fasta.0123
Homo_sapiens_assembly38.fasta.bwt.2bit.64
```

Run the bash script [`knownSitesDown.sh`](https://github.com/DZBohan/gatk_wgs_variant_calling/blob/main/refs/knownSitesDown.sh) to download the following known sites files for running `BaseRecalibrator`.

```
Homo_sapiens_assembly38.dbsnp138.vcf
Mills_and_1000G_gold_standard.indels.hg38.vcf.gz
1000G_phase1.snps.high_confidence.hg38.vcf.gz
```

Submit the Slurm script `knownSitesIndex.sh` to generate the following index files of known sites files.

```
Homo_sapiens_assembly38.dbsnp138.vcf.idx
Mills_and_1000G_gold_standard.indels.hg38.vcf.gz.tbi
1000G_phase1.snps.high_confidence.hg38.vcf.gz.tbi
```

### Alignment (Script A)

Edit and submit the Slurm script [`sample1_alignment.sh`](https://github.com/DZBohan/gatk_wgs_variant_calling/blob/main/scripts/sample1_alignment.sh) to run alignment and output the following files. Check the flagstat file to see the QC.

```
sample1.hg38.sorted.bam
sample1.hg38.sorted.bam.bai
sample1.hg38.sorted.flagstat.txt
```

### VCF Generation (Script B)

Edit and submit the Slurm script [`sample1_gatk_gvcf.sh`](https://github.com/DZBohan/gatk_wgs_variant_calling/blob/main/scripts/sample1_gatk_gvcf.sh) to generate the VCF file per sample. This script includes `MarkDuplicates`, `BaseRecalibrator`, `ApplyBQSR`, and `HaplotypeCaller`. The following files are the output files of the script. Check `dedup.metrics` to see the duplication QC.

```
sample1.hg38.dedup.bai
sample1.hg38.dedup.bam
sample1.hg38.dedup.bqsr.bai
sample1.hg38.dedup.bqsr.bam
sample1.hg38.dedup.metrics.txt
sample1.hg38.g.vcf.gz
sample1.hg38.g.vcf.gz.tbi
sample1..hg38.recal.table
```

### Joint Calling (Script C)

Edit and submit the Slurm script [`joint_calling.sh`](https://github.com/DZBohan/gatk_wgs_variant_calling/blob/main/scripts/joint_calling.sh) to merge the VCF files to get a cohort VCF file. This script includes `GenomicsDBImport` and `GenotypeGVCFs`.

During Joint Calling, only the 24 canonical chromosomes (chr1–chr22, chrX, chrY) were included. Non-canonical contigs (e.g., chrM and unlocalized/unplaced scaffolds such as chr1_KI…, chrUn…) were excluded.