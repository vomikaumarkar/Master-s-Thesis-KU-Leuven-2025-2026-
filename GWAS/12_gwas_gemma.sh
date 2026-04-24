#!/bin/bash -l
#SBATCH --cluster=genius
#SBATCH --job-name=gemma_gwas
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --time=12:00:00
#SBATCH -A lp_svbelleghem
#SBATCH -o gemma_gwas.%j.out

set -e

source /user/leuven/373/vsc37319/miniconda3/etc/profile.d/conda.sh
conda activate gemma_env

cd /scratch/leuven/373/vsc37319/GWAS/vcf

PHENO=/scratch/leuven/373/vsc37319/GWAS/phenotype_final.txt
KINSHIP=kinship_matrix/gwas_input.cXX.txt

mkdir -p gemma_results

echo "========================="
echo "Running GEMMA GWAS"
echo "========================="

# Trait 1: EL
gemma -bfile gwas_input \
      -k $KINSHIP \
      -pheno $PHENO \
      -n 1 \
      -lmm 4 \
      -outdir gemma_results \
      -o EL

# Trait 2: relMRWS
gemma -bfile gwas_input \
      -k $KINSHIP \
      -pheno $PHENO \
      -n 2 \
      -lmm 4 \
      -outdir gemma_results \
      -o relMRWS

# Trait 3: avg_time
gemma -bfile gwas_input \
      -k $KINSHIP \
      -pheno $PHENO \
      -n 3 \
      -lmm 4 \
      -outdir gemma_results \
      -o avg_time
      
echo "========================="
echo "GWAS complete"
echo "========================="