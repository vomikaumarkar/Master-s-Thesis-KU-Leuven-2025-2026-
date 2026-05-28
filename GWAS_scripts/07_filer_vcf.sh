#!/bin/bash -l 
#SBATCH --cluster=genius 
#SBATCH --job-name=filter 
#SBATCH --nodes=1 
#SBATCH --cpus-per-task=20
#SBATCH --time=12:00:00 
#SBATCH -A lp_svbelleghem
#SBATCH -o filter_vcf.%j.out

# Stop script on error
set -e

# Load Conda
source /user/leuven/373/vsc37319/miniconda3/etc/profile.d/conda.sh

#Activate environment
conda activate vcftools

# Directory
cd /scratch/leuven/373/vsc37319/GWAS/vcf

# VCF File
VCF=P_chalceus_SW_renamed.vcf.gz

echo "========================="
echo "Starting filtering: $(date)"
echo "========================="

# Keep SNPs only
vcftools --gzvcf $VCF \
  --remove-indels \
  --recode --recode-INFO-all \
  --stdout | bgzip > snps_only.vcf.gz

# Filter SNPs
vcftools --gzvcf snps_only.vcf.gz \
  --max-missing 0.8 \
  --maf 0.05 \
  --minQ 30 \
  --recode --recode-INFO-all \
  --stdout | bgzip > filtered_snps.vcf.gz

echo "========================="
echo "Filtering complete: $(date)"
echo "========================="
