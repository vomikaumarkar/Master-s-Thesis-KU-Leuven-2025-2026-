#Open all libraries
library(carData)
library(car)
library(openxlsx)    # Read/write Excel files
library(dplyr)
library(afex)        # ANOVA and mixed models for factorial experiments
library(lme4)        # Linear and generalized linear mixed models
library(MuMIn)       # Model selection and model averaging
library(emmeans)     # Estimated marginal means (least-squares means)
library(effects)     # Effect plots for regression models
library(ggplot2)     # Data visualization with grammar of graphics (in tidyverse)
library(ggthemes)    # Additional themes and scales for ggplot2
library(grid)        # Low-level graphics system
library(gridExtra)   # Arranging multiple grid-based plots
library(scales)      # for percent_format()
library(ggpubr)      # in combined plots, ex rremove("ylab")
library(readxl)      # for old .XLS format
library(reshape2)    # for function melt to convert data in long format  
library(psych)       # for icc function for repeatibility test
library(lpSolve)     # for package irr
library(irr)         # for kappa function to check repeatibity
library(survival)    # for survival analysis
library(coxme)       # for cox model of survival analysis
library(survminer)   # to visulise survivial analysis

# Set working directory
dir <- "/Users/vomikaumarkar/Library/Mobile Documents/com~apple~CloudDocs/Desktop/Master's_Thesis/R_scripts"
setwd(dir)

# To compare levels (when using factors) to the grand mean and coefficients sum to zero
set_sum_contrasts()

# Load data #
#############
data <- read.xlsx("Dudzele+Nieuwpoort.xlsx", sheet = 1)

# Transform data #
##################
data$IID <- as.factor(data$IID)
data$Sex <- factor(data$Sex, levels = c("M","F"))
data$Locality <- factor(data$Locality, levels = c("Dudzele","Nieuwpoort"))

data$time1 <- as.numeric(data$time1)
data$time2 <- as.numeric(data$time2)
data$time3 <- as.numeric(data$time3)

data$end_pos1 <- factor(data$end_pos1, levels = c("Submerged", "Emerged"))
data$end_pos2 <- factor(data$end_pos2, levels = c("Submerged", "Emerged"))
data$end_pos3 <- factor(data$end_pos3, levels = c("Submerged", "Emerged"))

str(data)

# Calculate %MRWS (Maximum Realizable Wing Size)
A_females = 1.4654 
A_males = 1.4879 
B_females = 0.8454 
B_males = 0.8385 
data$Esize <- data$EL * data$EW
data$Wsize <- data$WL * data$WW

data$maxWsize <- NA

for (i in 1:nrow(data)) {
  ifelse(data$Sex[i]=='F',data$maxWsize[i]<-exp(A_females) * data$Esize[i]^B_females,
         ifelse(data$Sex[i]=='M',data$maxWsize[i]<-exp(A_males) * data$Esize[i]^B_males,NA))
}
data$relMRWS <- data$Wsize/data$maxWsize

############################################
# DIFFERENCE IN MORPHOLOGY BETWEEN BEETLES #
############################################

# Check Correlations Betwen Explainatory Variables 
# EL ~ %MRWS
plot(data$EL, data$relMRWS, xlab = ("Elytra Length"), ylab =("Relative Maximum Realisable Wing Size"))
abline(lm(relMRWS ~ EL, data=data))
cor.test(data$EL, data$relMRWS, method="pearson")

#______________________________________________#
# Compare morphology across the two localities #

# 1. EL #
#########
mean_EL2 <- data %>%
  group_by(Locality) %>%
  summarise(
    label = paste0(
      "F = ", round(mean(EL[Sex == "F"], na.rm = TRUE), 2),
      "   M = ", round(mean(EL[Sex == "M"], na.rm = TRUE), 2)
    )
  )

plot_EL <- ggplot(data, aes(x = Sex, y = EL, fill = Sex)) +
  geom_violin(alpha = 0.6) +
  geom_boxplot(width = 0.1, outlier.shape = NA) +
  geom_jitter(width = 0.2, alpha = 0.6) +
  facet_wrap(~ Locality) +
  scale_x_discrete(labels = c("F" = "Female", "M" = "Male")) +
  labs(title = "Elytra length (mm)") +
  
  geom_text(data = mean_EL2,
            aes(x = 1.5, y = max(data$EL) * 1.05, label = label),
            inherit.aes = FALSE,
            size = 5) +
  
  theme_minimal(base_size = 18)

