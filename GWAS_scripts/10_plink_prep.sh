#!/bin/bash -l
#SBATCH --cluster=genius
#SBATCH --job-name=plink_prep
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --time=04:00:00
#SBATCH -A lp_svbelleghem
#SBATCH -o plink_prep.%j.out

set -e

# Activate conda
source /user/leuven/373/vsc37319/miniconda3/etc/profile.d/conda.sh
conda activate gemma_env

cd /scratch/leuven/373/vsc37319/GWAS/vcf

VCF=final_snps.vcf.gz

echo "========================="
echo "PLINK conversion"
echo "Start: $(date)"
echo "========================="

# Convert VCF → PLINK
plink --vcf $VCF \
      --double-id \
      --allow-extra-chr \
      --make-bed \
      --out gwas_input

# Fix .fam phenotype column for GEMMA
echo "Checking .fam phenotype column:"
head gwas_input.fam

echo "Fixing .fam phenotype column (replace -9 with 1)..."
awk '{$6=1; print}' gwas_input.fam > gwas_input.tmp.fam
mv gwas_input.tmp.fam gwas_input.fam  

# Quick check
head gwas_input.fam 
      
# QC step
plink --bfile gwas_input --freq --allow-extra-chr --out gwas_input
plink --bfile gwas_input --missing --allow-extra-chr --out missing_check

echo "========================="
echo "PLINK prep complete"
echo "End: $(date)"
echo "========================="
