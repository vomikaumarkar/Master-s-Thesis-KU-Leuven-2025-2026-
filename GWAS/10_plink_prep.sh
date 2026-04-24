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

# QC step
plink --bfile gwas_input --freq --allow-extra-chr --out gwas_input
plink --bfile gwas_input --missing --allow-extra-chr --out missing_check

echo "========================="
echo "PLINK prep complete"
echo "End: $(date)"
echo "========================="