# 2 relMRWS #
#############
mean_relMRWS <- data %>%
  group_by(Locality) %>%
  summarise(
    label = paste0(
      "F = ", round(mean(relMRWS[Sex == "F"], na.rm = TRUE) * 100, 1), "%  ",
      "M = ", round(mean(relMRWS[Sex == "M"], na.rm = TRUE) * 100, 1), "%"
    )
  )

plot_relMRWS<- ggplot(data, aes(x = Sex, y = relMRWS, fill = Sex)) +
  geom_violin(alpha = 0.6) +
  geom_boxplot(width = 0.1, outlier.shape = NA) +
  geom_jitter(width = 0.2, alpha = 0.6) +
  facet_wrap(~ Locality) +
  scale_x_discrete(labels = c("F" = "Female", "M" = "Male")) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) + 
  labs(title = "Maximum Realisable Wing Size (%)") +
  
  geom_text(data = mean_relMRWS,
            aes(x = 1.5, y = max(data$relMRWS) * 1.05, label = label),
            inherit.aes = FALSE,
            size = 5) +
  
  theme_minimal(base_size = 18)

plot_morph <- grid.arrange(plot_EL,  plot_relMRWS, nrow=2)

#_______________________#
# DATA TRANSFRORMATIONS #
#_______________________#
# Calculate Average Emergence Time
data$avg_time <- rowMeans(data[, c("time1", "time2", "time3")], na.rm = TRUE)

# Convert sex into numeric levels 1,2
data$sex_numeric <- data$Sex
data$sex_numeric <- ifelse(data$Sex == "F", 0,
                           ifelse(data$Sex == "M", 1, 2))

# Count instances of "Emerged"
data$emergeCount <- rowSums(data[
  c('end_pos1', 'end_pos2', 'end_pos3')] == "Emerged",
  na.rm = TRUE)

# Put data in long format 
data_long_time <- melt(data, id.vars = c("IID",'Locality','EL','relMRWS','Sex','emergeCount'), measure.vars = c('time1','time2','time3'),
                       variable.name = "trial", value.name = "time")

data_long_end_pos <- melt(data, id.vars = c("IID",'Locality','EL','relMRWS','Sex','emergeCount'), measure.vars = c('end_pos1','end_pos2','end_pos3'),
                               variable.name = "trial", value.name = "position")

# Get number of trials
data_long_time$trial <- gsub("time", "", data_long_time$trial)  # Convert 'time3' to '3'
data_long_time$trial <- as.factor(data_long_time$trial)
str(data_long_time)

data_long_end_pos$trial <- gsub("end_pos", "", data_long_end_pos$trial)  # Convert 'end_pos3' to '3'
data_long_end_pos$trial <- as.factor(data_long_end_pos$trial)
str(data_long_end_pos)

# Merge the two datasets in long format
data_long <- merge(data_long_time, data_long_end_pos, by = c("IID",'Locality','EL','relMRWS','Sex','emergeCount','trial'))

# Create position numeric with Emerged = 1 and Submerged = 0
data_long$position <- factor(data_long$position,levels = c("Submerged", "Emerged"))
str(data_long)
data_long$position_numeric <- ifelse(data_long$position == 'Emerged', 1, 0)

#############################
# HOW OFTEN BEETLES EMERGED #
#############################

# Are beetles consistent across trials in the two localities #
##############################################################
# icc test
icc(subset(data, Locality == "Dudzele")[, c("time1","time2","time3")])
icc(subset(data, Locality == "Nieuwpoort")[, c("time1","time2","time3")])

# kappam test
kappam.fleiss(subset(data, Locality == "Dudzele")[, c("end_pos1","end_pos2","end_pos3")])
kappam.fleiss(subset(data, Locality == "Nieuwpoort")[, c("end_pos1","end_pos2","end_pos3")])

