#install.packages("lme4") #### installs the multilevel package - only need to do this once
#install.packages("lmerTest") #### installs p values for the multilevel package - only need to do this once
#install.packages("emmeans")     ### estimated marginal means and p values
#install.packages("report")
#install.packages("survey")
#install.packages("lsmeans")
#install.packages("effects")

library(lme4)
library(lmerTest)
library(emmeans)
library(report)
library(dplyr)
library(survey)
library(effects)

options(scipen = 999) 
emm_options(pbkrtest.limit = 16896)
emm_options(lmerTest.limit = 16896)

###################### load data

EEGData<- read.csv("/Users/dhewitt/Data/pps/Exports/ERD/PPSERDDataLong_Grouped_noav_withratings_1904.csv") 
View(EEGData)
attach(EEGData)

EEGData$Condition<-factor(EEGData$Block,
                          levels = c(1,2),
                          labels = c("Conditioning", "Extinction"))

EEGData$Cue<-factor(EEGData$Cue,
                    levels = c(0,1),
                    labels = c("Neutral","Pain"))

EEGData$ElectrodeGroup<-factor(EEGData$Grouping2,
                               levels = c(1,3,4,5),
                               labels = c("Frontal", "Central","Parietal","Occipital")) #averaging over both levels of pain side
EEGData <- na.omit(EEGData)

EEGData$z_score <- (EEGData$EEGPowerChange - mean(EEGData$EEGPowerChange, na.rm = TRUE)) / sd(EEGData$EEGPowerChange, na.rm = TRUE)
EEGData <- EEGData[abs(EEGData$z_score) < 3, ]

###################### firstly looking at RQ1 - cues vs. condition
# separating into frequency bands

filtered_data_theta <- EEGData %>% filter(FreqBand == 4 ) 
filtered_data_alpha <- EEGData %>% filter(FreqBand == 8 )
filtered_data_beta <- EEGData %>% filter(FreqBand == 16 )

# ------------- Alpha -------------

# Model comparison
current_model <- lmer(EEGPowerChange ~ as.factor(Cue) * as.factor(Condition) + (1|ID/Rep), REML = FALSE, data = filtered_data_alpha)
current_model_timebin <- lmer(EEGPowerChange ~ as.factor(Cue) * as.factor(Condition) + Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_alpha)
current_model_timebin_int <- lmer(EEGPowerChange ~ as.factor(Cue) * as.factor(Condition) * Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_alpha)
AIC(current_model, current_model_timebin, current_model_timebin_int)
BIC(current_model, current_model_timebin, current_model_timebin_int)

electrodes <- unique(filtered_data_alpha$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_alpha %>% filter(ElectrodeGroup == electrode)

  # Fit model with Timebin and interaction
  current_model_timebin_int <- lmer(EEGPowerChange ~ as.factor(Cue) * as.factor(Condition) * Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode, "_WithTimebinInteraction")]] <- summary(current_model_timebin_int)
}

model_summaries #for all

# Create an empty data frame to store coefficients (except the intercept) for multiple comparison correction
coefficients_table1 <- data.frame()
for (key in names(model_summaries)) {
  if (grepl("_WithTimebinInteraction", key)) {
    model_coefficients <- as.data.frame(model_summaries[[key]]$coefficients[-1, ])
    model_coefficients$model <- key
    coefficients_table1 <- rbind(coefficients_table1, model_coefficients)
  }
}
coefficients_table1$Test <- "RQ1AlphaComplex"

# ----- Taking central and parietal regions due to significance in interaction model
alpha_central <- EEGData %>% filter(FreqBand == 8 & ElectrodeGroup == "Central")
alpha_parietal <- EEGData %>% filter(FreqBand == 8 & ElectrodeGroup == "Parietal")
alpha_frontal <- EEGData %>% filter(FreqBand == 8 & ElectrodeGroup == "Frontal")

# Estimate marginal means - central

current_model_ac <- lmer(EEGPowerChange~ Cue * Condition * Timebin + (1|ID/Rep), REML = FALSE, data = alpha_central)
alpha_central$predictedvals <- predict(current_model_ac)
current_model_ap <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) * Timebin + (1|ID/Rep), REML = FALSE, data = alpha_parietal)
alpha_parietal$predictedvals <- predict(current_model_ap)
current_model_af <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) * Timebin + (1|ID/Rep), REML = FALSE, data = alpha_frontal)
alpha_frontal$predictedvals <- predict(current_model_af)
adjustedalphadata <- rbind(alpha_frontal, alpha_central, alpha_parietal)

emmeans(current_model_ac, list(pairwise ~ Cue), adjust = "sidak")
emmeans(current_model_ac, pairwise~Cue | Condition) #if there was an interaction your code would be this

mylist<- list(Timebin = seq(1, 3, by = 1))
emmeans(current_model_ac, pairwise~Cue | Timebin / Condition, at = mylist)
emmeans(current_model_ac, pairwise~Cue | Timebin, at = mylist, adjust = "sidak")
emmip(current_model_ac, Condition:Cue ~ Timebin, cov.reduce = range)

###### Estimate marginal means - parietal
emmeans(current_model_ap, list(pairwise ~ Cue), adjust = "sidak")
emmeans(current_model_ap, list(pairwise ~ Condition), adjust = "sidak")
emmeans(current_model_ap, pairwise ~ Timebin, at = mylist, adjust = "sidak")
emmeans(current_model_ap, pairwise~Cue | Timebin, at = mylist)
emmeans(current_model_ap, pairwise~Cue | Condition) #if there was an interaction your code would be this
emmeans(current_model_ap, pairwise~Cue | Timebin / Condition) #3 way

###### Estimate marginal means - frontal

emmeans(current_model_af, list(pairwise ~ Cue), adjust = "sidak")
emmeans(current_model_af, list(pairwise ~ Condition), adjust = "sidak")
emmeans(current_model_af, pairwise~Cue | Timebin) #if there was an interaction your code would be this
emmeans(current_model_af, pairwise~Cue | Condition) #if there was an interaction your code would be this
emmeans(current_model_af, pairwise~Cue | Timebin / Condition) #3 way
emmeans(current_model_af, pairwise~Cue | Condition / Timebin) #3 way

### for more than 3 timebins
(mylist <- list(
  Timebin = seq(0, 7, by = 1),
  Cue = c("Neutral","Pain")
))
emmip(current_model_ap, Cue ~ Timebin, at = mylist, CIs = TRUE)

