#!/bin/bash -l 
#SBATCH --cluster=genius 
#SBATCH --job-name merge 
#SBATCH --nodes=1 
#SBATCH --cpus-per-task=4
#SBATCH --time=12:00:00 
#SBATCH -A lp_svbelleghem
#SBATCH -o merge_vcfs.%j.out

# Stop script on error
set -e

# Load package
module load BCFtools/1.18-GCC-12.3.0

echo "=============================="
echo "Starting VCF merge"
echo "Job ID: $SLURM_JOB_ID"
echo "Start time: $(date)"
echo "==============================="

# For local bcftools install:
# Module load Python/3.7.0-foss-2018a
# Export BCFTOOLS_PLUGINS=/data/leuven/361/vsc36175/bcftools/plugins

# Working directory
cd /scratch/leuven/373/vsc37319/GWAS/vcf

# Collect VCF files
mapfile -t VCF < <(ls -1v *.vcf.gz)

if [ ${#VCF[@]} -eq 0 ]; then
   echo "ERROR: No VCF files found!"
   exit 1
fi

echo "VCF files found:"
printf "%s\n" "${VCF[@]}"
echo "====================="

# Output file 
OUT=P_chalceus_SW_merged.vcf.gz

# Concatenate VCFs
bcftools concat -Oz -o "$OUT" "${VCF[@]}"

# Index merged VCF
bcftools index "$OUT"

echo "======================"
echo "Merge complete"
echo "Output: $OUT"
echo "END time: $(date)"
echo "======================="
