#!/bin/bash -l
#SBATCH --cluster=genius
#SBATCH --job-name=index_ref
#SBATCH --nodes=1
#SBATCH --tasks=1
#SBATCH --cpus-per-task=4
#SBATCH --time=02:00:00
#SBATCH -A lp_svbelleghem
#SBATCH -o 0_index.%j.out

module load BWA/0.7.17-foss-2018a

REF=/scratch/leuven/373/vsc37319/GWAS/Pchalceus_SW.sorted.fasta

echo "=============================="
echo "Starting BWA indexing"
echo "Reference: $REF"
echo "Job ID: $SLURM_JOB_ID"
echo "Start time: $(date)"
echo "=============================="

bwa index $REF

echo "=============================="
echo "Indexing finished"
echo "End time: $(date)"
echo "=============================="
