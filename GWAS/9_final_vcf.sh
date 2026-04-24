#!/bin/bash -l
#SBATCH --cluster=genius
#SBATCH --job-name=final_vcf
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --time=04:00:00
#SBATCH -A lp_svbelleghem
#SBATCH -o final_vcf.%j.out

# Stop script on error
set -e

# Load conda
source /user/leuven/373/vsc37319/miniconda3/etc/profile.d/conda.sh

# Activate environment (must contain bcftools)
conda activate vcftools

# Go to working directory
cd /scratch/leuven/373/vsc37319/GWAS/vcf

# Input file
VCF=filtered_snps.vcf.gz

echo "========================="
echo "Final VCF processing"
echo "Start time: $(date)"
echo "========================="

# -------------------------------
# Step 1: Remove bad sample
# -------------------------------
echo "Removing bad sample S-06..."

echo "S-06" > remove_bad_samples.txt

bcftools view -S ^remove_bad_samples.txt $VCF -Oz -o filtered_clean.vcf.gz
bcftools index filtered_clean.vcf.gz

echo "Sample removal complete"

# -------------------------------
# Step 2: Keep only biallelic SNPs
# -------------------------------
echo "Filtering to biallelic SNPs..."

bcftools view -v snps -m2 -M2 filtered_clean.vcf.gz -Oz -o final_snps.vcf.gz
bcftools index final_snps.vcf.gz

echo "Biallelic SNP filtering complete"

# -------------------------------
# Final summary
# -------------------------------
echo "Final SNP count:"
bcftools view -H final_snps.vcf.gz | wc -l

echo "========================="
echo "Final VCF ready: final_snps.vcf.gz"
echo "End time: $(date)"
echo "========================="