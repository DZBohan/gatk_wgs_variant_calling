# gatk_wgs_variant_calling

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

flowchart1