# ------------- Theta -------------
current_model <- lmer(EEGPowerChange ~ as.factor(Cue) * as.factor(Condition) + (1|ID/Rep), REML = FALSE, data = filtered_data_theta)
current_model_timebin <- lmer(EEGPowerChange ~ as.factor(Cue) * as.factor(Condition) + Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_theta)
current_model_timebin_int <- lmer(EEGPowerChange ~ as.factor(Cue) * as.factor(Condition) * Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_theta)
AIC(current_model, current_model_timebin, current_model_timebin_int)
BIC(current_model, current_model_timebin, current_model_timebin_int)

electrodes <- unique(filtered_data_theta$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
  
   # Fit model with Timebin and interaction
  current_model_timebin_int <- lmer(EEGPowerChange ~ as.factor(Cue) * as.factor(Condition) * Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode, "_WithTimebinInteraction")]] <- summary(current_model_timebin_int)
}

model_summaries #for all

# Create an empty data frame to store coefficients (except the intercept) for multiple comparison correction
coefficients_table2 <- data.frame()
for (key in names(model_summaries)) {
  if (grepl("_WithTimebinInteraction", key)) {
    model_coefficients <- as.data.frame(model_summaries[[key]]$coefficients[-1, ])
    model_coefficients$model <- key
    coefficients_table2 <- rbind(coefficients_table2, model_coefficients)
  }
}
coefficients_table2$Test <- "RQ1ThetaComplex"

#=== getting emmeans

theta_central <- EEGData %>% filter(FreqBand == 4 & ElectrodeGroup == "Central")
theta_frontal <- EEGData %>% filter(FreqBand == 4 & ElectrodeGroup == "Frontal")
theta_parietal <- EEGData %>% filter(FreqBand == 4 & ElectrodeGroup == "Parietal")
current_model_frontal <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) * Timebin + (1|ID/Rep), REML = FALSE, data = theta_frontal)
current_model_central <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) * Timebin + (1|ID/Rep), REML = FALSE, data = theta_central)
current_model_parietal <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) * Timebin + (1|ID/Rep), REML = FALSE, data = theta_parietal)

theta_central$predictedvals <- predict(current_model_central)
theta_frontal$predictedvals <- predict(current_model_frontal)
theta_parietal$predictedvals <- predict(current_model_parietal)
adjustedthetadata <- rbind(theta_frontal, theta_central, theta_parietal)

emmeans(current_model_frontal, list(pairwise ~ Condition), adjust = "sidak")
emmeans(current_model_central, list(pairwise ~ Condition), adjust = "sidak")
emmeans(current_model_parietal, list(pairwise ~ Condition), adjust = "sidak")
emmeans(current_model_parietal, pairwise ~ Condition | Timebin, at = mylist, adjust = "sidak")
emmeans(current_model_central, pairwise ~ Condition | Timebin, at = mylist, adjust = "sidak")

# ------------- Beta -------------
current_model <- lmer(EEGPowerChange ~ as.factor(Cue) * as.factor(Condition) + (1|ID/Rep), REML = FALSE, data = filtered_data_beta)
current_model_timebin <- lmer(EEGPowerChange ~ as.factor(Cue) * as.factor(Condition) + Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_beta)
current_model_timebin_int <- lmer(EEGPowerChange ~ as.factor(Cue) * as.factor(Condition) * Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_beta)
AIC(current_model, current_model_timebin, current_model_timebin_int)
BIC(current_model, current_model_timebin, current_model_timebin_int)

# Fit models for beta data
electrodes <- unique(filtered_data_beta$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_beta %>% filter(ElectrodeGroup == electrode)
  
  # Fit model with Timebin and interaction
  current_model_timebin_int <- lmer(EEGPowerChange ~ as.factor(Cue) * as.factor(Condition) * Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode, "_WithTimebinInteraction")]] <- summary(current_model_timebin_int)
}

model_summaries #for all

# Create an empty data frame to store coefficients (except the intercept) for multiple comparison correction
coefficients_table3 <- data.frame()
for (key in names(model_summaries)) {
  if (grepl("_WithTimebinInteraction", key)) {
    model_coefficients <- as.data.frame(model_summaries[[key]]$coefficients[-1, ])
    model_coefficients$model <- key
    coefficients_table3 <- rbind(coefficients_table3, model_coefficients)
  }
}
coefficients_table3$Test <- "RQ1BetaComplex"

#=== getting emmeans

beta_central <- EEGData %>% filter(FreqBand == 16 & ElectrodeGroup == "Central")
beta_parietal <- EEGData %>% filter(FreqBand == 16 & ElectrodeGroup == "Parietal")
current_model_parietal <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) * Timebin + (1|ID/Rep), REML = FALSE, data = beta_parietal)
current_model_central <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) * Timebin + (1|ID/Rep), REML = FALSE, data = beta_central)

beta_central$predictedvals <- predict(current_model_central)
beta_parietal$predictedvals <- predict(current_model_parietal)
adjustedbetadata <- rbind(beta_central, beta_parietal)

emmeans(current_model_central, pairwise~Cue | Condition) #if there was an interaction your code would be this

emmeans(current_model_parietal, list(pairwise ~ Cue), adjust = "sidak")
emmeans(current_model_parietal, list(pairwise ~ Condition), adjust = "sidak")
emmeans(current_model_parietal, pairwise~Cue | Condition) #if there was an interaction your code would be this

emmeans(current_model_parietal, pairwise~Cue | Timebin, at = mylist, adjust = "sidak")
emmeans(current_model_central, pairwise~Cue | Timebin, at = mylist, adjust = "sidak")

emmip(current_model_central, Condition:Cue ~ Timebin, cov.reduce = range)
emmip(current_model_parietal, Cue ~ Timebin, cov.reduce = range)

emmeans(current_model_central, pairwise~Cue | Timebin, at = mylist, adjust = "sidak")
emmeans(current_model_central, pairwise~Cue | Condition / Timebin, at = mylist, adjust = "sidak")

### splitting up the timebin effect to interpret diffs here
emmeans(current_model_central, list(pairwise ~ Timebin), adjust = "sidak")
emmeans(current_model_central, pairwise~Cue | Timebin) #if there was an interaction your code would be this
emmeans(current_model_central, pairwise~Cue | Timebin / Condition) #3 way
emmeans(current_model_parietal, pairwise~Cue | Timebin) #if there was an interaction your code would be this

current_model_parietal <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) * Timebin + (1|ID/Rep), REML = FALSE, data = beta_parietal)
current_model_central <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) * Timebin + (1|ID/Rep), REML = FALSE, data = beta_central)
emmeans(current_model_central, pairwise~Cue | Timebin / Condition) #3 way
emmeans(current_model_central, list(pairwise ~ Cue), adjust = "sidak")
emmeans(current_model_parietal, list(pairwise ~ Cue), adjust = "sidak")

