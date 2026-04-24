#!/bin/bash -l
#SBATCH --cluster=genius
#SBATCH --job-name=kinship
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --time=04:00:00
#SBATCH -A lp_svbelleghem
#SBATCH -o kinship.%j.out

# Stop script if error
set -e

# Load Conda
source /user/leuven/373/vsc37319/miniconda3/etc/profile.d/conda.sh
conda activate gemma_env

cd /scratch/leuven/373/vsc37319/GWAS/vcf

echo "========================="
echo "Generating kinship matrix"
echo "Start time: $(date)"
echo "========================="

# Step 1: PLINK GRM
plink --bfile gwas_input \
      --make-grm-bin \
      --allow-extra-chr \
      --out gwas_input_grm

# Step 2: GEMMA kinship
mkdir -p kinship_matrix

gemma -bfile gwas_input \
      -gk 1 \
      -outdir kinship_matrix \
      -o gwas_input

echo "Kinship files:"
ls kinship_matrix/

echo "========================="
echo "Kinship matrix complete"
echo "End time: $(date)"
echo "========================="