# Does emergence of beetles differ between localities #
#######################################################
model <- glm(cbind(emergeCount, 3 - emergeCount) ~ Locality,
             family = binomial,
             data = unique(data[, c("IID", "Locality", "emergeCount")]))

summary(model)
levels(data$Locality)

grand_mean <- coef(model)[1]
effect <- coef(model)[2]

# Dudzele
plogis(grand_mean + effect)

# Nieuwpoort
plogis(grand_mean - effect)

# Visualise model 
# Create prediction dataset
newdata <- data.frame(Locality = levels(data$Locality))

# Get plot data
plot_data <- data %>%
  group_by(Locality) %>%
  summarise(
    prob = mean(emergeCount / 3),
    n = n(),
    se = sqrt((prob * (1 - prob)) / n),
    ymin = prob - se,
    ymax = prob + se
  )
  
# Plot
ggplot(plot_data, aes(x = Locality, y = prob, fill = Locality)) +
  geom_col(width = 0.6) +
  geom_errorbar(aes(ymin = ymin, ymax = ymax), width = 0.2) +
  labs(y = "Probability of emergence") +
  theme_minimal(base_size = 18)

# Count for each beetle how often they emerged and compare them between the localities #
########################################################################################
# Summarise per locality
emergeDistribution <- data_long %>%
  distinct(IID, Locality, emergeCount) %>%  # one row per beetle
  count(Locality, emergeCount) %>%
  group_by(Locality) %>%
  mutate(
    proportion = n / sum(n),
    se = sqrt((proportion * (1 - proportion)) / sum(n)),
    ymin = proportion - se,
    ymax = proportion + se,
    emergeLabel = paste0(emergeCount, "/3")
  )

# Plot Side by Side Bars
ggplot(emergeDistribution, 
       aes(x = emergeLabel, y = proportion, fill = Locality)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.7), width = 0.6) +
  geom_errorbar(aes(ymin = ymin, ymax = ymax),
                position = position_dodge(width = 0.7),
                width = 0.2) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    x = "Emergence frequency (out of 3 trials)",
    y = "Beetles (%)",
    fill = "Locality"
  ) +
  theme_minimal(base_size = 18)
 
par(mfrow = c(1, 1))

# Compare actual and randomised data #
######################################
# To test whether individual consistency exceeded random expectation in the two localities.

# Split locality
data_list <- split(data, data$Locality)

# Run randomisation per locality
random_results <- list()

for (loc in names(data_list)) {
  
  df <- data_list[[loc]]
  data_shuffled <- data.frame(matrix(nrow = nrow(df), ncol = 0))
  
  for (seed in 0:99) {
    set.seed(seed)
    
    s1 <- df$end_pos1
    s1[!is.na(s1)] <- sample(na.omit(s1), replace = FALSE)
    
    s2 <- df$end_pos2
    s2[!is.na(s2)] <- sample(na.omit(s2), replace = FALSE)
    
    s3 <- df$end_pos3
    s3[!is.na(s3)] <- sample(na.omit(s3), replace = FALSE)
    
    shuffled_df <- data.frame(s1, s2, s3)
    emerge_count <- rowSums(shuffled_df == "Emerged", na.rm = TRUE)
    
    data_shuffled[[paste0("randomized", seed)]] <- emerge_count
  }
  
  # Frequency distribution
  emergeCountRandom <- matrix(0, nrow = 4, ncol = ncol(data_shuffled))
  rownames(emergeCountRandom) <- 0:3
  
  for (i in seq_along(data_shuffled)) {
    counts <- table(factor(data_shuffled[[i]], levels = 0:3))
    emergeCountRandom[, i] <- counts
  }
  
  # Summarise
  emergeDistributionRandom <- data.frame(
    emergeCount = 0:3,
    mean = rowMeans(emergeCountRandom),
    se = apply(emergeCountRandom, 1, function(x) sd(x) / sqrt(length(x)))
  )
  
  emergeDistributionRandom <- emergeDistributionRandom %>%
    mutate(
      proportion = mean / nrow(df),
      ymin = proportion - se / nrow(df),
      ymax = proportion + se / nrow(df),
      Locality = loc,
      type = "Randomized"
    )
  
  random_results[[loc]] <- emergeDistributionRandom
}