# ------------ Exporting to CSVs -------------
#------- saving

adjustedRQ1data <- rbind(adjustedalphadata, adjustedbetadata, adjustedthetadata)
file_path <- "/Users/dhewitt/Data/pps/Exports/ERD/adjustedRQ1data_171024.csv"
write.csv(adjustedRQ1data, file = file_path, row.names = TRUE)

# ------------- RQ2 -------------

EEGData<- read.csv("/Users/dhewitt/Data/pps/Exports/ERD/PPSERDDataLong_Grouped_noav_withratings_1904.csv")
View(EEGData)
attach(EEGData)

EEGData <- EEGData %>% filter(Block == 2 & congruency != 0) ##1 now dropped from file

EEGData$CueSide<-factor(EEGData$Side,
                        levels = c(0,1,2),
                        labels = c("middle", "left","right"))

EEGData$TonicSide<-factor(EEGData$congruency,
                          levels = c(1,2),
                          labels = c("incongruent","congruent"))

EEGData$ElectrodeGroup<-factor(EEGData$Grouping2,
                               levels = c(1,3,4,5),
                               labels = c("Frontal", "Central","Parietal","Occipital")) #averaging over both levels of pain side
EEGData <- na.omit(EEGData)

EEGData$z_score <- (EEGData$EEGPowerChange - mean(EEGData$EEGPowerChange, na.rm = TRUE)) / sd(EEGData$EEGPowerChange, na.rm = TRUE)
EEGData <- EEGData[abs(EEGData$z_score) < 3, ]

###################### separating into frequency bands

filtered_data_theta <- EEGData %>% filter(FreqBand == 4)
filtered_data_alpha <- EEGData %>% filter(FreqBand == 8)
filtered_data_beta <- EEGData %>% filter(FreqBand == 16)

# ------------- Alpha - RQ2 -------------
#Model comparison
current_model <- lmer(EEGPowerChange ~ as.factor(TonicSide) + (1|ID/Rep), REML = FALSE, data = filtered_data_alpha)
current_model_timebin <- lmer(EEGPowerChange ~ as.factor(TonicSide) + Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_alpha)
current_model_timebin_int <- lmer(EEGPowerChange ~ as.factor(TonicSide) * Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_alpha)
AIC(current_model, current_model_timebin, current_model_timebin_int)
BIC(current_model, current_model_timebin, current_model_timebin_int)

# Fit models for alpha data with different LME model
electrodes <- unique(filtered_data_alpha$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_alpha %>% filter(ElectrodeGroup == electrode)

  # Fit model with Timebin
  current_model_timebin <- lmer(EEGPowerChange ~ as.factor(TonicSide) + Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode, "_WithTimebinOnly")]] <- summary(current_model_timebin)
  
}

model_summaries #for all

# Create an empty data frame to store coefficients (except the intercept) for multiple comparison correction
coefficients_table4 <- data.frame()
for (key in names(model_summaries)) {
  if (grepl("_WithTimebinOnly", key)) {
    model_coefficients <- as.data.frame(model_summaries[[key]]$coefficients[-1, ])
    model_coefficients$model <- key
    coefficients_table4 <- rbind(coefficients_table4, model_coefficients)
  }
}
coefficients_table4$Test <- "RQ2AlphaModerate"

# ------------- Theta - RQ2 -------------
#Model comparison
current_model <- lmer(EEGPowerChange ~ as.factor(TonicSide) + (1|ID/Rep), REML = FALSE, data = filtered_data_theta)
current_model_timebin <- lmer(EEGPowerChange ~ as.factor(TonicSide) + Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_theta)
current_model_timebin_int <- lmer(EEGPowerChange ~ as.factor(TonicSide) * Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_theta)
AIC(current_model, current_model_timebin, current_model_timebin_int)
BIC(current_model, current_model_timebin, current_model_timebin_int)

# Fit models for theta data
electrodes <- unique(filtered_data_theta$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
  
  # Fit model with Timebin
  current_model_timebin <- lmer(EEGPowerChange ~ as.factor(TonicSide) + Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode, "_WithTimebinOnly")]] <- summary(current_model_timebin)

}

model_summaries #for all

# Create an empty data frame to store coefficients (except the intercept) for multiple comparison correction
coefficients_table5 <- data.frame()
for (key in names(model_summaries)) {
  if (grepl("_WithTimebinOnly", key)) {
    model_coefficients <- as.data.frame(model_summaries[[key]]$coefficients[-1, ])
    model_coefficients$model <- key
    coefficients_table5 <- rbind(coefficients_table5, model_coefficients)
  }
}
coefficients_table5$Test <- "RQ2ThetaModerate"

#### central

theta_frontal <- EEGData %>% filter(FreqBand == 4 & ElectrodeGroup == "Frontal")
current_model_theta <- lmer(EEGPowerChange~ TonicSide + Timebin + (1|ID/Rep), REML = FALSE, data = theta_frontal)
summary(current_model_theta)

theta_frontal$predictedvals <- predict(current_model_theta)

emmeans(current_model_theta, list(pairwise ~ TonicSide), adjust = "sidak")

# ------------- Beta - RQ2 -------------
#Model comparison
current_model <- lmer(EEGPowerChange ~ as.factor(TonicSide) + (1|ID/Rep), REML = FALSE, data = filtered_data_beta)
current_model_timebin <- lmer(EEGPowerChange ~ as.factor(TonicSide) + Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_beta)
current_model_timebin_int <- lmer(EEGPowerChange ~ as.factor(TonicSide) * Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_beta)
AIC(current_model, current_model_timebin, current_model_timebin_int)
BIC(current_model, current_model_timebin, current_model_timebin_int)

# Fit models for beta data
electrodes <- unique(filtered_data_beta$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_beta %>% filter(ElectrodeGroup == electrode)
 
  # Fit model with Timebin
  current_model_timebin <- lmer(EEGPowerChange ~ as.factor(TonicSide) + Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode, "_WithTimebinOnly")]] <- summary(current_model_timebin)
}

model_summaries #for all

# Create an empty data frame to store coefficients (except the intercept) for multiple comparison correction
coefficients_table6 <- data.frame()
for (key in names(model_summaries)) {
  if (grepl("_WithTimebinOnly", key)) {
    model_coefficients <- as.data.frame(model_summaries[[key]]$coefficients)
    model_coefficients <- model_coefficients[-1, ]
    model_coefficients$model <- key
    coefficients_table6 <- rbind(coefficients_table6, model_coefficients)
  }
}
coefficients_table6$Test <- "RQ2BetaModerate"

