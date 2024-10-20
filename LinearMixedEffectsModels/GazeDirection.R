install.packages("lme4") #### installs the multilevel package - only need to do this once
install.packages("lmerTest") #### installs p values for the multilevel package - only need to do this once
install.packages("emmeans")     ### estimated marginal means and p values
install.packages("report")

library(lme4)
library(lmerTest)
library(emmeans)
library(report)
library(dplyr)

options(scipen = 999) 

output_file <- "/Users/dhewitt/Data/pps/Exports/GazeDirection/Model_Summaries.txt"
coefficients_file <- "/Users/dhewitt/Data/pps/Exports/GazeDirection/LME_coefficients.csv"

###################### RQ1
# ------------- Load data -------------

Pupildata<- read.csv("/Users/dhewitt/Data/pps/Exports/GazeDirection/GrandAvExport_GazeDirExtLong_Recoded_noav_1904.csv") 
View(Pupildata)
attach(Pupildata)

Pupildata$Condition<-factor(Pupildata$Condition,
                            levels = c(1,2),
                            labels = c("Conditioning", "Extinction"))

Pupildata$Cue<-factor(Pupildata$Side,
                      levels = c(0,1,2),
                      labels = c("Neutral", "Pain", "Pain")) #averaging over both levels of pain side


contrasts(Pupildata$Condition) <- contr.sum(2)
Pupildata$Cue <- relevel(Pupildata$Cue, ref = "Neutral")

# Remove outliers from z-scores
Pupildata$z_score <- (Pupildata$Measure - mean(Pupildata$Measure, na.rm = TRUE)) / sd(Pupildata$Measure, na.rm = TRUE)
Pupildata <- Pupildata[abs(Pupildata$z_score) < 3, ]

# ------------- RQ1 LMM Models -------------

diameter_pred_phase<- lmer(Measure~ as.factor(Cue) * as.factor(Condition) + Phase + (1|ID/Rep), REML = FALSE, data = Pupildata)
diameter_pred_phase_int<- lmer(Measure~ as.factor(Cue) * as.factor(Condition) * Phase + (1|ID/Rep), REML = FALSE, data = Pupildata)

#Check fit and residuals of the fitted model/s
AIC(diameter_pred_phase, diameter_pred_phase_int)
BIC(diameter_pred_phase, diameter_pred_phase_int)

residuals <- residuals(diameter_pred_phase_int)
qqnorm(residuals)
qqline(residuals)
hist(residuals)

summary(diameter_pred_phase)
summary(diameter_pred_phase_int) #none sig

#---- saving
summary(diameter_pred_phase_int)
sink(output_file)  # Redirecting output to file
cat("RQ1 - Summary of gaze_pred_phase:\n")
summary(diameter_pred_phase_int)
sink()

coefficients_table_RQ1 <- as.data.frame(summary(diameter_pred_phase_int)$coefficients[-1, ])  # Exclude the intercept
coefficients_table_RQ1$Test <- "RQ1"

# ------------- Load RQ2 data -------------

Pupildata<- read.csv("/Users/dhewitt/Data/pps/Exports/GazeDirection/GrandAvExport_GazeDirExtLong_Recoded_noav_1904.csv") 
View(Pupildata)
attach(Pupildata)

Pupildata <- Pupildata %>% filter(Side != 0 ) ##neutral now dropped from file

Pupildata$CueSide<-factor(Pupildata$Side,
                          levels = c(1,2),
                          labels = c("left","right"))

Pupildata$TonicSide<-factor(Pupildata$congruency,
                            levels = c(1,2),
                            labels = c("incongruent","congruent"))

# Remove outliers from z-scores
Pupildata$z_score <- (Pupildata$Measure - mean(Pupildata$Measure, na.rm = TRUE)) / sd(Pupildata$Measure, na.rm = TRUE)
Pupildata <- Pupildata[abs(Pupildata$z_score) < 3, ]

# ------------- RQ2 LMMs -------------

