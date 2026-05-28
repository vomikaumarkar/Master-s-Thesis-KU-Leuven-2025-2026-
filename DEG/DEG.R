#Open all libraries
library(data.table)
library(dplyr)
library(stringr)
library(ggplot2)
library(patchwork)
library(cowplot)
library(glue)

# Set working directory
dir <- "/Users/vomikaumarkar/Library/Mobile Documents/com~apple~CloudDocs/Desktop/Master's_Thesis/GWAS/GWAS_Assoc_Results/DEG/deseq2"
setwd(dir)

deg <- read.delim(
  "DESeq2_SW_vs_LW.annotated.tsv",
  sep = "\t",
  stringsAsFactors = FALSE
)

deg <- subset(deg, !is.na(padj) & padj < 0.1)

deg$diff_expr <- ifelse(
  deg$log2FoldChange > 0,
  "upregulation",
  "downregulation"
)

# =========================================================
# LOAD GTF
# =========================================================

gtf <- fread(
  "braker.annotated.gtf",
  sep = "\t",
  header = FALSE,
  quote = ""
)

colnames(gtf) <- c(
  "chromosome",
  "source",
  "feature",
  "Start",
  "End",
  "score",
  "strand",
  "frame",
  "attribute"
)

gtf_gene <- gtf %>%
  filter(feature == "gene")

gtf_gene$gene_id <- str_extract(
  gtf_gene$attribute,
  'gene_id "[^"]+"'
)

gtf_gene$gene_id <- str_replace_all(
  gtf_gene$gene_id,
  'gene_id "|"',
  ""
)

gtf_gene$chromosome <- gsub(
  "CHR",
  "",
  gtf_gene$chromosome
)

gtf_gene$chromosome <- as.numeric(
  gtf_gene$chromosome
)

gtf_gene <- gtf_gene %>%
  select(
    gene_id,
    chromosome,
    Start,
    End
  )

# =========================================================
# MERGE DEGs WITH COORDINATES
# =========================================================

deg <- merge(
  deg,
  gtf_gene,
  by = "gene_id",
  all.x = TRUE
)

deg <- deg %>%
  filter(
    !is.na(chromosome),
    !is.na(Start)
  )

# =========================================================
# LOAD FAI
# =========================================================

fai <- fread(
  "Pchalceus_SW.sorted.fasta.fai",
  header = FALSE
)

colnames(fai)[1:2] <- c("chr", "length")

fai$chr <- gsub(
  "chr",
  "",
  fai$chr,
  ignore.case = TRUE
)

fai$chr <- as.numeric(fai$chr)

fai <- fai %>%
  filter(chr %in% 1:11) %>%
  arrange(chr) %>%
  mutate(
    chromStart = cumsum(lag(length, default = 0)),
    chromMid = chromStart + length / 2
  )

# =========================================================
# ADD CUMULATIVE POSITIONS TO DEGs
# =========================================================

deg <- deg %>%
  left_join(
    fai,
    by = c("chromosome" = "chr")
  ) %>%
  mutate(
    chromPos = Start + chromStart
  )

# =========================================================
# LOAD BELGIUM FST
# =========================================================

fst_list <- list()

for (i in 1:11) {
  
  file <- paste0(
    "pop_0/Pchal_Bar_SW.chr_",
    i,
    ".pop0.stats"
  )
  
  tmp <- fread(file)
  
  tmp$chromosome <- i
  
  tmp$FstWC_B_NIE_T_B_DUD_S_egg[
    tmp$FstWC_B_NIE_T_B_DUD_S_egg == "None"
  ] <- NA
  
  tmp$FstWC_B_NIE_T_B_DUD_S_egg <-
    as.numeric(tmp$FstWC_B_NIE_T_B_DUD_S_egg)
  
  tmp$FstWC_B_NIE_T_B_DUD_S_egg[
    tmp$FstWC_B_NIE_T_B_DUD_S_egg < 0
  ] <- 0
  
  fst_list[[i]] <- tmp
}

FstBelgium <- bind_rows(fst_list)

FstBelgium <- FstBelgium %>%
  left_join(
    fai,
    by = c("chromosome" = "chr")
  ) %>%
  mutate(
    chromPos = mid + chromStart
  )

