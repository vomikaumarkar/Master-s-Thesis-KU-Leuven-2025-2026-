#!/bin/bash -l 
#SBATCH --cluster=genius 
#SBATCH --job-name=check_names 
#SBATCH --nodes=1 
#SBATCH --cpus-per-task=2
#SBATCH --time=2:00:00 
#SBATCH -A lp_svbelleghem
#SBATCH -o check_names.%j.out

# Stop script on error
set -e

# Load package
module load BCFtools/1.18-GCC-12.3.0

echo "========================="
echo "Checking sample name consistency"
echo "Job ID: $SLURM_JOB_ID"
echo "Start time:  $(date)"
echo "========================="

# DIRECTORIES
VCF_DIR=/scratch/leuven/373/vsc37319/GWAS/vcf

cd /scratch/leuven/373/vsc37319/GWAS

# INPUT FILE 
VCF_FILE=$VCF_DIR/P_chalceus_SW_renamed.vcf.gz
PHENO_FILE=phenotype_final.txt

# Check files exist
if [ ! -f "$VCF_FILE" ]; then
   echo "ERROR: VCF file not found: $VCF_FILE"
   exit 1
fi

if [ ! -f "$PHENO_FILE" ]; then
   echo "ERROR: Phenotype file not found: $PHENO_FILE"
   exit 1
fi

echo "VCF file: $VCF_FILE"
echo "Phenotype file: $PHENO_FILE"
echo "=============================="

# Extract sample names
bcftools query -l "$VCF_FILE" > vcf_samples.txt

# Adjust column depending on your phenotype format
cut -f2 "$PHENO_FILE" > phenotype_samples.txt

# Sort files
sort vcf_samples.txt > vcf_samples_sorted.txt
sort phenotype_samples.txt > phenotype_samples_sorted.txt

# Compare sample lists
comm -3 vcf_samples_sorted.txt phenotype_samples_sorted.txt > sample_mismatch.txt

echo "==========================="
echo "Comparison complete"
echo "Mismatched samples saved in: sample_mismatch.txt"
echo "==========================="

# Optional summary
echo "Number of VCF samples:"
wc -l vcf_samples.txt

echo "Number of phenotype samples:"
wc -l phenotype_samples.txt

echo "Number of mismatches:"
wc -l sample_mismatch.txt

echo "============================="
echo "END time: $(date)"
echo "============================="