# Combine randomised data
emergeDistributionRandom_all <- bind_rows(random_results)

# Prepare actual data per locality
emergeDistribution_actual <- data %>%
  count(Locality, emergeCount) %>%
  group_by(Locality) %>%
  mutate(
    proportion = n / sum(n),
    se = sqrt((proportion * (1 - proportion)) / sum(n)),
    ymin = proportion - se,
    ymax = proportion + se,
    type = "Actual"
  )

# Combine Both
plot_data <- bind_rows(
  emergeDistribution_actual,
  emergeDistributionRandom_all
) %>%
  mutate(label = paste0(emergeCount, "/3"),
         percent = proportion * 100,
         ymin = ymin * 100,
         ymax = ymax * 100)

# Plot facet by locality
ggplot(plot_data, aes(x = label, y = percent, fill = type)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.8), width = 0.6) +
  geom_errorbar(aes(ymin = ymin, ymax = ymax),
                position = position_dodge(width = 0.8), width = 0.2) +
  facet_wrap(~ Locality) +
  scale_y_continuous(labels = scales::percent_format(scale = 1)) +
  scale_fill_manual(values = c("Actual" = "darkseagreen4", "Randomized" = "darkseagreen2")) +
  labs(
    x = "Emergence frequency per individual",
    y = "Proportion of beetles (%)",
    fill = ""
  ) +
  theme_minimal(base_size = 18)

# Permutation test #
####################
# Is the observed consistency greater than expected by chance?

# Run permutation test per locality
perm_test_consistency <- function(df, nperm = 1000) {
  
  # observed statistic (variance = consistency)
  observed <- var(df$emergeCount)
  
  # store randomized stats
  rand_stats <- numeric(nperm)
  
  for (i in 1:nperm) {
    
    s1 <- sample(df$end_pos1)
    s2 <- sample(df$end_pos2)
    s3 <- sample(df$end_pos3)
    
    shuffled <- data.frame(s1, s2, s3)
    rand_count <- rowSums(shuffled == "Emerged")
    
    rand_stats[i] <- var(rand_count)
  }
  
  # p-value: is observed > random?
  p_value <- (sum(rand_stats >= observed) + 1) / (length(rand_stats) + 1)
  
  list(
    observed = observed,
    random_mean = mean(rand_stats),
    p_value = p_value,
    rand_dist = rand_stats
  )
}

# Run for each locality
res_dudzele <- perm_test_consistency(subset(data, Locality == "Dudzele"))
res_nieuwpoort <- perm_test_consistency(subset(data, Locality == "Nieuwpoort"))

# Print result
res_dudzele
res_nieuwpoort

# Compare between localities
res_dudzele$observed
res_nieuwpoort$observed

obs_diff <- res_nieuwpoort$observed - res_dudzele$observed

rand_diff <- res_nieuwpoort$rand_dist - res_dudzele$rand_dist

p_diff <- mean(rand_diff >= obs_diff)
p_diff

#####################################
# CAN MORPHOLOGY PREDICT BEHAVIOUR? #
#####################################
data_long$EL_s <- scale(data_long$EL)
data_long$relMRWS_s <- scale(data_long$relMRWS)

# 1. END POSITION
# Build different models
fit1 <- glmer(position ~ EL_s * relMRWS_s * Locality * Sex + (1|IID), family = binomial, data = data_long, control = glmerControl(optimizer="bobyqa", optCtrl=list(maxfun=2e5)))
fit2 <- glmer(position ~ EL_s * relMRWS_s * Locality + Sex + (1|IID), family = binomial, data = data_long, control = glmerControl(optimizer="bobyqa", optCtrl=list(maxfun=2e5)))
fit3 <- glmer(position ~ EL_s * relMRWS_s + Locality + Sex + (1|IID), family = binomial, data = data_long, control = glmerControl(optimizer="bobyqa", optCtrl=list(maxfun=2e5)))              
fit4 <- glmer(position ~ EL_s * relMRWS_s + Locality * Sex + (1|IID), family = binomial, data = data_long, control = glmerControl(optimizer="bobyqa", optCtrl=list(maxfun=2e5)))
fit5 <- glmer(position ~ EL_s + relMRWS_s * Locality * Sex + (1|IID), family = binomial, data = data_long, control = glmerControl(optimizer="bobyqa", optCtrl=list(maxfun=2e5)))
fit6 <- glmer(position ~ EL_s + relMRWS_s + Locality + Sex + (1|IID), family = binomial, data = data_long, control = glmerControl(optimizer="bobyqa", optCtrl=list(maxfun=2e5)))

