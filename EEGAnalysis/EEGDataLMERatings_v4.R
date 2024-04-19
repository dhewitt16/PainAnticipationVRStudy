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

#options(scipen = 999) 

emm_options(pbkrtest.limit = 16896)
emm_options(lmerTest.limit = 16896)

###################### load data

EEGData<- read.csv("/Users/dhewitt/Data/pps/Exports/ERD/PPSERDDataLong_Grouped_noav_withratings.csv") 
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

###################### firstly looking at RQ1 - cues vs. condition
# separating into frequency bands

filtered_data_theta <- EEGData %>% filter(FreqBand == 4)
filtered_data_alpha <- EEGData %>% filter(FreqBand == 8)
filtered_data_beta <- EEGData %>% filter(FreqBand == 16)

# ------------- Alpha -------------

electrodes <- unique(filtered_data_alpha$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_alpha %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all

#including timebin in the model

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_alpha %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) + Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}
summary(current_model_alpha)

#timebin as an int - also saving the overall model pvalues vs a null model
for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_alpha %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) * Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all

# Create an empty data frame to store coefficients for multiple comparison correction
coefficients_table1 <- data.frame()
for (key in names(model_summaries)) {
  model_coefficients <- as.data.frame(model_summaries[[key]]$coefficients)
  model_coefficients$model <- key
  coefficients_table1 <- rbind(coefficients_table1, model_coefficients)
}
coefficients_table1$Test <- "RQ1AlphaComplex"

#----------------Taking central and parietal regions due to significance in interaction model

alpha_central <- EEGData %>% filter(FreqBand == 8 & ElectrodeGroup == "Central")
alpha_parietal <- EEGData %>% filter(FreqBand == 8 & ElectrodeGroup == "Parietal")

# Estimate marginal means - central

current_model_ac <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) * Timebin + (1|ID/Rep), REML = FALSE, data = alpha_central)
emmeans(current_model_ac, list(pairwise ~ Cue), adjust = "sidak")
emmeans(current_model_ac, pairwise~Cue | Condition) #if there was an interaction your code would be this
emmeans(current_model_ac, pairwise~Cue | Timebin) #if there was an interaction your code would be this

###### Estimate marginal means - parietal

current_model_ap <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) * Timebin + (1|ID/Rep), REML = FALSE, data = alpha_parietal)
emmeans(current_model_ap, list(pairwise ~ Cue), adjust = "none")
emmeans(current_model_ap, pairwise~Cue | Timebin) #if there was an interaction your code would be this
emmeans(current_model_ap, pairwise~Cue | Condition) #if there was an interaction your code would be this
emmeans(current_model_ap, pairwise~Cue | Timebin / Condition) #3 way

# ------------- Theta -------------

current_model_theta <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) + ElectrodeGroup + Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_theta)

electrodes <- unique(filtered_data_theta$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all -- sig cond effect in frontal and central

model_summaries <- list()
for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) + Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all -- sig cond effect in frontal and central

#timebin as an int
model_summaries <- list()
for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) * Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all

# Create an empty data frame to store coefficients for multiple comparison correction
coefficients_table2 <- data.frame()
for (key in names(model_summaries)) {
  model_coefficients <- as.data.frame(model_summaries[[key]]$coefficients)
  model_coefficients$model <- key
  coefficients_table2 <- rbind(coefficients_table2, model_coefficients)
}
coefficients_table2$Test <- "RQ1ThetaComplex"

#=== getting emmeans

theta_central <- EEGData %>% filter(FreqBand == 4 & ElectrodeGroup == "Central")
theta_frontal <- EEGData %>% filter(FreqBand == 4 & ElectrodeGroup == "Frontal")
current_model_frontal <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) + Timebin + (1|ID/Rep), REML = FALSE, data = theta_frontal)
current_model_central <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) + Timebin + (1|ID/Rep), REML = FALSE, data = theta_central)
emmeans(current_model_frontal, list(pairwise ~ Condition), adjust = "none")
emmeans(current_model_central, list(pairwise ~ Condition), adjust = "none")