# ------------ Exporting to CSVs -------------
# Doing multiple comparison corrections --- make sure to have run the most recent model for each first.

alpha_merged_coefficients <- rbind(coefficients_table1) ## add alpha coef table 4 if anything sig
alpha_merged_coefficients$FDR_adjusted_pvalue <- p.adjust(alpha_merged_coefficients$`Pr(>|t|)`, method = "fdr")

beta_merged_coefficients <- rbind(coefficients_table3) ## add beta coef table 6 if anything sig
beta_merged_coefficients$FDR_adjusted_pvalue <- p.adjust(beta_merged_coefficients$`Pr(>|t|)`, method = "fdr")

theta_merged_coefficients <- rbind(coefficients_table2, coefficients_table5)
theta_merged_coefficients$FDR_adjusted_pvalue <- p.adjust(theta_merged_coefficients$`Pr(>|t|)`, method = "fdr")

# ------------ Looking at hemispheric asymmetries

EEGData<- read.csv("/Users/dhewitt/Data/pps/Exports/ERD/PPSERDDataLong_Grouped_noav_withratings_elhem_180324.csv")
View(EEGData)
attach(EEGData)

EEGData <- EEGData %>% filter(Block == 2 & congruency != 0) ##1 now dropped from file

EEGData$CueSide<-factor(EEGData$Side,
                        levels = c(0,1,2),
                        labels = c("middle", "left","right"))

EEGData$TonicSide<-factor(EEGData$congruency,
                          levels = c(1,2),
                          labels = c("incongruent","congruent"))

EEGData$ElectrodeGroup<-factor(EEGData$Grouping1,
                               levels = c(1,3,4,5),
                               labels = c("Frontal", "Central","Parietal","Occipital")) #averaging over both levels of pain side

EEGData$ElHem<-factor(EEGData$ElHem,
                      levels = c(1,-1),
                      labels = c("Contra","Ipsi")) #averaging over both levels of pain side

EEGData <- na.omit(EEGData)

EEGData$z_score <- (EEGData$EEGPowerChange - mean(EEGData$EEGPowerChange, na.rm = TRUE)) / sd(EEGData$EEGPowerChange, na.rm = TRUE)
EEGData <- EEGData[abs(EEGData$z_score) < 3, ]

###################### separating into frequency bands

filtered_data_theta <- EEGData %>% filter(FreqBand == 4)
filtered_data_alpha <- EEGData %>% filter(FreqBand == 8)
filtered_data_beta <- EEGData %>% filter(FreqBand == 16)

# ------------- Alpha - RQ2 Hemi -------------
#Model comparison - better fit without hemisphere
current_model_timebin <- lmer(EEGPowerChange ~ as.factor(TonicSide) + Timebin + ElHem + (1|ID/Rep), REML = FALSE, data = filtered_data_alpha)
current_model_timebin_hem <- lmer(EEGPowerChange ~ as.factor(TonicSide) + Timebin * ElHem + (1|ID/Rep), REML = FALSE, data = filtered_data_alpha)
AIC(current_model_timebin, current_model_timebin_hem)
BIC(current_model_timebin, current_model_timebin_hem)

# ------------- Theta - RQ2 Hemi -------------
#Model comparison - better fit without hemisphere
current_model_timebin <- lmer(EEGPowerChange ~ as.factor(TonicSide) + Timebin + ElHem + (1|ID/Rep), REML = FALSE, data = filtered_data_theta)
current_model_timebin_hem <- lmer(EEGPowerChange ~ as.factor(TonicSide) + Timebin * ElHem + (1|ID/Rep), REML = FALSE, data = filtered_data_theta)
AIC(current_model_timebin, current_model_timebin_hem)
BIC(current_model_timebin, current_model_timebin_hem)

# ------------- Beta - RQ2 Hemi -------------
#Model comparison - better fit without hemisphere
current_model_timebin <- lmer(EEGPowerChange ~ as.factor(TonicSide) + Timebin + ElHem + (1|ID/Rep), REML = FALSE, data = filtered_data_beta)
current_model_timebin_hem <- lmer(EEGPowerChange ~ as.factor(TonicSide) + Timebin * ElHem + (1|ID/Rep), REML = FALSE, data = filtered_data_beta)
AIC(current_model_timebin, current_model_timebin_hem)
BIC(current_model_timebin, current_model_timebin_hem)

# ------------ Exporting to CSVs -------------
# Doing multiple comparison corrections --- make sure to have run the most recent model for each first.

alpha_merged_coefficients <- rbind(coefficients_table1) ## add alpha coef table 4 if anything sig
alpha_merged_coefficients$FDR_adjusted_pvalue <- p.adjust(alpha_merged_coefficients$`Pr(>|t|)`, method = "fdr")

beta_merged_coefficients <- rbind(coefficients_table3) ## add beta coef table 6 if anything sig
beta_merged_coefficients$FDR_adjusted_pvalue <- p.adjust(beta_merged_coefficients$`Pr(>|t|)`, method = "fdr")

theta_merged_coefficients <- rbind(coefficients_table2, coefficients_table5)
theta_merged_coefficients$FDR_adjusted_pvalue <- p.adjust(theta_merged_coefficients$`Pr(>|t|)`, method = "fdr")

#------- saving

adjustedRQ2data <- theta_central
file_path <- "/Users/dhewitt/Data/pps/Exports/ERD/adjustedRQ2data_171024.csv"
write.csv(adjustedRQ2data, file = file_path, row.names = TRUE)

adjustedRQ2hemdata <- rbind(alpha_parietal, beta_parietal)
file_path <- "/Users/dhewitt/Data/pps/Exports/ERD/adjustedRQ2hemdata_171024.csv"
write.csv(adjustedRQ2hemdata, file = file_path, row.names = TRUE)

all_merged_coefficients <- rbind(alpha_merged_coefficients, beta_merged_coefficients, theta_merged_coefficients)
file_path <- "/Users/dhewitt/Data/pps/Exports/ERD/LME_coefficients_171024.csv"
write.csv(all_merged_coefficients, file = file_path, row.names = TRUE)

all_merged_hems <- rbind(coefficients_hem_1, coefficients_hem_2)
file_path <- "/Users/dhewitt/Data/pps/Exports/ERD/LME_coefficients_hems_171024.csv"
write.csv(all_merged_hems, file = file_path, row.names = TRUE)

# --------------- RQ2 - Covariates 
# ------------- RQ2 Covs Alpha -------------

## Firstly, starting with a covariate only model

covariates <- c("STAI_Trait_Score", "Age", "MeanInt", "MeanUn", "PupilDiameter", "GazeDirection")

