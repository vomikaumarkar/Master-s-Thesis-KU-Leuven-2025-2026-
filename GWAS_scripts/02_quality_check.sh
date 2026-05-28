#!/bin/bash -l 
#SBATCH --cluster=genius 
#SBATCH --job-name qc
#SBATCH --nodes=1 
#SBATCH --tasks=1
#SBATCH --cpus-per-task=8
#SBATCH --time=24:00:00 
#SBATCH -A lp_svbelleghem
#SBATCH -o bams_qc.%j.out

# Stop script on error
set -e

# Set directory
BAM_DIR=/scratch/leuven/373/vsc37319/GWAS/bams
cd $BAM_DIR

# Load module
module load libdeflate/1.18-GCCcore-12.3.0
module load SAMtools/1.18-GCC-12.3.0

echo "================================"
echo "Starting BAM quality checks"
echo "Working directory: $(pwd)"
echo "Start time: $(date)"
echo "================================="

# Get BAM files and ensure they exist
mapfile -t bams_files < <(find $BAM_DIR -name "*.filtered.sorted.bam")

#Check if files exist
if [ ${#bams_files[@]} -eq 0 ]; then
    echo "ERROR: No BAM files found in directory!"
    exit 1
fi

# Count files
num_bams=${#bams_files[@]}
echo "Number of BAM files: $num_bams"
echo "==============================="

# MAPPING STATISTICS
echo "Generating mapping statistics..."

> mapping_stats.txt

for bam in "${bams_files[@]}"; do 
    echo "===== $bam =====" >> mapping_stats.txt 
    samtools flagstat "$bam" >> mapping_stats.txt
    echo " " >> mapping_stats.txt
done > mapping_stats.txt

echo "Mapping statistics saved to mapping_stats.txt"
echo "================================"

# BAM INTEGRITY CHECK

# Output file for errors
ERROR_LOG="quickcheck_failed_bams.txt"

# Empty the error log file before running
> "$ERROR_LOG"

echo "Checking BAM file integrity..."

# Loop through all filtered.sorted.bam files
for bam in "$bams_files"; do
    if ! samtools quickcheck "$bam"; then
        echo "$bam" >> "$ERROR_LOG"
    fi
done

echo "Integrity check complete"
echo "Files with errors are listed in: $ERROR_LOG"
echo "=========================="

# AVERAGE DEPTH CALCULATION
echo "Calculating average sequencing depth..."

echo -e "Sample\tAvergaeDepth" > average_depths.txt

for bam in "$bams_files"; do 
    sample=$(basename "$bam" .bam)
    depth=$(samtools depth "$bam" | awk '{sum+=3} END {if (NR>0) print sum/NR; else print "0"}') 
    echo -e "$sample\t$depth" >> average_depths.txt
done

echo "Average depth saved to average_depths.txt"
echo "======================="
echo "Quality check complete"
echo "End time: $(date)"
echo "========================"
