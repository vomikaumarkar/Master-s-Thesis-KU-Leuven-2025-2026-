#!/bin/bash -l 
#SBATCH --cluster=genius 
#SBATCH --job-name=stats 
#SBATCH --nodes=1 
#SBATCH --cpus-per-task=8
#SBATCH --time=04:00:00 
#SBATCH -A lp_svbelleghem
#SBATCH -o stats.%j.out

# Stop script on error
set -e

# Load conda
source /user/leuven/373/vsc37319/miniconda3/etc/profile.d/conda.sh

# Activate environment
conda activate vcftools

# Check version
bcftools --version
vcftools --version

# Directory
cd /scratch/leuven/373/vsc37319/GWAS/vcf

# VCF File
VCF=P_chalceus_SW_renamed.vcf.gz

echo "========================="
echo "Running VCF statistics"
echo "Start time: $(date)"
echo "========================="

# 1. Overall stats
bcftools stats $VCF > vcf_stats.txt

# 2. Quick summary
grep -E "^SN|TSTqV" vcf_stats.txt > vcf_summary.txt

# 3. Missingness per individual
vcftools --gzvcf $VCF --missing-indv --out missing_indv

# 4. Allele frequency
vcftools --gzvcf $VCF --freq --out allele_freq

# 5. SNP density (1 Mb windows)
vcftools --gzvcf $VCF --SNPdensity 1000000 --out snp_density

echo "========================="
echo "Stats complete"
echo "End time: $(date)"
echo "========================="
