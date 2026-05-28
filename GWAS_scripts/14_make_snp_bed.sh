#!/bin/bash -l
#SBATCH --cluster=wice
#SBATCH --partition=batch
#SBATCH --job-name=make_snp_beds
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH --account=lp_svbelleghem
#SBATCH --output=make_snp_beds.%j.out
#SBATCH --error=make_snp_beds.%j.err

set -e

cd /scratch/leuven/373/vsc37319/GWAS/vcf/gemma_results/significant_snps

mkdir -p bed_files

echo "======================="
echo "Converting SNPs to BED"
echo "======================="

for f in *.txt; do

    base=$(basename "$f" .txt)

    awk 'NR>1 {
        print $1"\t"$3-1"\t"$3"\t"$2"\t"$4
    }' "$f" > bed_files/${base}.bed

done

echo "======================="
echo "BED conversion complete"
echo "======================="