# ------------- Beta -------------

electrodes <- unique(filtered_data_beta$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_beta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all -- sig cue effect in central and occipital, sig cond effect in parietal, sig interaction in parietal and occipital

# with timebin as a term
model_summaries <- list()
for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_beta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) + Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all -- same as above, sig cue effect in central and occipital, sig cond effect in parietal, sig interaction in parietal and occipital

#timebin as an int
model_summaries <- list()
for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_beta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) * Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all

# Create an empty data frame to store coefficients for multiple comparison correction
coefficients_table3 <- data.frame()
for (key in names(model_summaries)) {
  model_coefficients <- as.data.frame(model_summaries[[key]]$coefficients)
  model_coefficients$model <- key
  coefficients_table3 <- rbind(coefficients_table3, model_coefficients)
}
coefficients_table3$Test <- "RQ1BetaComplex"

#=== getting emmeans

beta_central <- EEGData %>% filter(FreqBand == 16 & ElectrodeGroup == "Central")
beta_parietal <- EEGData %>% filter(FreqBand == 16 & ElectrodeGroup == "Parietal")
beta_occipital <- EEGData %>% filter(FreqBand == 16 & ElectrodeGroup == "Occipital")
current_model_parietal <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) * Timebin + (1|ID/Rep), REML = FALSE, data = beta_parietal)
current_model_central <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) * Timebin + (1|ID/Rep), REML = FALSE, data = beta_central)
current_model_occipital <- lmer(EEGPowerChange~ as.factor(Cue) * as.factor(Condition) + Timebin + (1|ID/Rep), REML = FALSE, data = beta_occipital)

emmeans(current_model_central, list(pairwise ~ Cue), adjust = "none")
emmeans(current_model_central, pairwise~Cue | Condition) #if there was an interaction your code would be this
emmeans(current_model_central, pairwise~Cue | Timebin) #if there was an interaction your code would be this
emmeans(current_model_central, pairwise~Cue | Timebin / Condition) #3 way

emmeans(current_model_parietal, list(pairwise ~ Cue), adjust = "none")
emmeans(current_model_parietal, list(pairwise ~ Condition), adjust = "none")
emmeans(current_model_parietal, pairwise~Cue | Condition) #if there was an interaction your code would be this
emmeans(current_model_parietal, pairwise~Cue | Timebin) #if there was an interaction your code would be this

emmeans(current_model_occipital, list(pairwise ~ Cue), adjust = "none")
emmeans(current_model_occipital, pairwise~Cue | Condition) #if there was an interaction your code would be this

# ------------- RQ2 -------------

EEGData<- read.csv("/Users/dhewitt/Data/pps/Exports/ERD/PPSERDDataLong_Grouped_noav_withratings.csv") 
View(EEGData)
attach(EEGData)

EEGData <- EEGData %>% filter(Block == 2 & congruency != 0 ) ##1 now dropped from file

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

###################### separating into frequency bands

filtered_data_theta <- EEGData %>% filter(FreqBand == 4)
filtered_data_alpha <- EEGData %>% filter(FreqBand == 8)
filtered_data_beta <- EEGData %>% filter(FreqBand == 16)

# ------------- Alpha - RQ2 -------------

