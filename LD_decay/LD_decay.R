library(dplyr)
library(ggplot2)
library(patchwork)
library(glue)

# Set Working Directory 
setwd("/Users/vomikaumarkar/Library/Mobile Documents/com~apple~CloudDocs/Desktop/Master's_Thesis/GWAS/LD")

# Read LD data
ld <- read.table("ld_distance_r2.txt", header=FALSE)

colnames(ld) <- c("chr","distance","r2")

# Remove negative distances if any
ld <- ld[ld$distance >= 0, ]

# Create 1 kb bins
ld$bin <- floor(ld$distance / 1000) * 1000

# Distance where LD drops below 0.2
ld_decay <- ld_summary2 %>%
  group_by(chr) %>%
  filter(mean_r2 < 0.2) %>%
  summarise(decay_distance_bp = min(bin))

ld_decay

# Distance where LD drops below 0.1
ld_decay2 <- ld_summary2 %>%
  group_by(chr) %>%
  filter(mean_r2 < 0.1) %>%
  summarise(decay_distance_bp = min(bin))

ld_decay2

# Background ld levels
ld_summary2 %>%
  filter(bin > 50000) %>%
  summarise(background_r2 = mean(mean_r2, na.rm = TRUE))

ld_summary2

# Plot with mean of all chromosmes #
####################################
# Mean LD per bin
ld_summary <- ld %>%
  group_by(bin) %>%
  summarise(mean_r2 = mean(r2, na.rm=TRUE))

# Plot
p3 <- ggplot(ld_summary, aes(x=bin, y=mean_r2)) +
  geom_line() +
  xlab("Distance (bp)") +
  ylab(expression(LD~(r^2))) +
  theme_bw()
p3

# LD per chromosom #
#####################
ld_summary2 <- ld %>%
  group_by(chr, bin) %>%
  summarise(mean_r2 = mean(r2, na.rm = TRUE),
            .groups = "drop")

# One plot with chromosomes of different colours
p <- ggplot(ld_summary2,
            aes(x = bin,
                y = mean_r2,
                color = factor(chr))) +
  
  geom_line(linewidth = 1) +
  
  geom_hline(yintercept = 0.2,
             linetype = "dashed",
             color = "red") +
  
  xlab("Distance (bp)") +
  ylab(expression(LD~(r^2))) +
  
  labs(color = "Chromosome") +
  
  theme_bw() +

  theme(
    text = element_text(size = 16),          
    axis.title = element_text(size = 18),   
    axis.text = element_text(size = 14),     
    strip.text = element_text(size = 16) 
  )
p

# Separate plot for each chromosome
chr_list <- unique(ld_summary2$chr)

plot_list <- lapply(chr_list, function(ch) {
  
  ggplot(filter(ld_summary2, chr == ch),
         aes(x = bin, y = mean_r2)) +
    
    geom_line() +
    
    geom_hline(yintercept = 0.2,
               linetype = "dashed",
               color = "red") +
    
    xlab("Distance (bp)") +
    ylab(expression(LD~(r^2))) +
    
    ggtitle(paste("Chr", ch)) +
    
    theme_bw() +
    
    theme(
      text = element_text(size = 16),
      axis.title = element_text(size = 18),
      axis.text = element_text(size = 14),
      plot.title = element_text(size = 16, hjust = 0.5)
    )
})

# Add the combined chromosome plot as the 12th panel
plot_list[[12]] <- p

# Arrange as 4 columns:
# Row1 = chr1-4
# Row2 = chr5-8
# Row3 = chr9-11 + p
final_plot <- wrap_plots(plotlist = plot_list, ncol = 4)
final_plot

# Save plots
ggsave("ld_decay_plot.png", plot =  p3, width=8, height=6)
ggsave("ld_decay_per_chromosome.png", plot = p, width = 14, height = 10)
ggsave("ld_decay_per_chromosome_separate.png", plot = p2, width = 14, height = 10)
ggsave("ld_decay_across_chrom0.2.png", plot = final_plot, width = 24, height = 12)
ggsave("ld_decay_across_chrom0.1.png", plot = final_plot, width = 24, height = 12)