AICc(fit1, fit2, fit3, fit4, fit5, fit6)
summary(fit6)

# 2. TIME
# We perform a survival analyis to check for this

# Create survival object
surv_obj <- Surv(time = data_long$time, event = data_long$position_numeric)

# Build different models
cox_model1 <- coxme(surv_obj ~ EL_s * relMRWS_s * Locality * Sex + (1|IID), data = data_long)
cox_model2 <- coxme(surv_obj ~ EL_s * relMRWS_s * Locality + Sex + (1|IID), data = data_long)
cox_model3 <- coxme(surv_obj ~ EL_s * relMRWS_s + Locality + Sex + (1|IID), data = data_long)
cox_model4 <- coxme(surv_obj ~ EL_s * relMRWS_s + Locality * Sex + (1|IID), data = data_long)
cox_model5 <- coxme(surv_obj ~ EL_s + relMRWS_s * Locality * Sex + (1|IID), data = data_long)
cox_model6 <- coxme(surv_obj ~ EL_s + relMRWS_s + Locality + Sex + (1|IID), data = data_long)

AICc(cox_model1, cox_model2, cox_model3, cox_model4, cox_model5, cox_model6)
summary(cox_model4)
emm <- emmeans(cox_model4, ~ Sex | Locality)
summary(pairs(emm), type = "response")

# Fraility models 
cox_frailty1 <- coxph(surv_obj ~ EL_s * relMRWS_s * Locality * Sex + frailty(IID), data = data_long)
cox_frailty2 <- coxph(surv_obj ~ EL_s * relMRWS_s * Locality + Sex + frailty(IID), data = data_long)
cox_frailty3 <- coxph(surv_obj ~ EL_s * relMRWS_s + Locality + Sex + frailty(IID), data = data_long)
cox_frailty4 <- coxph(surv_obj ~ EL_s * relMRWS_s + Locality * Sex + frailty(IID), data = data_long)
cox_frailty5 <- coxph(surv_obj ~ EL_s + relMRWS_s * Locality * Sex + frailty(IID), data = data_long)
cox_frailty6 <- coxph(surv_obj ~ EL_s + relMRWS_s + Locality + Sex + frailty(IID), data = data_long)

AICc(cox_frailty1, cox_frailty2, cox_frailty3, cox_frailty4, cox_frailty5, cox_frailty6)
summary(cox_frailty1)

# Visulisation
# Plot 1
fit_km <- survfit(surv_obj ~ Locality + Sex, data = data_long)
ggsurvplot(fit_km,
           data = data_long,
           conf.int = TRUE,
           pval = FALSE,
           legend.title = "Group",
           legend.labs = c("Dudzele F", "Dudzele M", "Nieuwpoort F", "Nieuwpoort M"),
           xlab = "Time (s)",
           ylab = "Probability of not emerging",
           ggtheme = theme_minimal(base_size = 16))

# Plot 2
emm_df <- as.data.frame(summary(emm))
names(emm_df)
emm_df$hazard <- exp(emm_df$emmean)
emm_df$lower <- exp(emm_df$asymp.LCL)
emm_df$upper <- exp(emm_df$asymp.UCL)

ggplot(emm_df, aes(x = Sex, y = hazard, fill = Locality)) +
  geom_col(position = position_dodge(width = 0.6), width = 0.5) +
  geom_errorbar(aes(ymin = lower, ymax = upper),
                position = position_dodge(width = 0.6), width = 0.2) +
  labs(y = "Hazard ratio (emergence speed)") +
  theme_minimal(base_size = 16)