model_summaries <- list()

for (covariate in covariates) {
  current_model_summaries <- list()
  for (electrode in unique(filtered_data_alpha$ElectrodeGroup)) {
    filtered_data_electrode <- filtered_data_alpha %>% filter(ElectrodeGroup == electrode)
    formula <- paste("EEGPowerChange ~", covariate, "+ (1 | ID/Rep)")
    current_model <- lmer(formula, REML = FALSE, data = filtered_data_electrode)
    current_model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
  }
  model_summaries[[covariate]] <- current_model_summaries
}

# Doing over all alpha
for (covariate in covariates) {
  current_model_summaries <- list()
    formula <- paste("EEGPowerChange ~", covariate, "+ (1 | ID/Rep)")
    current_model <- lmer(formula, REML = FALSE, data = filtered_data_alpha)
    current_model_summaries <- summary(current_model)
  model_summaries[[covariate]] <- current_model_summaries
}

model_summaries

## Now adding in the congruency condition for ones that were significant alone

covariates <- c("MeanInt", "MeanUn")

model_summaries <- list()

for (covariate in covariates) {
  current_model_summaries <- list()
  for (electrode in unique(filtered_data_alpha$ElectrodeGroup)) {
    filtered_data_electrode <- filtered_data_alpha %>% filter(ElectrodeGroup == electrode)
    formula <- paste("EEGPowerChange ~ as.factor(TonicSide) +", covariate, "+ (1 | ID/Rep)")
    current_model <- lmer(formula, REML = FALSE, data = filtered_data_electrode)
    current_model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
  }
  model_summaries[[covariate]] <- current_model_summaries
}

model_summaries

## Next, the interaction

model_summaries <- list()
alpha_cov_coefficients_table <- data.frame()

for (covariate in covariates) {
  current_model_summaries <- list()
  for (electrode in unique(filtered_data_alpha$ElectrodeGroup)) {
    if (electrode == "Occipital") {
      next
    }
    filtered_data_electrode <- filtered_data_alpha %>% filter(ElectrodeGroup == electrode)
    formula <- paste("EEGPowerChange ~ as.factor(TonicSide) *", covariate, "+ (1 | ID/Rep)")
    current_model <- lmer(formula, REML = FALSE, data = filtered_data_electrode)
    current_model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
    
    #saving to a table
    coefficients <- as.data.frame(coef(summary(current_model)))[-1, ]
    coefficients$ElectrodeGroup <- paste0("ElectrodeGroup_", electrode)
    coefficients$Covariate <- covariate
    alpha_cov_coefficients_table <- rbind(alpha_cov_coefficients_table, coefficients)
    
  }
  model_summaries[[covariate]] <- current_model_summaries
}
alpha_cov_coefficients_table$Test <- "RQ2AlphaModerate"

model_summaries

## Finally, adding in timebin (exploratory)

model_summaries <- list()

for (covariate in covariates) {
  current_model_summaries <- list()
  for (electrode in unique(filtered_data_alpha$ElectrodeGroup)) {
    filtered_data_electrode <- filtered_data_alpha %>% filter(ElectrodeGroup == electrode)
    formula <- paste("EEGPowerChange ~ as.factor(TonicSide) *", covariate, "+ Timebin + (1 | ID/Rep)")
    current_model <- lmer(formula, REML = FALSE, data = filtered_data_electrode)
    current_model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
  }
  model_summaries[[covariate]] <- current_model_summaries
}

model_summaries

#### Getting estimated means and plotting

alpha_frontal <- EEGData %>% filter(FreqBand == 8 & ElectrodeGroup == "Frontal")
alpha_central <- EEGData %>% filter(FreqBand == 8 & ElectrodeGroup == "Central")
alpha_parietal <- EEGData %>% filter(FreqBand == 8 & ElectrodeGroup == "Parietal")

#---- frontal

#plotting effects - have to get rid of the 'asfactor' but this has already been determined above anyway
cov_alpha_frontal1 <- lmer(EEGPowerChange~ TonicSide * MeanUn + (1|ID/Rep), REML = FALSE, data = alpha_frontal)
alpha_frontal$predictedvals_unp <- predict(cov_alpha_frontal1)

summary(cov_alpha_frontal1)
plot(effect("TonicSide", cov_alpha_frontal1))
plot(effect("MeanUn", cov_alpha_frontal1))
plot(effect("TonicSide:MeanUn", cov_alpha_frontal1))

emmip(cov_alpha_frontal1, TonicSide ~ MeanUn, cov.reduce = range)
ratinglist<- list(MeanUn = seq(1.5, 6.5, by = 1))
emmeans(cov_alpha_frontal1, pairwise~TonicSide|MeanUn, at = ratinglist)

cov_alpha_frontal2 <- lmer(EEGPowerChange~ TonicSide * PupilDiameter + (1|ID/Rep), REML = FALSE, data = alpha_frontal)
alpha_frontal$predictedvals_pupilD <- predict(cov_alpha_frontal2)
summary(cov_alpha_frontal2)
plot(effect("PupilDiameter", cov_alpha_frontal2))
mylist<- list(PupilDiameter = seq(-1, 1, by = 0.5))
emmeans(cov_alpha_frontal, pairwise~PupilDiameter, at = mylist, adjust = "sidak")

cov_alpha_frontal3 <- lmer(EEGPowerChange~ TonicSide * MeanInt + (1|ID/Rep), REML = FALSE, data = alpha_frontal)
alpha_frontal$predictedvals_int <- predict(cov_alpha_frontal3)
summary(cov_alpha_frontal3)
ratinglist<- list(MeanInt = seq(1.5, 6.5, by = 1))
plot(effect("MeanInt", cov_alpha_frontal3))
plot(effect("TonicSide:MeanInt", cov_alpha_frontal3))
emmeans(cov_alpha_frontal3, pairwise~TonicSide|MeanInt, at = ratinglist)

#---- central

#plotting effects - have to get rid of the 'asfactor' but this has already been determined above anyway
cov_alpha_central1 <- lmer(EEGPowerChange~ TonicSide * MeanUn + (1|ID/Rep), REML = FALSE, data = alpha_central)
alpha_central$predictedvals_unp <- predict(cov_alpha_central1)
summary(cov_alpha_central1)
plot(effect("TonicSide", cov_alpha_central1))
plot(effect("MeanUn", cov_alpha_central1))
plot(effect("TonicSide:MeanUn", cov_alpha_central1))