# =========================================================
# LOAD SPAIN FST
# =========================================================

fst_list2 <- list()

for (i in 1:11) {
  
  file2 <- paste0(
    "pop_2/Pchal_Bar_SW.chr_",
    i,
    ".pop2.stats"
  )
  
  tmp2 <- fread(
    file2,
    na.strings = c("None", "NA", ".")
  )
  
  tmp2$chromosome <- i
  
  tmp2$FstWC_BARBATE_SW_BARBATE_LW_egg <-
    as.numeric(tmp2$FstWC_BARBATE_SW_BARBATE_LW_egg)
  
  tmp2$FstWC_BARBATE_SW_BARBATE_LW_egg[
    tmp2$FstWC_BARBATE_SW_BARBATE_LW_egg < 0
  ] <- 0
  
  fst_list2[[i]] <- tmp2
}

FstSpain <- bind_rows(fst_list2)

FstSpain <- FstSpain %>%
  left_join(
    fai,
    by = c("chromosome" = "chr")
  ) %>%
  mutate(
    chromPos = mid + chromStart
  )

# =========================================================
# CHROMOSOME AXIS LABELS
# =========================================================

axis_df <- fai %>%
  mutate(center = chromStart + length/2)

# =========================================================
# PLOT UPREGULATED
# =========================================================

p_up <- ggplot(
  subset(deg, diff_expr == "upregulation"),
  aes(
    x = chromPos,
    y = log2FoldChange
  )
) +
  
  geom_point(
    aes(size = -log10(padj)),
    color = "#F8766D",
    alpha = 0.6
  ) +
  
  scale_x_continuous(
    breaks = axis_df$center,
    labels = paste0("Chr", axis_df$chr)
  ) +
  
  coord_cartesian(ylim = c(0, 10)) +
  
  theme_classic() +
  
  theme(
    axis.text.x = element_blank(),
    axis.title.x = element_blank()
  ) +
  
  labs(y = "log2FC",
       title = "Genes upregulated in short-winged ecotype")

# =========================================================
# PLOT DOWNREGULATED
# =========================================================

p_down <- ggplot(
  subset(deg, diff_expr == "downregulation"),
  aes(
    x = chromPos,
    y = log2FoldChange
  )
) +
  
  geom_point(
    aes(size = -log10(padj)),
    color = "#00BFC4",
    alpha = 0.6
  ) +
  
  geom_vline(
    xintercept = fai$chromStart,
    color = "grey80"
  ) +
  
  scale_x_continuous(
    breaks = axis_df$center,
    labels = paste0("Chr", axis_df$chr)
  ) +
  
  coord_cartesian(ylim = c(-10, 0)) +
  
  theme_classic() +
  
  theme(
    axis.text.x = element_blank(),
    axis.title.x = element_blank()
  ) +
  
  labs(y = "log2FC",
       title = "Genes upregulated in long-winged ecotype")

# =========================================================
# BELGIUM FST
# =========================================================

p_be <- ggplot(
  FstBelgium,
  aes(
    x = chromPos,
    y = FstWC_B_NIE_T_B_DUD_S_egg
  )
) +
  
  geom_point(
    color = "orange4",
    size = 0.5,
    alpha = 0.6
  ) +
  
  geom_hline(
    yintercept = 0.2,
    linetype = "dashed"
  ) +
  
  geom_vline(
    xintercept = fai$chromStart,
    color = "grey80"
  ) +
  
  scale_x_continuous(
    breaks = axis_df$center,
    labels = paste0("Chr", axis_df$chr)
  ) +
  
  theme_classic() +
  
  theme(
    axis.text.x = element_blank(),
    axis.title.x = element_blank()
  ) +
  
  labs(y = "FST Belgium")

# =========================================================
# SPAIN FST
# =========================================================

