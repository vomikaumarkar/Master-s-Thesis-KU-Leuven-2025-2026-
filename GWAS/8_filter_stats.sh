#!/bin/bash -l 
#SBATCH --cluster=genius 
#SBATCH --job-name=stats 
#SBATCH --nodes=1 
#SBATCH --cpus-per-task=20
#SBATCH --time=24:00:00 
#SBATCH -A lp_svbelleghem
#SBATCH -o stats.%j.out

# Stop script on error
set -e

# Load Conda
source /user/leuven/373/vsc37319/miniconda3/etc/profile.d/conda.sh

#Activate environment
conda activate vcftools

# Directory
cd /scratch/leuven/373/vsc37319/GWAS/vcf

# VCF File
VCF=filtered_snps.vcf.gz
PREFIX=filtered

echo "========================="
echo "Running VCF statistics"
echo "Start time: $(date)"
echo "========================="

# -------------------------------
# Core stats
# -------------------------------
bcftools stats $VCF > ${PREFIX}.bcftools_stats.txt
grep -E "SN|TSTV" ${PREFIX}.bcftools_stats.txt

# -------------------------------
# Variant counts
# -------------------------------
TOTAL_SNPS=$(bcftools view -H $VCF | wc -l)
BIALLELIC_SNPS=$(bcftools view -m2 -M2 -v snps $VCF | wc -l)
MULTIALLELIC_SNPS=$(bcftools view -m3 $VCF | wc -l)

echo "Total SNPs: $TOTAL_SNPS"
echo "Biallelic SNPs: $BIALLELIC_SNPS"
echo "Multiallelic SNPs: $MULTIALLELIC_SNPS"

# -------------------------------
# Missingness
# -------------------------------
vcftools --gzvcf $VCF --missing-indv --out $PREFIX
vcftools --gzvcf $VCF --missing-site --out $PREFIX

# -------------------------------
# Missingness summaries
# -------------------------------
echo "Top individuals by missingness:"
sort -k6,6nr ${PREFIX}.imiss | head

echo "Mean individual missingness:"
awk 'NR>1 {sum+=$6} END {print sum/(NR-1)}' ${PREFIX}.imiss

echo "Top SNPs by missingness:"
sort -k6,6nr ${PREFIX}.lmiss | head

echo "Mean site missingness:"
awk 'NR>1 {sum+=$6} END {print sum/(NR-1)}' ${PREFIX}.lmiss

echo "SNPs with >20% missing:"
awk 'NR>1 && $6 > 0.2' ${PREFIX}.lmiss | wc -l

# -------------------------------
# Allele frequency
# -------------------------------
vcftools --gzvcf $VCF --freq --out $PREFIX

# -------------------------------
# SNP density
# -------------------------------
vcftools --gzvcf $VCF --SNPdensity 1000000 --out $PREFIX

# -------------------------------
# Depth
# -------------------------------
vcftools --gzvcf $VCF --site-mean-depth --out $PREFIX
vcftools --gzvcf $VCF --depth --out $PREFIX

# -------------------------------
# Heterozygosity
# -------------------------------
vcftools --gzvcf $VCF --het --out $PREFIX

# -------------------------------
# Hardy-Weinberg
# -------------------------------
vcftools --gzvcf $VCF --hardy --out $PREFIX

echo "========================="
echo "Stats complete"
echo "End time: $(date)"
echo "========================="