diameter_pred <- lmer(Measure~ as.factor(TonicSide) + (1|ID/Rep), REML = FALSE, data = Pupildata)
diameter_pred_phase<- lmer(Measure~ as.factor(TonicSide) + Phase + (1|ID/Rep), REML = FALSE, data = Pupildata)
diameter_pred_phase_int<- lmer(Measure~ as.factor(TonicSide) * Phase + (1|ID/Rep), REML = FALSE, data = Pupildata)

# accounting for cue dir
diameter_pred <- lmer(Measure~ as.factor(TonicSide) + as.factor(CueSide) + (1|ID/Rep), REML = FALSE, data = Pupildata)
diameter_pred_phase<- lmer(Measure~ as.factor(TonicSide) + as.factor(CueSide) + Phase + (1|ID/Rep), REML = FALSE, data = Pupildata)
diameter_pred_phase_int<- lmer(Measure~ as.factor(TonicSide) + as.factor(CueSide) * Phase + (1|ID/Rep), REML = FALSE, data = Pupildata)

AIC(diameter_pred, diameter_pred_phase, diameter_pred_phase_int)
BIC(diameter_pred, diameter_pred_phase, diameter_pred_phase_int)

summary(diameter_pred) ## simple - ns
summary(diameter_pred_phase) ##without phase int - best BIC - ns
summary(diameter_pred_phase_int) ###with phase int - ns

residuals <- residuals(diameter_pred_phase)
qqnorm(residuals)
qqline(residuals)
hist(residuals)

#---- saving
summary(diameter_pred)
sink(output_file)  # Redirecting output to file
cat("RQ2 - Summary of gaze_pred\n")
summary(diameter_pred)
sink()

coefficients_table_RQ2 <- as.data.frame(summary(diameter_pred)$coefficients)  # Exclude the intercept
coefficients_table_RQ2$Test <- "RQ2"
all_coefficients <- rbind(coefficients_table_RQ1, coefficients_table_RQ2)
all_coefficients$FDR_adjusted_pvalue <- p.adjust(all_coefficients$`Pr(>|t|)`, method = "fdr")
write.csv(all_coefficients, file = coefficients_file, row.names = TRUE)

##### covariates

# ------------- RQ2 Covariates -------------

## just cov only - none sig
covariates <- c("STAI_Trait_Score", "Age", "MeanInt", "MeanUn", "Sex")
model_summaries <- list()

# Loop through covariates for models with covariates only
for (covariate in covariates) {
  formula <- paste("Measure ~", covariate, "+ (1 | ID/Rep)")
  model <- lmer(formula, REML = FALSE, data = Pupildata)
  model_summaries[[paste0("Covariate_", covariate)]] <- summary(model)
}

# Display summaries of covariate-only models
for (model_name in names(model_summaries)) {
  cat("Summary of", model_name, "model:\n")
  print(model_summaries[[model_name]])
  cat("\n")
}

## cov with cond - none sig

model_summaries_with_cond <- list()

# Loop through covariates for models with TonicSide and covariates
for (covariate in covariates) {
  formula <- paste("Measure ~ as.factor(TonicSide) +", covariate, "+ (1 | ID/Rep)")
  model <- lmer(formula, REML = FALSE, data = Pupildata)
  model_summaries_with_cond[[paste0("Covariate_Cond_", covariate)]] <- summary(model)
}

# Display summaries of models with TonicSide and covariates
for (model_name in names(model_summaries_with_cond)) {
  cat("Summary of", model_name, "model with TonicSide:\n")
  print(model_summaries_with_cond[[model_name]])
  cat("\n")
}

################### with cov interaction - this is the critical comparison - none sig

model_summaries_with_cond_int <- list()

# Loop through covariates for models with TonicSide and covariates interaction
for (covariate in covariates) {
  formula <- paste("Measure ~ as.factor(TonicSide) *", covariate, "+ (1 | ID/Rep)")
  model <- lmer(formula, REML = FALSE, data = Pupildata)
  model_summaries_with_cond_int[[paste0("Covariate_Cond_", covariate)]] <- summary(model)
}

# Display summaries of models with TonicSide and covariates
for (model_name in names(model_summaries_with_cond_int)) {
  cat("Summary of", model_name, "model with TonicSide:\n")
  print(model_summaries_with_cond_int[[model_name]])
  cat("\n")
}

