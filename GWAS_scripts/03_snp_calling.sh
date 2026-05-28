#!/bin/bash -l 
#SBATCH --cluster=genius 
#SBATCH --job-name=snps 
#SBATCH --nodes=1 
#SBATCH --cpus-per-task=20
#SBATCH --time=24:00:00 
#SBATCH -A lp_svbelleghem
#SBATCH -o call_snps.%j.out

# Stop script on error
set -e

# ARRAY JOB
ID=$((SLURM_ARRAY_TASK_ID -1))

# LOAD SOFTWARE
module load BCFtools/1.18-GCC-12.3.0

# for local BCFtools:
# module load Python/3.7.0-foss-2018a
# export BCFTOOLS_PLUGINS=/data/leuven/373/vsc37319/GWAS/bcftools/plugins

echo "=============================="
echo "Starting SNP calling"
echo "Job ID: $SLURM_JOB_ID"
echo "Array ID: $SLURM_ARRAY_TASK_ID"
echo "Start time: $(date)"
echo "=============================="

# Chromosmomes
chrom=(CHR1 CHR2 CHR3 CHR4 CHR5 CHR6 CHR7 CHR8 CHR9 CHR10 CHR11)
names=(01 02 03 04 05 06 07 08 09 10 11)

# Check index 
if [ -z "${chrom[$ID]}" ]; then
    echo "ERROR: Invalid chromosome index"
    exit 1
fi

# Reference
REF=/scratch/leuven/373/vsc37319/GWAS/Pchalceus_SW.sorted.fasta
REFNAME=BarSW

# Working Directory
BAM_DIR=/scratch/leuven/373/vsc37319/GWAS/bams

# Get all the BAM files
mapfile -t BAMS < <(find "$BAM_DIR" -maxdepth 1 -name "*.filtered.sorted.bam")

echo "Current directory: $(pwd)"
echo "Listing BAM directory:"
ls -lh /scratch/leuven/373/vsc37319/GWAS/bams

if [ ${#BAMS[@]} -eq 0 ]; then
    echo "ERROR: No BAM files found!"
    exit 1
fi

echo "Reference: $REF"
echo "Chromosome: ${chrom[$ID]}"
echo "NUmber of BAMs: ${#BAMS[@]}"

#Output file 
OUTDIR=/scratch/leuven/373/vsc37319/GWAS/vcf
mkdir -p $OUTDIR
OUT=$OUTDIR/P_chalceus_${REFNAME}.chr_${names[$ID]}.vcf.gz

# SNP calling
bcftools mpileup \
    -f $REF \
    -r ${chrom[$ID]} \
    --threads 20 \
    -Ou "${BAMS[@]}" | \
bcftools call \
    -m \
    -Oz \
    -o $OUT

# Index VCF
bcftools index $OUT

echo "========================="
echo "SNP calling finished"
echo "Output: $OUT"
echo "End time: $(date)"
echo "========================="