p_sp <- ggplot(
  FstSpain,
  aes(
    x = chromPos,
    y = FstWC_BARBATE_SW_BARBATE_LW_egg
  )
) +
  
  geom_point(
    color = "steelblue",
    size = 0.5,
    alpha = 0.6
  ) +
  
  geom_hline(
    yintercept = 0.2,
    linetype = "dashed"
  ) +
  
  geom_vline(
    xintercept = fai$chromStart,
    color = "grey80"
  ) +
  
  scale_x_continuous(
    breaks = axis_df$center,
    labels = paste0("Chr", axis_df$chr)
  ) +
  
  theme_classic() +
  
  labs(
    x = "Genome position",
    y = "FST Spain"
  )

# =====================================================
# ASSIGN HIGH FST REGIONS
# =====================================================

high_fst <- FstBelgium %>%
  filter(FstWC_B_NIE_T_B_DUD_S_egg > 0.2)

deg$FSTgroup <- "background"

# simple overlap approximation
for(i in 1:nrow(high_fst)) {
  
  chr_i <- high_fst$chromosome[i]
  pos_i <- high_fst$mid[i]
  
  idx <- which(
    deg$chromosome == chr_i &
      abs(deg$Start - pos_i) < 10000
  )
  
  deg$FSTgroup[idx] <- "high_FST"
}

# =====================================================
# BOXPLOT: UPREGULATED
# =====================================================

library(ggpubr)

p_up_box <- ggplot(
  subset(deg, diff_expr == "upregulation"),
  aes(
    x = FSTgroup,
    y = log2FoldChange,
    color = FSTgroup
  )
) +
  
  coord_cartesian(ylim = c(0, 10)) +
  
  geom_boxplot(alpha = 0.5) +
  
  stat_compare_means(
    method = "wilcox.test",
    label = "p.format"
  ) +
  
  theme_bw() +
  
  labs(
    title = "Genes upregulated in short-winged ecotype",
    x = "",
    y = "log2FC"
  ) +
  
  theme(
    legend.position = "none",
    axis.text.x = element_blank()
  )

# =====================================================
# BOXPLOT: DOWNREGULATED
# =====================================================

p_down_box <- ggplot(
  subset(deg, diff_expr == "downregulation"),
  aes(
    x = FSTgroup,
    y = log2FoldChange,
    color = FSTgroup
  )
) +
  
  coord_cartesian(ylim = c(-10, 0)) +
  
  geom_boxplot(alpha = 0.5) +
  
  stat_compare_means(
    method = "wilcox.test",
    label = "p.format"
  ) +
  
  theme_bw() +
  
  labs(
    title ="Genes upregulated in long-winged ecotype",
    x = "",
    y = "log2FC"
  ) +
  
  theme(
    legend.position = "none", 
    axis.text.x = element_blank()
  )

# =====================================================
# STACK BOXPLOTS
# =====================================================

boxplots <- p_up_box / p_down_box

# =========================================================
# COMBINE
# =========================================================
p_up_box <- p_up_box +
  theme(
    plot.title = element_blank(),
    axis.text.y = element_text(size = 8),
    plot.margin = margin(5, 5, 5, 0)
  )

p_down_box <- p_down_box +
  theme(
    plot.title = element_blank(),
    axis.text.y = element_text(size = 8),
    plot.margin = margin(5, 5, 5, 0)
  )

# =========================================================
# MAKE MAIN LEFT COLUMN
# =========================================================

left_column <- (
  p_up /
    p_down /
    p_be /
    p_sp
) +
  plot_layout(
    heights = c(3, 3, 1.5, 1.5)
  )

# =========================================================
# MAKE RIGHT COLUMN (SMALL WIDTH)
# =========================================================

right_column <- (
  p_up_box /
    p_down_box /
    plot_spacer() /
    plot_spacer()
) +
  plot_layout(
    heights = c(3, 3, 1.5, 1.5)
  )

# =========================================================
# FINAL COMBINED LAYOUT
# =========================================================

final_plot <- left_column | right_column

final_plot <- final_plot +
  plot_layout(
    widths = c(8, 1)   # make boxplots very narrow
  )

# =========================================================
# SAVE
# =========================================================

ggsave(
  "Genomewide_DEG_FST_combined_v3.pdf",
  final_plot,
  width = 18,
  height = 12
)

ggsave(
  "Genomewide_DEG_FST_combined_v3.png",
  final_plot,
  width = 18,
  height = 12,
  dpi = 300
)
