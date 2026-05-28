#!/bin/bash -l
#SBATCH --cluster=wice
#SBATCH --partition=batch
#SBATCH --job-name=get_sig_snps
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --time=1:00:00
#SBATCH --account=lp_svbelleghem
#SBATCH --output=get_sig_snps.%j.out

# Stop script if an error
set -e

# Working directory 
cd /scratch/leuven/373/vsc37319/GWAS/vcf/gemma_results

mkdir -p significant_snps

echo "========================"
echo "Getting significant SNPs"
echo "========================"

for f in *.assoc.txt; do
    base=$(basename "$f" .assoc.txt)

    awk 'NR==1 || $13 < 5e-8 {print $1, $2, $3, $13}' "$f" \
        > significant_snps/${base}_bonferroni_snps.txt

    awk 'NR==1 || $13 < 1e-5 {print $1, $2, $3, $13}' "$f" \
        > significant_snps/${base}_suggestive_snps.txt
done

echo "================================"
echo "Significant SNPs positions found"
echo "================================"