emmip(cov_alpha_central1, TonicSide ~ MeanUn, cov.reduce = range)
ratinglist<- list(MeanUn = seq(1.5, 6.5, by = 1))
emmeans(cov_alpha_central1, pairwise~TonicSide|MeanUn, at = ratinglist)

cov_alpha_central2 <- lmer(EEGPowerChange~ TonicSide * MeanInt + (1|ID/Rep), REML = FALSE, data = alpha_central)
alpha_central$predictedvals_int <- predict(cov_alpha_central2)
summary(cov_alpha_central2)
plot(effect("MeanInt", cov_alpha_central2))
plot(effect("TonicSide:MeanInt", cov_alpha_central2))

alpha_central$predictedvals_pupilD <- 'na'
alpha_central$predictedvals_int <- 'na'

#---- parietal

#plotting effects - have to get rid of the 'asfactor' but this has already been determined above anyway
cov_alpha_parietal1 <- lmer(EEGPowerChange~ TonicSide * PupilDiameter + (1|ID/Rep), REML = FALSE, data = alpha_parietal)
alpha_parietal$predictedvals_unp <- 'na'
alpha_parietal$predictedvals_pupilD <- predict(cov_alpha_parietal1)
plot(effect("TonicSide", cov_alpha_parietal1))
plot(effect("TonicSide:PupilDiameter", cov_alpha_parietal1))

cov_alpha_parietal2 <- lmer(EEGPowerChange~ TonicSide * MeanInt + (1|ID/Rep), REML = FALSE, data = alpha_parietal)
alpha_parietal$predictedvals_int <- predict(cov_alpha_parietal2)

adjustedRQ2alphadata <- rbind(alpha_frontal, alpha_central, alpha_parietal)

# ------------- RQ2 Covs Theta -------------

## Firstly, starting with a covariate only model

covariates <- c("STAI_Trait_Score", "Age", "MeanInt", "MeanUn", "PupilDiameter", "GazeDirection")

model_summaries <- list()

for (covariate in covariates) {
  current_model_summaries <- list()
  for (electrode in unique(filtered_data_theta$ElectrodeGroup)) {
    filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
    formula <- paste("EEGPowerChange ~", covariate, "+ (1 | ID/Rep)")
    formula <- paste("EEGPowerChange ~", covariate, "+ (1 | ID/Rep)")
    current_model <- lmer(formula, REML = FALSE, data = filtered_data_electrode)
    current_model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
  }
  model_summaries[[covariate]] <- current_model_summaries
}

model_summaries

# Doing over all alpha
for (covariate in covariates) {
  current_model_summaries <- list()
  formula <- paste("EEGPowerChange ~", covariate, "+ (1 | ID/Rep)")
  current_model <- lmer(formula, REML = FALSE, data = filtered_data_theta)
  current_model_summaries <- summary(current_model)
  model_summaries[[covariate]] <- current_model_summaries
}

model_summaries

## Now adding in the congruency condition

covariates <- c("PupilDiameter")

model_summaries <- list()

for (covariate in covariates) {
  current_model_summaries <- list()
  for (electrode in unique(filtered_data_theta$ElectrodeGroup)) {
    filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
    formula <- paste("EEGPowerChange ~ as.factor(TonicSide) +", covariate, "+ (1 | ID/Rep)")
    current_model <- lmer(formula, REML = FALSE, data = filtered_data_electrode)
    current_model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
    
    
  }
  model_summaries[[covariate]] <- current_model_summaries
}

model_summaries

## Next, the interaction

model_summaries <- list()
theta_cov_coefficients_table <- data.frame()

for (covariate in covariates) {
  current_model_summaries <- list()
  for (electrode in unique(filtered_data_theta$ElectrodeGroup)) {
    filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
    formula <- paste("EEGPowerChange ~ as.factor(TonicSide) *", covariate, "+ (1 | ID/Rep)")
    current_model <- lmer(formula, REML = FALSE, data = filtered_data_electrode)
    current_model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
    
    #saving to a table
    coefficients <- as.data.frame(coef(summary(current_model)))[-1, ]
    coefficients$ElectrodeGroup <- paste0("ElectrodeGroup_", electrode)
    coefficients$Covariate <- covariate
    theta_cov_coefficients_table <- rbind(theta_cov_coefficients_table, coefficients)
    
  }
  model_summaries[[covariate]] <- current_model_summaries
}
theta_cov_coefficients_table$Test <- "RQ2ThetaModerate"

model_summaries

## Finally, adding in timebin (exploratory)

model_summaries <- list()

for (covariate in covariates) {
  current_model_summaries <- list()
  for (electrode in unique(filtered_data_theta$ElectrodeGroup)) {
    filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
    formula <- paste("EEGPowerChange ~ as.factor(TonicSide) *", covariate, "+ Timebin + (1 | ID/Rep)")
    current_model <- lmer(formula, REML = FALSE, data = filtered_data_electrode)
    current_model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
  }
  model_summaries[[covariate]] <- current_model_summaries
}

model_summaries

# ---- plotting
theta_frontal <- EEGData %>% filter(FreqBand == 4 & ElectrodeGroup == "Frontal")
theta_parietal <- EEGData %>% filter(FreqBand == 4 & ElectrodeGroup == "Parietal")

#plotting effects - have to get rid of the 'asfactor' but this has already been determined above anyway
cov_theta_frontal <- lmer(EEGPowerChange~ TonicSide * PupilDiameter + (1|ID/Rep), REML = FALSE, data = theta_frontal)
theta_frontal$predictedvals_pupilD <- predict(cov_theta_frontal)
plot(effect("PupilDiameter", cov_theta_frontal))

#plotting effects - have to get rid of the 'asfactor' but this has already been determined above anyway
cov_theta_parietal <- lmer(EEGPowerChange~ TonicSide * PupilDiameter + (1|ID/Rep), REML = FALSE, data = theta_parietal)
theta_parietal$predictedvals_pupilD <- predict(cov_theta_parietal)
plot(effect("PupilDiameter", cov_theta_parietal))

adjustedRQ2thetadata <- rbind(theta_frontal, theta_parietal)

# ------------- RQ2 Covs Beta -------------

## Firstly, starting with a covariate only model

covariates <- c("STAI_Trait_Score", "Age", "MeanInt", "MeanUn", "PupilDiameter", "GazeDirection")

model_summaries <- list()

for (covariate in covariates) {
  current_model_summaries <- list()
  for (electrode in unique(filtered_data_beta$ElectrodeGroup)) {
    filtered_data_electrode <- filtered_data_beta %>% filter(ElectrodeGroup == electrode)
    formula <- paste("EEGPowerChange ~", covariate, "+ (1 | ID/Rep)")
    current_model <- lmer(formula, REML = FALSE, data = filtered_data_electrode)
    current_model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
  }
  model_summaries[[covariate]] <- current_model_summaries
}

