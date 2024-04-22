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


###################### RQ1

Pupildata<- read.csv("/Users/dhewitt/Data/pps/Exports/GazeDirection/GrandAvExport_GazeDirExtLong_Recoded_noav_1904.csv") 
View(Pupildata)
attach(Pupildata)

Pupildata$Condition<-factor(Pupildata$Condition,
                            levels = c(1,2),
                            labels = c("Conditioning", "Extinction"))

Pupildata$Cue<-factor(Pupildata$Side,
                      levels = c(0,1,2),
                      labels = c("Neutral", "Pain", "Pain")) #averaging over both levels of pain side

##without phase int
diameter_pred_phase<- lmer(Measure~ as.factor(Cue) * as.factor(Condition) + Phase + (1|ID/Rep), REML = FALSE, data = Pupildata)
summary(diameter_pred_phase)
report(diameter_pred_phase)

emmeans(diameter_pred_phase, list(pairwise ~ Condition), adjust = "bonferroni")  #post hoc (two correction egs)

###with phase int
diameter_pred_phase<- lmer(Measure~ as.factor(Cue) * as.factor(Condition) * Phase + (1|ID/Rep), REML = FALSE, data = Pupildata)
summary(diameter_pred_phase)
report(diameter_pred_phase)

###################### RQ2

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

## simple - ns
diameter_pred_phase<- lmer(Measure~ as.factor(TonicSide) + (1|ID/Rep), REML = FALSE, data = Pupildata)
summary(diameter_pred_phase)
report(diameter_pred_phase)

##without phase int - ns
diameter_pred_phase<- lmer(Measure~ as.factor(TonicSide) + Phase + (1|ID/Rep), REML = FALSE, data = Pupildata)
summary(diameter_pred_phase)
report(diameter_pred_phase)

###with phase int - ns
diameter_pred_phase_int<- lmer(Measure~ as.factor(TonicSide) * Phase + (1|ID/Rep), REML = FALSE, data = Pupildata)
summary(diameter_pred_phase_int)
report(diameter_pred_phase_int)


##### covariates

## just cov only - none sig

diameter_pred_phase1<- lmer(Measure~ Age + (1|ID/Rep), REML = FALSE, data = Pupildata)
diameter_pred_phase2<- lmer(Measure~ Sex + (1|ID/Rep), REML = FALSE, data = Pupildata)
diameter_pred_phase3<- lmer(Measure~ STAI_Trait_Score + (1|ID/Rep), REML = FALSE, data = Pupildata)
diameter_pred_phase4<- lmer(Measure~ MeanInt + (1|ID/Rep), REML = FALSE, data = Pupildata)
diameter_pred_phase5<- lmer(Measure~ MeanUn + (1|ID/Rep), REML = FALSE, data = Pupildata)
summary(diameter_pred_phase1)
summary(diameter_pred_phase2)
summary(diameter_pred_phase3)
summary(diameter_pred_phase4)
summary(diameter_pred_phase5)

## cov with cond - none sig

diameter_pred_phase1<- lmer(Measure~ as.factor(TonicSide) + Age + (1|ID/Rep), REML = FALSE, data = Pupildata)
diameter_pred_phase2<- lmer(Measure~ as.factor(TonicSide) + Sex + (1|ID/Rep), REML = FALSE, data = Pupildata)
diameter_pred_phase3<- lmer(Measure~ as.factor(TonicSide) + STAI_Trait_Score + (1|ID/Rep), REML = FALSE, data = Pupildata)
diameter_pred_phase4<- lmer(Measure~ as.factor(TonicSide) + MeanInt + (1|ID/Rep), REML = FALSE, data = Pupildata)
diameter_pred_phase5<- lmer(Measure~ as.factor(TonicSide) + MeanUn + (1|ID/Rep), REML = FALSE, data = Pupildata)
summary(diameter_pred_phase1)
summary(diameter_pred_phase2)
summary(diameter_pred_phase3)
summary(diameter_pred_phase4)
summary(diameter_pred_phase5)

Pupildata <- Pupildata %>% filter(Phase != 1 & Phase != 4 ) ## just taking anticipatory phases now - ns

## simple - ns
diameter_pred_phase<- lmer(Measure~ as.factor(TonicSide) + (1|ID/Rep), REML = FALSE, data = Pupildata)
summary(diameter_pred_phase)
#report(diameter_pred_phase)

##without phase int - ns
diameter_pred_phase<- lmer(Measure~ as.factor(TonicSide) + Phase + (1|ID/Rep), REML = FALSE, data = Pupildata)
summary(diameter_pred_phase)
#report(diameter_pred_phase)

###with phase int - ns
diameter_pred_phase_int<- lmer(Measure~ as.factor(TonicSide) * Phase + (1|ID/Rep), REML = FALSE, data = Pupildata)
summary(diameter_pred_phase_int)