electrodes <- unique(filtered_data_alpha$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_alpha %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(TonicSide) + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all

#including timebin in the model

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_alpha %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(TonicSide) + Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all

# Create an empty data frame to store coefficients for multiple comparison correction
coefficients_table4 <- data.frame()
for (key in names(model_summaries)) {
  model_coefficients <- as.data.frame(model_summaries[[key]]$coefficients)
  model_coefficients$model <- key
  coefficients_table4 <- rbind(coefficients_table4, model_coefficients)
}
coefficients_table4$Test <- "RQ2AlphaModerate"

#timebin as an int
for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_alpha %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(TonicSide) * Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all
model_summaries$ElectrodeGroup_Central   
model_summaries$ElectrodeGroup_Parietal  
model_summaries$ElectrodeGroup_Occipital 


###################### covariates

electrodes <- unique(filtered_data_alpha$ElectrodeGroup)
model_summaries1 <- list()
model_summaries2 <- list()
model_summaries3 <- list()
model_summaries4 <- list()
model_summaries5 <- list()
model_summaries6 <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_alpha %>% filter(ElectrodeGroup == electrode)
  current_model1 <- lmer(EEGPowerChange~ STAI_Trait_Score + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  current_model2 <- lmer(EEGPowerChange~ Age + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode) 
  current_model3 <- lmer(EEGPowerChange~ MeanInt + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  current_model4 <- lmer(EEGPowerChange~ MeanUn + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  current_model5 <- lmer(EEGPowerChange~ PupilDiameter + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  current_model6 <- lmer(EEGPowerChange~ GazeDirection + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries1[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model1)
  model_summaries2[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model2)
  model_summaries3[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model3)
  model_summaries4[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model4)
  model_summaries5[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model5)
  model_summaries6[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model6)
}

model_summaries1 #ns
model_summaries2 #ns
model_summaries3 #parietal & frontal  - mean int sig, occipital approaching sig
model_summaries4 #central & frontal - mean unp sig
model_summaries5 # pupil diameter - frontal, central and parietal sig
model_summaries6 # gaze dir - central sig, parietal almost sig

#################### now with the congruency condition

model_summaries1 <- list()
model_summaries2 <- list()
model_summaries3 <- list()
model_summaries4 <- list()
model_summaries5 <- list()
model_summaries6 <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_alpha %>% filter(ElectrodeGroup == electrode)
  current_model1 <- lmer(EEGPowerChange~ as.factor(TonicSide) + STAI_Trait_Score + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  current_model2 <- lmer(EEGPowerChange~  as.factor(TonicSide) + Age + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode) 
  current_model3 <- lmer(EEGPowerChange~ as.factor(TonicSide) + MeanInt + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  current_model4 <- lmer(EEGPowerChange~ as.factor(TonicSide) + MeanUn + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  current_model5 <- lmer(EEGPowerChange~ as.factor(TonicSide) + PupilDiameter + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  current_model6 <- lmer(EEGPowerChange~ as.factor(TonicSide) + GazeDirection + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries1[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model1)
  model_summaries2[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model2)
  model_summaries3[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model3)
  model_summaries4[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model4)
  model_summaries5[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model5)
  model_summaries6[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model6)
}

model_summaries1 #ns
model_summaries2 #ns
model_summaries3 #parietal & frontal  - mean int sig, occipital approaching sig
model_summaries4 #central & frontal - mean unp sig
model_summaries5 # pupil diameter sig in frontal, central, parietal. cong sig in central.
model_summaries6 # gaze dir sig in central and parietal. cong almost sig in central.

# as an int

model_summaries2 <- list()
model_summaries3 <- list()
model_summaries4 <- list()
model_summaries5 <- list()
model_summaries6 <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_alpha %>% filter(ElectrodeGroup == electrode)
  current_model2 <- lmer(EEGPowerChange~ as.factor(TonicSide) * MeanUn * MeanInt + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  current_model3 <- lmer(EEGPowerChange~ as.factor(TonicSide) * MeanInt + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  current_model4 <- lmer(EEGPowerChange~ as.factor(TonicSide) * MeanUn + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  current_model5 <- lmer(EEGPowerChange~ as.factor(TonicSide) * PupilDiameter + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  current_model6 <- lmer(EEGPowerChange~ as.factor(TonicSide) * GazeDirection + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries2[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model2)
  model_summaries3[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model3)
  model_summaries4[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model4)
  model_summaries5[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model5)
  model_summaries6[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model6)
}

model_summaries2 #
model_summaries3 #
model_summaries4 #
model_summaries5 # pupil diameter sig in frontal, central, parietal. cong sig in central.
model_summaries6 # gaze dir sig in central and parietal. cong almost sig in central.

## just including timebin to see - seems a better model (model comparison needed)

model_summaries3 <- list()
model_summaries4 <- list()
model_summaries5 <- list()
model_summaries6 <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_alpha %>% filter(ElectrodeGroup == electrode)
  current_model3 <- lmer(EEGPowerChange~ as.factor(TonicSide) * MeanInt + Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  current_model4 <- lmer(EEGPowerChange~ as.factor(TonicSide) * MeanUn + Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  current_model5 <- lmer(EEGPowerChange~ as.factor(TonicSide) * PupilDiameter + Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  current_model6 <- lmer(EEGPowerChange~ as.factor(TonicSide) * GazeDirection + Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries3[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model3)
  model_summaries4[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model4)
  model_summaries5[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model5)
  model_summaries6[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model6)
}

model_summaries3 #pain intensity -- frontal and parietal MEs and frontal ints still sig
model_summaries4 #pain unpleasantness -- frontal MEs and frontal ints still sig
model_summaries5 #pupil diameter - central and frontal sig
model_summaries6 #gaze dir - just central

#### taking frontal and central forwards

alpha_frontal <- EEGData %>% filter(FreqBand == 8 & ElectrodeGroup == "Frontal")
alpha_central <- EEGData %>% filter(FreqBand == 8 & ElectrodeGroup == "Central")
alpha_parietal <- EEGData %>% filter(FreqBand == 8 & ElectrodeGroup == "Parietal")

#---- frontal
cov_alpha_frontal1 <- lmer(EEGPowerChange~ as.factor(TonicSide) * PupilDiameter + Timebin + (1|ID/Rep), REML = FALSE, data = alpha_frontal)
cov_alpha_frontal2 <- lmer(EEGPowerChange~ as.factor(TonicSide) * GazeDirection + Timebin + (1|ID/Rep), REML = FALSE, data = alpha_frontal)
cov_alpha_frontal3 <- lmer(EEGPowerChange~ as.factor(TonicSide) * PupilDiameter * GazeDirection + Timebin + (1|ID/Rep), REML = FALSE, data = alpha_frontal)
anova(cov_alpha_frontal1,cov_alpha_frontal3)
anova(cov_alpha_frontal2,cov_alpha_frontal3)
anova(cov_alpha_frontal1,cov_alpha_frontal2,cov_alpha_frontal3)

summary(cov_alpha_frontal3)

#plotting effects - have to get rid of the 'asfactor' but this has already been determined above anyway
cov_alpha_frontal1 <- lmer(EEGPowerChange~ TonicSide * PupilDiameter + Timebin + (1|ID/Rep), REML = FALSE, data = alpha_frontal)
plot(effect("PupilDiameter", cov_alpha_frontal1))
plot(effect("TonicSide:PupilDiameter", cov_alpha_frontal1))

#plotting effects - have to get rid of the 'asfactor' but this has already been determined above anyway
cov_alpha_frontal1 <- lmer(EEGPowerChange~ TonicSide * MeanInt + Timebin + (1|ID/Rep), REML = FALSE, data = alpha_frontal)
plot(effect("MeanInt", cov_alpha_frontal1))
plot(effect("TonicSide:MeanInt", cov_alpha_frontal1))

#plotting effects - have to get rid of the 'asfactor' but this has already been determined above anyway
cov_alpha_frontal1 <- lmer(EEGPowerChange~ TonicSide * MeanUn + Timebin + (1|ID/Rep), REML = FALSE, data = alpha_frontal)
plot(effect("MeanUn", cov_alpha_frontal1))
plot(effect("TonicSide:MeanUn", cov_alpha_frontal1))

#---- central
cov_alpha_central1 <- lmer(EEGPowerChange~ as.factor(TonicSide) * PupilDiameter + Timebin + (1|ID/Rep), REML = FALSE, data = alpha_central)
cov_alpha_central2 <- lmer(EEGPowerChange~ as.factor(TonicSide) * GazeDirection + Timebin + (1|ID/Rep), REML = FALSE, data = alpha_central)
cov_alpha_central3 <- lmer(EEGPowerChange~ as.factor(TonicSide) * PupilDiameter * GazeDirection + Timebin + (1|ID/Rep), REML = FALSE, data = alpha_central)
anova(cov_alpha_frontal1,cov_alpha_frontal2,cov_alpha_frontal3)

summary(cov_alpha_central3)

#plotting effects - have to get rid of the 'asfactor' but this has already been determined above anyway
cov_alpha_central1 <- lmer(EEGPowerChange~ TonicSide * PupilDiameter + Timebin + (1|ID/Rep), REML = FALSE, data = alpha_central)
plot(effect("PupilDiameter", cov_alpha_central1))
plot(effect("TonicSide:PupilDiameter", cov_alpha_central1))

cov_alpha_central2 <- lmer(EEGPowerChange~ TonicSide * GazeDirection + Timebin + (1|ID/Rep), REML = FALSE, data = alpha_central)
plot(effect("GazeDirection", cov_alpha_central2))
plot(effect("TonicSide:GazeDirection", cov_alpha_central2))

#---- parietal

#plotting effects - have to get rid of the 'asfactor' but this has already been determined above anyway
cov_alpha_parietal1 <- lmer(EEGPowerChange~ TonicSide * MeanInt + Timebin + (1|ID/Rep), REML = FALSE, data = alpha_parietal)
plot(effect("MeanInt", cov_alpha_parietal1))

#=============================================================================
### THETA BAND - RQ2

electrodes <- unique(filtered_data_theta$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(TonicSide) + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all

#including timebin in the model
current_model_theta <- lmer(EEGPowerChange~ as.factor(TonicSide) + ElectrodeGroup + Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_theta)
summary(current_model_theta)
report(current_model_theta)

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(TonicSide) + Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all

#timebin as an int
for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(TonicSide) * Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all

# Create an empty data frame to store coefficients for multiple comparison correction
coefficients_table5 <- data.frame()
for (key in names(model_summaries)) {
  model_coefficients <- as.data.frame(model_summaries[[key]]$coefficients)
  model_coefficients$model <- key
  coefficients_table5 <- rbind(coefficients_table5, model_coefficients)
}
coefficients_table5$Test <- "RQ2ThetaComplex"

#### central

theta_central <- EEGData %>% filter(FreqBand == 4 & ElectrodeGroup == "Central")

current_model_theta <- lmer(EEGPowerChange~ as.factor(TonicSide) * Timebin + (1|ID/Rep), REML = FALSE, data = theta_central)
summary(current_model_theta)

emmeans(current_model_theta, list(pairwise ~ TonicSide), adjust = "none")
emmeans(current_model_theta, pairwise~TonicSide | Timebin) #if there was an interaction your code would be this

###################### covariates
### STAI

electrodes <- unique(filtered_data_theta$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ STAI_Trait_Score + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all

# AGE
electrodes <- unique(filtered_data_theta$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ Age + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all ##sig in parietal

# Handedness - not including as only 2 not right handed.

# Pain

electrodes <- unique(filtered_data_theta$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ MeanInt + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all

# Unp

electrodes <- unique(filtered_data_theta$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ MeanUn + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all

#################### now with the congruency condition

electrodes <- unique(filtered_data_theta$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(TonicSide) + Age + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all ## age sig in parietal - cong not sig (wasn't anyway)

# as an int

electrodes <- unique(filtered_data_theta$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(TonicSide) * Age + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #sig interaction with age*tonic side in frontal electrodes, with tonic side approaching sig.

###################### covariates - now just with timebin 1
### STAI

filtered_data_theta <- EEGData %>% filter(FreqBand == 4 & Timebin == "1")

electrodes <- unique(filtered_data_theta$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ STAI_Trait_Score + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all

# AGE
electrodes <- unique(filtered_data_theta$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ Age + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all ##almost sig in parietal

# Handedness - not including as only 2 not right handed.

# Pain

electrodes <- unique(filtered_data_theta$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ MeanInt + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all #sig in occipital

# Unp

electrodes <- unique(filtered_data_theta$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ MeanUn + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all #approaching sig in occipital

#################### now with the congruency condition
## Age

electrodes <- unique(filtered_data_theta$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(TonicSide) + Age + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all ## age almost sig in parietal - cong not sig (sig in central and appraoching sig in frontal)

# as an int

electrodes <- unique(filtered_data_theta$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(TonicSide) * Age + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #sig interaction with age*tonic side in frontal electrodes, with tonic side approaching sig.

## MeanInt

electrodes <- unique(filtered_data_theta$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(TonicSide) + MeanInt + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all ## meanint sig in occipital

# as an int

electrodes <- unique(filtered_data_theta$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(TonicSide) * MeanInt + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #sig interaction with meanint*tonic side in central electrodes, tonic side also sig

## MeanUn

electrodes <- unique(filtered_data_theta$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(TonicSide) + MeanUn + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all ## ns in any

# as an int

electrodes <- unique(filtered_data_theta$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_theta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(TonicSide) * MeanUn + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries # ns in any - dropped.

#### combining previous models and comparing

filtered_data_theta_central <- EEGData %>% filter(FreqBand == 4 & Timebin == "1" & ElectrodeGroup == 'Central')
current_model_simple <- lmer(EEGPowerChange~ as.factor(TonicSide) + (1|ID/Rep), REML = FALSE, data = filtered_data_theta_central) #lowest bic
current_model_age <- lmer(EEGPowerChange~ as.factor(TonicSide) * Age + (1|ID/Rep), REML = FALSE, data = filtered_data_theta_central)
current_model_pain <- lmer(EEGPowerChange~ as.factor(TonicSide) * MeanInt + (1|ID/Rep), REML = FALSE, data = filtered_data_theta_central) #lowest aic
current_model_all <- lmer(EEGPowerChange~ as.factor(TonicSide) * MeanInt * Age + (1|ID/Rep), REML = FALSE, data = filtered_data_theta_central) #most sig
anova(current_model_simple, current_model_age, current_model_pain, current_model_all)
anova(current_model_age, current_model_simple)
anova(current_model_pain, current_model_simple) #pain better
anova(current_model_all, current_model_pain) #all more (but not) sig, pain lower aic and bic

summary(current_model_all)
summary(current_model_pain)
summary(current_model_age)

#removing an outlier from ggplot
EEGData2 <- EEGData[-c(9129), ]



#=============================================================================
### BETA BAND - RQ2

electrodes <- unique(filtered_data_beta$ElectrodeGroup)
model_summaries <- list()

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_beta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(TonicSide) + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all

# Create an empty data frame to store coefficients for multiple comparison correction
coefficients_table6 <- data.frame()
for (key in names(model_summaries)) {
  model_coefficients <- as.data.frame(model_summaries[[key]]$coefficients)
  model_coefficients$model <- key
  coefficients_table6 <- rbind(coefficients_table6, model_coefficients)
}
coefficients_table6$Test <- "RQ2BetaSimple"

#including timebin in the model

for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_beta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(TonicSide) + Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all

#timebin as an int
for (electrode in electrodes) {
  filtered_data_electrode <- filtered_data_beta %>% filter(ElectrodeGroup == electrode)
  current_model <- lmer(EEGPowerChange~ as.factor(TonicSide) * Timebin + (1|ID/Rep), REML = FALSE, data = filtered_data_electrode)
  model_summaries[[paste0("ElectrodeGroup_", electrode)]] <- summary(current_model)
}

model_summaries #for all

## nothing significant - did not look at covariates.


### Doing multiple comparison corrections

merged_coefficients <- rbind(coefficients_table1, coefficients_table2, coefficients_table3, coefficients_table4, coefficients_table5, coefficients_table6)
merged_coefficients$FDR_adjusted_pvalue <- p.adjust(merged_coefficients$`Pr(>|t|)`, method = "fdr")
file_path <- "/Users/dhewitt/Data/pps/Exports/ERD/LME_coefficients.csv"
write.csv(merged_coefficients, file = file_path, row.names = TRUE)
