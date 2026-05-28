#!/bin/bash -l
#SBATCH --cluster=wice
#SBATCH --partition=batch
#SBATCH --job-name=extract_genes
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH --account=lp_svbelleghem
#SBATCH --output=extract_genes.%j.out
#SBATCH --error=extract_genes.%j.err

set -e

cd /scratch/leuven/373/vsc37319/annotation-Pogonus-SW

mkdir -p annotation_bed

echo "======================="
echo "Extracting genes from GTF"
echo "======================="

awk '
BEGIN{OFS="\t"}

$3=="gene" {

    chr=$1
    sub(/^CHR/,"",chr)

    attrs=""

    for(i=9;i<=NF;i++) {
        attrs=attrs" "$i
    }

    gene_id="NA"
    gene_name="NA"
    product="NA"
    note="NA"

    if (match(attrs,/gene_id "[^"]+"/)) {
        gene_id=substr(attrs,RSTART+9,RLENGTH-10)
    }

    if (match(attrs,/gene_name "[^"]+"/)) {
        gene_name=substr(attrs,RSTART+11,RLENGTH-12)
    }

    if (match(attrs,/product "[^"]+"/)) {
        product=substr(attrs,RSTART+9,RLENGTH-10)
    }

    if (match(attrs,/note "[^"]+"/)) {
        note=substr(attrs,RSTART+6,RLENGTH-7)
    }

    print chr,$4-1,$5,gene_id,gene_name,product,note
}
' braker.annotated.gtf \
> annotation_bed/genes.bed

echo "======================="
echo "Gene extraction complete"
echo "======================="