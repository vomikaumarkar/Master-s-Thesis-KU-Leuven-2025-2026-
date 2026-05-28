#!/bin/bash -l
#SBATCH --cluster=wice
#SBATCH --partition=batch
#SBATCH --job-name=find_candidate_genes
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:20:00
#SBATCH --account=lp_svbelleghem
#SBATCH --output=find_candidate_genes.%j.out
#SBATCH --error=find_candidate_genes.%j.err

set -e

module load BEDTools

cd /scratch/leuven/373/vsc37319/GWAS/vcf/gemma_results/significant_snps

mkdir -p candidate_genes

GENES=/scratch/leuven/373/vsc37319/annotation-Pogonus-SW/annotation_bed/genes.bed

echo "======================="
echo "Finding candidate genes"
echo "======================="

for f in bed_files/*.bed; do

    base=$(basename "$f" .bed)

    # SNPs overlapping genes
    bedtools intersect -wa -wb \
        -a "$f" \
        -b "$GENES" \
        > candidate_genes/${base}_overlapping_genes.txt

    # Nearest genes within 10 kb
    bedtools window \
        -w 10000 \
        -a "$f" \
        -b "$GENES" \
        > candidate_genes/${base}_nearby_genes_10kb.txt

done

echo "======================="
echo "Candidate gene search complete"
echo "======================="