model_summaries

# Doing over all alpha
for (covariate in covariates) {
  current_model_summaries <- list()
  formula <- paste("EEGPowerChange ~", covariate, "+ (1 | ID/Rep)")
  current_model <- lmer(formula, REML = FALSE, data = filtered_data_beta)
  current_model_summaries <- summary(current_model)
  model_summaries[[covariate]] <- current_model_summaries
}

model_summaries

## Now adding in the congruency condition

covariates <- c("PupilDiameter", "MeanUn")

model_summaries <- list()

for (covariate in covariates) {
  current_model_summaries <- list()
  for (electrode in unique(filtered_data_beta$ElectrodeGroup)) {
    filtered_data_electrode <- filtered_data_beta %>% filter(ElectrodeGroup == electrode)
    formula <- paste("EEGPowerChange ~ as.factor(TonicSide) +", covariate, "+ (1 | ID/Rep)")
    current_model <- lmer(formula, REML = FALSE, data = filtered_data_electrode)
    current_model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
  }
  model_summaries[[covariate]] <- current_model_summaries
}

model_summaries

## Next, the interaction

model_summaries <- list()
beta_cov_coefficients_table <- data.frame()

for (covariate in covariates) {
  current_model_summaries <- list()
  for (electrode in unique(filtered_data_beta$ElectrodeGroup)) {
    filtered_data_electrode <- filtered_data_beta %>% filter(ElectrodeGroup == electrode)
    formula <- paste("EEGPowerChange ~ as.factor(TonicSide) *", covariate, "+ (1 | ID/Rep)")
    current_model <- lmer(formula, REML = FALSE, data = filtered_data_electrode)
    current_model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
    
    #saving to a table
    coefficients <- as.data.frame(coef(summary(current_model)))[-1, ]
    coefficients$ElectrodeGroup <- paste0("ElectrodeGroup_", electrode)
    coefficients$Covariate <- covariate
    beta_cov_coefficients_table <- rbind(beta_cov_coefficients_table, coefficients)
  }
  model_summaries[[covariate]] <- current_model_summaries
}
beta_cov_coefficients_table$Test <- "RQ2BetaModerate"

model_summaries

## Finally, adding in timebin (exploratory)

model_summaries <- list()

for (covariate in covariates) {
  current_model_summaries <- list()
  for (electrode in unique(filtered_data_beta$ElectrodeGroup)) {
    filtered_data_electrode <- filtered_data_beta %>% filter(ElectrodeGroup == electrode)
    formula <- paste("EEGPowerChange ~ as.factor(TonicSide) *", covariate, "+ Timebin + (1 | ID/Rep)")
    current_model <- lmer(formula, REML = FALSE, data = filtered_data_electrode)
    current_model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
  }
  model_summaries[[covariate]] <- current_model_summaries
}

model_summaries

#### Getting estimated means and plotting

beta_occipital <- EEGData %>% filter(FreqBand == 16 & ElectrodeGroup == "Occipital")
beta_parietal <- EEGData %>% filter(FreqBand == 16 & ElectrodeGroup == "Parietal")
beta_central <- EEGData %>% filter(FreqBand == 16 & ElectrodeGroup == "Central")

cov_beta_occipital <- lmer(EEGPowerChange~ TonicSide * MeanUn + (1|ID/Rep), REML = FALSE, data = beta_occipital)
cov_beta_parietal <- lmer(EEGPowerChange~ TonicSide * MeanUn + (1|ID/Rep), REML = FALSE, data = beta_parietal)
beta_occipital$predictedvals_unp <- predict(cov_beta_occipital)
beta_parietal$predictedvals_unp <- predict(cov_beta_parietal)

summary(cov_beta_occipital)
summary(cov_beta_parietal)
emmeans(cov_beta_occipital, list(pairwise ~ TonicSide), adjust = "sidak")
emmeans(cov_beta_parietal, list(pairwise ~ TonicSide), adjust = "sidak")

beta_central$predictedvals_unp <- 'na'
beta_occipital$predictedvals_pupilD <- 'na'
adjustedRQ2betadata <- rbind(beta_central, beta_parietal, beta_occipital)

# Plotting effects

plot(effect("MeanUn", cov_beta_parietal))
plot(effect("TonicSide", cov_beta_parietal))
plot(effect("TonicSide", cov_beta_occipital))
plot(effect("TonicSide:MeanUn", cov_beta_parietal))
plot(effect("TonicSide:MeanUn", cov_beta_occipital))

plot(effect("PupilDiameter", cov_beta_occipital2))
plot(effect("PupilDiameter", cov_beta_parietal2))

emmip(cov_beta_parietal, TonicSide ~ MeanUn, cov.reduce = range)
ratinglist<- list(MeanUn = c(1.8, 4.4, 6.7)) #min, mean, max
emmeans(cov_beta_parietal, pairwise~TonicSide|MeanUn, at = ratinglist, adjust = "sidak")

emmip(cov_beta_occipital, TonicSide ~ MeanUn, cov.reduce = range)
ratinglist<- list(MeanUn = c(1.8, 4.4, 6.7)) #min, mean, max
emmeans(cov_beta_occipital, pairwise~TonicSide|MeanUn, at = ratinglist, adjust = "sidak")

# ------------- Exports -------------
# ------- saving

adjustedRQ2betadata$predictedvals_int <- 'na'
adjustedRQ2thetadata$predictedvals_int <- 'na'
adjustedRQ2thetadata$predictedvals_unp <- 'na'

adjustedRQ2covdata <- rbind(adjustedRQ2alphadata, adjustedRQ2betadata, adjustedRQ2thetadata)
file_path <- "/Users/dhewitt/Data/pps/Exports/ERD/adjustedRQ2covdata_070524.csv"
write.csv(adjustedRQ2data, file = file_path, row.names = TRUE)

# ---- Exporting coefficient tables

alpha_cov_coefficients_table$FDR_adjusted_pvalue <- p.adjust(alpha_cov_coefficients_table$`Pr(>|t|)`, method = "fdr")
theta_cov_coefficients_table$FDR_adjusted_pvalue <- p.adjust(theta_cov_coefficients_table$`Pr(>|t|)`, method = "fdr")
beta_cov_coefficients_table$FDR_adjusted_pvalue <- p.adjust(beta_cov_coefficients_table$`Pr(>|t|)`, method = "fdr")

