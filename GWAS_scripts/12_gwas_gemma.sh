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
SEX=/scratch/leuven/373/vsc37319/GWAS/covariates_sex.txt

mkdir -p gemma_results

echo "========================="
echo "Running GEMMA GWAS"
echo "========================="

# Trait 1: EL with sex as covariate
gemma -bfile gwas_input \
      -k $KINSHIP \
      -p $PHENO \
      -c $SEX \
      -n 1 \
      -lmm 4 \
      -outdir gemma_results \
      -o EL_sex

# Trait 1: EL without sex as covariate
gemma -bfile gwas_input \
      -k $KINSHIP \
      -p $PHENO \
      -n 1 \
      -lmm 4 \
      -outdir gemma_results \
      -o EL      

# Trait 2: relMRWS with sex as a covariate
gemma -bfile gwas_input \
      -k $KINSHIP \
      -p $PHENO \
      -c $SEX \
      -n 2 \
      -lmm 4 \
      -outdir gemma_results \
      -o relMRWS_sex

# Trait 2: relMRWS without sex as a covariate
gemma -bfile gwas_input \
      -k $KINSHIP \
      -p $PHENO \
      -n 2 \
      -lmm 4 \
      -outdir gemma_results \
      -o relMRWS

# Trait 3: avg_time with sex as a covariate
gemma -bfile gwas_input \
      -k $KINSHIP \
      -p $PHENO \
      -c $SEX \
      -n 3 \
      -lmm 4 \
      -outdir gemma_results \
      -o avg_time_sex

# Trait 3: avg_time without sex as a covariate
gemma -bfile gwas_input \
      -k $KINSHIP \
      -p $PHENO \
      -n 3 \
      -lmm 4 \
      -outdir gemma_results \
      -o avg_time     

# Trait 4: emerge_count with sex as a covariate
gemma -bfile gwas_input \
      -k $KINSHIP \
      -p $PHENO \
      -c $SEX \
      -n 4 \
      -lmm 4 \
      -outdir gemma_results \
      -o emerge_count_sex

# Trait 4: emerge_count without sex as a covariate
gemma -bfile gwas_input \
      -k $KINSHIP \
      -p $PHENO \
      -n 4 \
      -lmm 4 \
      -outdir gemma_results \
      -o emerge_count
      
echo "========================="
echo "GWAS complete"
echo "========================="