all_merged_cov_coefficients <- rbind(alpha_cov_coefficients_table, theta_cov_coefficients_table, beta_cov_coefficients_table)
file_path <- "/Users/dhewitt/Data/pps/Exports/ERD/LME_coefficients_covs_1710.csv"
write.csv(all_merged_cov_coefficients, file = file_path, row.names = TRUE)

# ------------- RQ2 HemiCovs -------------

EEGData<- read.csv("/Users/dhewitt/Data/pps/Exports/ERD/PPSERDDataLong_Grouped_noav_withratings_elhem_180324.csv")
View(EEGData)
attach(EEGData)

EEGData <- EEGData %>% filter(Block == 2 & congruency != 0) ##1 now dropped from file

EEGData$CueSide<-factor(EEGData$Side,
                        levels = c(0,1,2),
                        labels = c("middle", "left","right"))

EEGData$TonicSide<-factor(EEGData$congruency,
                          levels = c(1,2),
                          labels = c("incongruent","congruent"))

EEGData$ElectrodeGroup<-factor(EEGData$Grouping1,
                               levels = c(1,3,4,5),
                               labels = c("Frontal", "Central","Parietal","Occipital")) #averaging over both levels of pain side

EEGData$ElHem<-factor(EEGData$ElHem,
                      levels = c(1,-1),
                      labels = c("Contra","Ipsi")) #averaging over both levels of pain side

EEGData <- na.omit(EEGData)

###################### separating into frequency bands

filtered_data_alpha <- EEGData %>% filter(FreqBand == 8)
filtered_data_beta <- EEGData %>% filter(FreqBand == 16)

# ------------- Alpha - HemiCovs -------------
## Now adding in the congruency condition for ones that were significant alone

covariates <- c("MeanInt", "MeanUn", "PupilDiameter")

model_summaries <- list()
alpha_hemcov_coefficients_table <- data.frame()

for (covariate in covariates) {
  current_model_summaries <- list()
  for (electrode in unique(filtered_data_alpha$ElectrodeGroup)) {
    filtered_data_electrode <- filtered_data_alpha %>% filter(ElectrodeGroup == electrode)
    formula <- paste("EEGPowerChange ~ as.factor(TonicSide) *", covariate, "* ElHem + (1 | ID/Rep)")
    current_model <- lmer(formula, REML = FALSE, data = filtered_data_electrode)
    current_model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
    
    #saving to a table
    coefficients <- as.data.frame(coef(summary(current_model)))[-1, ]
    coefficients$ElectrodeGroup <- paste0("ElectrodeGroup_", electrode)
    coefficients$Covariate <- covariate
    alpha_hemcov_coefficients_table <- rbind(alpha_hemcov_coefficients_table, coefficients)
  }
  model_summaries[[covariate]] <- current_model_summaries
}
alpha_hemcov_coefficients_table$Test <- "RQ2HemAlphaModerate"

model_summaries

#### Getting estimated means and plotting
alpha_frontal <- EEGData %>% filter(FreqBand == 8 & ElectrodeGroup == "Frontal")

# interactions with hem and covs
cov_alpha_frontal <- lmer(EEGPowerChange~ TonicSide * MeanUn * ElHem + (1|ID/Rep), REML = FALSE, data = alpha_frontal)
alpha_frontal$ERD_unp_hem <- predict(cov_alpha_frontal)
emmip(cov_alpha_frontal, TonicSide:ElHem ~ MeanUn, cov.reduce = range)

# ------------- Beta - HemiCovs -------------
## Now adding in the congruency condition

covariates <- c("PupilDiameter", "MeanUn")

model_summaries <- list()
beta_hemcov_coefficients_table <- data.frame()

for (covariate in covariates) {
  current_model_summaries <- list()
  for (electrode in unique(filtered_data_beta$ElectrodeGroup)) {
    filtered_data_electrode <- filtered_data_beta %>% filter(ElectrodeGroup == electrode)
    formula <- paste("EEGPowerChange ~ as.factor(TonicSide) *", covariate, "* ElHem + (1 | ID/Rep)")
    current_model <- lmer(formula, REML = FALSE, data = filtered_data_electrode)
    current_model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
    
    #saving to a table
    coefficients <- as.data.frame(coef(summary(current_model)))[-1, ]
    coefficients$ElectrodeGroup <- paste0("ElectrodeGroup_", electrode)
    coefficients$Covariate <- covariate
    beta_hemcov_coefficients_table <- rbind(beta_hemcov_coefficients_table, coefficients)
  }
  model_summaries[[covariate]] <- current_model_summaries
}
beta_hemcov_coefficients_table$Test <- "RQ2HemBetaModerate"

model_summaries

#### Getting estimated means and plotting
beta_central <- EEGData %>% filter(FreqBand == 16 & ElectrodeGroup == "Central")

# interactions with hem and covs
cov_beta_central2 <- lmer(EEGPowerChange~ TonicSide * MeanUn * ElHem + (1|ID/Rep), REML = FALSE, data = beta_central)
cov_beta_central3 <- lmer(EEGPowerChange~ TonicSide * PupilDiameter * ElHem + (1|ID/Rep), REML = FALSE, data = beta_central)
beta_central$ERD_unp_hem <- predict(cov_beta_central2)
beta_central$ERD_pupilD_hem <- predict(cov_beta_central3)
emmip(cov_beta_central, TonicSide:ElHem ~ MeanUn, cov.reduce = range)
emmip(cov_beta_central2, TonicSide:ElHem ~ PupilDiameter, cov.reduce = range)

# ---- Exporting coefficient tables

alpha_hemcov_coefficients_table$FDR_adjusted_pvalue <- p.adjust(alpha_hemcov_coefficients_table$`Pr(>|t|)`, method = "fdr")
beta_hemcov_coefficients_table$FDR_adjusted_pvalue <- p.adjust(beta_hemcov_coefficients_table$`Pr(>|t|)`, method = "fdr")

all_merged_hemcov_coefficients <- rbind(alpha_hemcov_coefficients_table, beta_hemcov_coefficients_table)
file_path <- "/Users/dhewitt/Data/pps/Exports/ERD/LME_coefficients_hemcovs_0705.csv"
write.csv(all_merged_hemcov_coefficients, file = file_path, row.names = TRUE)

# exporting csvs for figures
alpha_frontal$ERD_pupilD_hem <- 'na'

adjustedRQ2hemcovdata <- rbind(beta_central, alpha_frontal)
file_path <- "/Users/dhewitt/Data/pps/Exports/ERD/adjustedRQ2hemcovdata_070524.csv"
write.csv(adjustedRQ2hemcovdata, file = file_path, row.names = TRUE)


