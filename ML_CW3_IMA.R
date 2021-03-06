

###############-------------------------------------------#################
###############          IMANOL BELAUSTEGUIGOITIA         #################
###############                                           #################
###############             COURSEWORK 3 ML               #################
###############-------------------------------------------#################


# Workflow

# 1. Data Cleaning
# 2. Exploratory Analysis
# 3. 10 Facts
# 4. Data Mining: Manchester United Case Study
# 5. Predicting Market Value


###############     1.  Data Cleaning     #################


####### Setting working directory, libraries and loading data ##########

setwd("~/Downloads/")
FIFA19 <- read.csv("FIFA19.csv")
View(FIFA19)
load("FIFA19_ML")

### Downloading Libraries ###

library(caret)
library(DMwR)
library(parallel)
library(doParallel)
library(dplyr)
library(mlbench)
library(dummies)
library(ggpubr)
library(xgboost)

### Inspecting the data

dim(FIFA19)
names(FIFA19)
str(FIFA19)

### Checking how complete is the data

# Data Completeness

total_na <- sum(is.na(FIFA19))
total_data <- 18207 * 89 # dim 18207 X 89
percentage_na <- total_na/total_data                
percentage_na


##  Gettin rid of unuseful variables
#Photo, Flag, ID, CLUB LOGO, REAL FACE
#LS : RB

FIFA19[,"Photo"] <- NULL
FIFA19[,"Flag"] <- NULL
FIFA19[,"ID"] <- NULL
FIFA19[,"Club.Logo"] <- NULL
FIFA19[,29:54] <- NULL


# Removing unuseful characters (like $)


FIFA19[,'Value'] <- gsub("€","",FIFA19[,'Value'])
FIFA19[,'Value'] <- gsub("M","",FIFA19[,'Value'])

FIFA19[,'Wage'] <- gsub("€","",FIFA19[,'Value'])
FIFA19[,'Wage'] <- gsub("K","",FIFA19[,'Value'])

FIFA19[,'Release.Clause'] <- gsub("€","",FIFA19[,'Release.Clause'])
FIFA19[,'Release.Clause'] <- gsub("M","",FIFA19[,'Release.Clause'])

FIFA19[,'Weight'] <- gsub("lbs","",FIFA19[,'Value'])

FIFA19[,'Height'] <- gsub("'",".",FIFA19[,'Height'])

View(FIFA19)


# Transforming to numeric for further steps

FIFA19$Release.Clause <- as.numeric(FIFA19$Release.Clause)
FIFA19$Contract.Valid.Until <- as.numeric(FIFA19$Contract.Valid.Until)
FIFA19$Wage <- as.numeric(FIFA19$Wage)
FIFA19$Value <- as.numeric(FIFA19$Value)




###############     2.  Exploratory Analysis     #################


mean(FIFA19$Contract.Valid.Until, na.rm =TRUE)
mean(FIFA19$Release.Clause, na.rm =TRUE)
mean(FIFA19$Value, na.rm =TRUE)



range(FIFA19$Overall)
quantile(FIFA19$Overall)



FIFA19 %>%
  ggplot(aes(x= Overall)) +
  geom_histogram(color = "white", fill = "darkgrey") +
  ggtitle("Player ratings Are Normally Distributed", subtitle = "The mean can be used as a measure of central tendancy")

FIFA19 %>%
  ggplot(aes(x= Age)) +
  geom_histogram(color = "white", fill = "darkgrey") +
  ggtitle("Player ages is not normally distributed", subtitle = "Left side distribution")

FIFA19 %>%
  group_by(Age) %>%
  summarise(Rating = mean(Overall)) %>%
  ggplot(aes(x= Age, y= Rating, group = 1)) +
  geom_line(color = "grey50", size = 1) +
  ggtitle("The Age Curve Flattens Off", subtitle = "Player ratings tend not to get better after the age of 30")



#### YOUNGEST TEAMS


age_avg <- mean(FIFA19$Age)
age_sd <- sd(FIFA19$Age)

team_age <- FIFA19 %>%
  group_by(Club) %>%
  summarise(AvgAge = mean(Age)) %>%
  mutate(AgeZ_score = (AvgAge - age_avg) / age_sd)

team_age <- team_age %>%
  mutate(AgeType = ifelse(AgeZ_score <0, "Below", "Above"))


team_age <- team_age %>%
  arrange(desc(AgeZ_score)) %>%
  head(20) %>%
  rbind(team_age %>% arrange(desc(AgeZ_score)) %>% tail(20))


team_age %>%
  ggplot(aes(x= reorder(Club,AgeZ_score), y= AgeZ_score)) +
  geom_bar(stat = 'identity', aes(fill = AgeType), colour = "white") +
  geom_text(aes(label = round(AvgAge,1))) +
  scale_fill_manual(values = c("purple", "green")) +
  coord_flip() +
  ggtitle("Nordic Clubs Are Younger Than South American Clubs", subtitle = "Ranking the 20 oldest playing lists vs the 20 youngest playing lists") +
  
  theme(legend.position = "none", axis.text.x = element_blank())


##### Highest scores clubs

top_20_overall_clubs <- FIFA19 %>%
  group_by(Club) %>%
  summarise(AverageRating = mean(Overall, na.rm = T)) %>%
  arrange(desc(AverageRating)) %>%
  head(n = 20) %>% pull(Club) 


FIFA19 %>%
  filter(Club %in% top_20_overall_clubs) %>%
  mutate(Top3 = ifelse(Club %in% c("Juventus", "Napoli", "Inter"), "Yes", "No")) %>%
  ggplot(aes(x= reorder(Club,Overall), y= Overall, fill = Top3)) +
  geom_boxplot(color = "black") +
  scale_fill_manual(values = c("lightgrey", "purple")) +
  ggtitle("Italian Teams Have The Highest Overall Ratings", subtitle = "The average overall rating of the 20 highest rated teams in the game, sorted in descending order") +
  coord_flip() +
  theme(legend.position = "none")

FIFA19 %>%
  mutate(ElitePlayers = ifelse(Overall >= 85, "Elite", "Not Elite")) %>%
  group_by(Club, ElitePlayers) %>%
  filter(ElitePlayers == "Elite") %>%
  summarise(NumberElitePlayers = n()) %>%
  filter(NumberElitePlayers >1) %>%
  mutate(Top3 = ifelse(Club %in% c("Juventus", "Napoli", "Inter"), "Yes", "No")) %>%
  arrange(desc(NumberElitePlayers)) %>%
  ggplot(aes(x= reorder(Club,NumberElitePlayers), y= NumberElitePlayers, fill = Top3)) +
  geom_col(color = "black") +
  scale_fill_manual(values = c("lightgrey", "purple")) +
  ggtitle("However If You Define Talent As Number Of Superstars", subtitle = "Plotted are clubs with more than one 'elite' player. Elite players being those with a rating greater than 85") +
  scale_y_continuous(breaks = seq(0,12,1))+
  coord_flip() +
  theme(legend.position = "none")




###############     3.  10 Fun Facts     #################



# 1. One out of 3 players is left footed

table(FIFA19$Preferred.Foot)

left <- 4211/13948
left
right <- 1-left
right

# 2. England is the country with most players in the game

most_nationalities <- summary(FIFA19$Nationality)
head(most_nationalities, 10)

# 3. Spain has the most players in the top 100

top_100 <- FIFA19[0:100,]
nationalities_top_100 <- data.frame(table(top_100$Nationality))
top_100 <-(nationalities_top_100 %>% arrange(desc(Freq)))
head(top_100,10)

# 4. Mexican goalkeeper Oscar Perez (45) is the oldest player

oldest_player <- FIFA19 %>%
  arrange(desc(Age))

head(oldest_player[,2:5],1)

# 5. Best 10 under 21 players in the game

young_beasts<-subset(FIFA19, FIFA19$Age < 21 & FIFA19$Overall>75)
head(young_beasts[,2:5],10)

# 6. Englands best rated player is Harry Kane

eng<-subset(FIFA19, FIFA19$Nationality == "England" & FIFA19$Overall>80)
head(eng[,2:5],5)

# 7. Average player age in the game

mean(FIFA19$Age)

# 8. Total teams

length(unique(FIFA19$Club))

# 9. Best 3 Players

head(FIFA19[,0:5],3)

# 10. 5 Players with most expectations (Overall- Potential)

FIFA19$Potential.Gap <-  FIFA19$Potential - FIFA19$Overall

most_expectations <- FIFA19 %>%
  arrange(desc(Potential.Gap))

head(most_expectations[,2:8], 5)




###############     4. Manchester United Case Study    #################




# Man U  (22-27) (more than 80 Overall) , not very valuable # big gap between potential and overall at a good price
# Ole Gunar Solksjaer



posible_man_united <- subset(FIFA19, FIFA19$Age < 27 & FIFA19$Overall>80 & FIFA19$Potential.Gap > 0 & FIFA19$Value < 80 & FIFA19$Release.Clause < 80)
dim(posible_man_united)

sanchez_replacement <- subset(posible_man_united, Position =="RW")
dim(sanchez_replacement)
head(sanchez_replacement[,2:8],5)
new_sanchez <- subset(head(sanchez_replacement[,2:8],1))

mata_replacement <- subset(posible_man_united, Position =="RM")
dim(mata_replacement)
head(mata_replacement[,2:8],5)
new_mata <-subset(head(mata_replacement[,2:8],1))

herrera_replacement <- subset(posible_man_united, Position =="CM")
dim(herrera_replacement)
head(herrera_replacement[,2:8],5)
new_herrera <- subset(head(herrera_replacement[,2:8],1))

new_centerback <- subset(posible_man_united, Position =="CB")
dim(new_centerback)
head(new_centerback[,2:8],5)
new_1_centerback <- subset(head(new_centerback[,2:8],1))

darmian_replacement <- subset(posible_man_united, Position =="LB")

dim(darmian_replacement)
head(darmian_replacement[,2:8],5)
new_darmian <- subset(head(darmian_replacement[,2:8],1))


man_u_new_signings <- rbind(new_sanchez, new_mata, new_herrera, new_1_centerback, new_darmian)
man_u_new_signings

total_expenditure <- sum(man_u_new_signings$Value)
total_expenditure




###############     5. Predicting Market Value      ###############



######   D A T A       P R E P R O C E S S I N G



# guide https://machinelearningmastery.com/pre-process-your-dataset-in-r/


# Data preprocessing steps

# Dummification
# Near Zero Variance
# Data center and scale
# Data normalization
# The Box-Cox Transform
# cutoff correlation
# only numerics

# PCA

# Dummification
# nzv
#only numerics
# center scale, pca


# Example...


dim(FIFA19)


#### Near Zero Varince


FIFA19 <- FIFA19[, -nearZeroVar(FIFA19)]  ## removed only one predictor

dim(FIFA19)

## dummifing position, preferred foot and work rate

FIFA19_1 <- cbind(FIFA19, dummy(FIFA19$Position, sep = "_"))
FIFA19_1 <- cbind(FIFA19_1, dummy(FIFA19$Preferred.Foot, sep = "_"))
FIFA19_1 <- cbind(FIFA19_1, dummy(FIFA19$Work.Rate, sep = "_"))




names(FIFA19_1)

dim(FIFA19_1)

View(FIFA19_1)




# Model Pre processing   # we will only work with numeric values



numeric_FIFA19 <- FIFA19_1[sapply(FIFA19_1,is.numeric)]


names(numeric_FIFA19)
dim(numeric_FIFA19)



# center and scale


preProc <- preProcess(numeric_FIFA19, method=c('center','scale')) 
FIFA19_transformed <- predict(preProc,numeric_FIFA19)

### since it is centeres and scaled, we will its null values with "0"  (no need to do complex imputations since they are so few)

FIFA19_transformed <- replace(FIFA19_transformed, is.na(FIFA19_transformed), 0)

names(FIFA19_transformed)
View(FIFA19_transformed)
summary(FIFA19_transformed)


# Skewness treatment

preprocessParams <- preProcess(FIFA19_transformed, method=c("BoxCox"))
# summarize transform parameters
print(preprocessParams)
# transform the dataset using the parameters
FIFA19_transformed_1 <- predict(preprocessParams, FIFA19_transformed)
# summarize the transformed dataset (note pedigree and age)
summary(FIFA19_transformed_1)

# DATASET 1 -> NON CORRELATED VALUES


# remove high corr


df2 = cor(FIFA19_transformed_1)
hc = findCorrelation(df2, cutoff=0.75) # putt any value as a "cutoff" 
hc = sort(hc)
model_data = FIFA19_transformed_1[,-c(hc)]

dim(model_data)
dim(FIFA19_transformed_1)


# DATASET 2 --> PCA (does not discar correlated values) 


# Note that in PCA we do take higly correlated data

pca_process = preProcess(FIFA19_transformed_1, method=c("pca"))
print(pca_process)
pca_data <- predict(pca_process, FIFA19_transformed_1)
dim(pca_data)


#write.csv(model_data, "model_data.csv")
#write.csv(pca_data, "pca_data.csv")





######   M O D E L L I N G



# Remove Value + insert as non-scaled

Value <- FIFA19$Value
Value <- replace(Value, is.na(Value), 0)
model_data_1 <- subset(model_data, select = -c(Value) )
model_data_1 <- cbind(Value, model_data_1)

pca_data_1 <- cbind(Value, pca_data)

View(model_data_1)
View(pca_data_1)




# Predictor importance

set.seed(7)


control <- trainControl(method="repeatedcv", number=10, repeats=3)
model_imp <- train(Value~., data=model_data_1, method="lm", trControl=control)
importance <- varImp(model_imp, scale=FALSE)
print(importance)
plot(importance)


dim(model_data)

model1 <- lm(Value ~., data = FIFA19_transformed)
model1_results <- summary(model1)
summary(model1)



##### L i n e a r   R e g r e s s i o n


## 1st Linear model (all features)

tc <- trainControl(method = "cv", number = 10)


lm1_cv <- train(Value~., data = model_data_1, method = "lm",
                trControl = tc)
summary(lm1_cv)

results_lm1_cv <- summary(lm1_cv)

## 2nd model contains 20 relevant features (less than 0.001 p - value)


lm2_cv <- train(Value~Age+Potential+Wage+International.Reputation+Skill.Moves+Jersey.Number+Contract.Valid.Until+SprintSpeed+SprintSpeed+Reactions+Stamina+Strength+Composure+FIFA19_CAM+FIFA19_CB+FIFA19_CDM+FIFA19_CF+FIFA19_CM+FIFA19_LB+FIFA19_LCB, data = model_data_1, method = "lm",
                trControl = tc)

results_lm2_cv <- summary(lm2_cv)


## 3rd model contains only 4 features that are really intuitive

lm3_cv <- train(Value~Age+Potential+Wage+International.Reputation+Stamina, data = model_data_1, method = "lm",
                trControl = tc)

summary(lm3_cv)

results_lm3_cv <- summary(lm3_cv)


# Best MSE is 3.533


# with PCA

lm1_cv_PCA <- train(Value~., data = pca_data_1, method = "lm",
                trControl = tc)


summary(lm1_cv_PCA)

results_csv_PCA <- summary(lm1_cv_PCA)


# RMSE 0.959 which is great!



##### S t o c h a s t i c  G r a d i e n t  B o o s t i n g  with  P C A


set.seed(7)

gbmFit1_pca <- train(Value ~ ., data = pca_data_1, 
                 method = "gbm", 
                 trControl = tc, 
                 verbose = FALSE, 
                 ## Only a single model can be passed to the
                 ## function when no resampling is used:
                 tuneGrid = data.frame(interaction.depth = 4,
                                       n.trees = 100,
                                       shrinkage = c(.1,.2,.3),
                                       n.minobsinnode = 20),
                 metric = "RMSE")


results_gbmFit1_pca <- gbmFit1_pca

results_gbmFit1_pca

# RMSE of 1.11

set.seed(7)

gbmFit2_pca <- train(Value ~ ., data = pca_data_1, 
                     method = "gbm", 
                     trControl = tc, 
                     verbose = FALSE, 
                     ## Only a single model can be passed to the
                     ## function when no resampling is used:
                     tuneGrid = data.frame(interaction.depth = 4,
                                           n.trees = 300,
                                           shrinkage = .2,
                                           n.minobsinnode = 20),
                     metric = "RMSE")


results_gbmFit2_pca <- gbmFit2_pca

results_gbmFit2_pca

# RMSE 0.98935



###### e X t r e m e   G r a d i e n t    B o o s t i n g   with   P C A


set.seed(7)


xgbGrid_1 <- expand.grid(nrounds = c(1, 10, 15),
                             max_depth =  4,
                             eta = .1,
                             gamma = 0,
                             colsample_bytree = .7,
                             min_child_weight = 1,
                             subsample = c(.5,.8,1))

xgbFit1_pca <- train(Value ~ ., data = pca_data_1, 
                     method = "xgbTree", 
                     trControl = tc, 
                     verbose = FALSE, 
                     ## Only a single model can be passed to the
                     ## function when no resampling is used:
                     tuneGrid = xgbGrid_1, 
                     metric = "RMSE")


results_xgbFit1_pca <- xgbFit1_pca


### clearly needs more trees


set.seed(7)


xgbGrid_2 <- expand.grid(nrounds = c(100, 150, 200),
                         max_depth =  4,
                         eta = .1,
                         gamma = 0,
                         colsample_bytree = .7,
                         min_child_weight = 1,
                         subsample = c(.5,.8,1))


xgbFit2_pca <- train(Value ~ ., data = pca_data_1, 
                     method = "xgbTree", 
                     trControl = tc, 
                     verbose = FALSE, 
                     ## Only a single model can be passed to the
                     ## function when no resampling is used:
                     tuneGrid = xgbGrid_2, 
                     metric = "RMSE")


xgbFit2_pca_results <- xgbFit2_pca
c


## third model


set.seed(7)


xgbGrid_3 <- expand.grid(nrounds = c(250,400),
                         max_depth =  4,
                         eta = .1,
                         gamma = 0,
                         colsample_bytree = .7,
                         min_child_weight = 1,
                         subsample = c(.5,.8,1))


xgbFit3_pca <- train(Value ~ ., data = pca_data_1, 
                     method = "xgbTree", 
                     trControl = tc, 
                     verbose = FALSE, 
                     ## Only a single model can be passed to the
                     ## function when no resampling is used:
                     tuneGrid = xgbGrid_3, 
                     metric = "RMSE")

xgbFit3_pca_results <- xgbFit3_pca
xgbFit3_pca_results



### fourth model


set.seed(7)

xgbGrid_4 <- expand.grid(nrounds = 1000,
                         max_depth =  4,
                         eta = .1,
                         gamma = 0,
                         colsample_bytree = .7,
                         min_child_weight = 1,
                         subsample = c(.5,.8,1))


xgbFit4_pca <- train(Value ~ ., data = pca_data_1, 
                     method = "xgbTree", 
                     trControl = tc, 
                     verbose = FALSE, 
                     ## Only a single model can be passed to the
                     ## function when no resampling is used:
                     tuneGrid = xgbGrid_4, 
                     metric = "RMSE")


xgbFit4_pca_results <- xgbFit4_pca
xgbFit4_pca_results




###### R a n d o m   F o r e s t   with   P C A



set.seed(7)


rfFit_pca1 <- train(Value ~ ., 
                data = pca_data_1,
                method = 'ranger',
                # should be set high at least p/3
                tuneLength = 10, 
                trControl = tc,
                ## parameters passed onto the ranger function
                # the bigger the better.
                num.trees = 15,
                importance = "permutation")


rfFit_pca1_results <- rfFit_pca1

rfFit_pca1_results


### second model


set.seed(7)


rfFit_pca2 <- train(Value ~ ., 
                    data = pca_data_1,
                    method = 'ranger',
                    # should be set high at least p/3
                    tuneLength = 10, 
                    trControl = tc,
                    ## parameters passed onto the ranger function
                    # the bigger the better.
                    num.trees = 150,
                    importance = "permutation")


rfFit_pca2_results <- rfFit_pca2
rfFit_pca2_results



##### S U P P O R T   V E C T O R    M A C H I N E S    WITH    P C A 


svm_pca1 <- train(Value~., data=pca_data_1, method = "svmLinear", trControl = tc)

svm_pca1_results <- svm_pca1


svm_pca1_results

# RMSE 1.01





#######  M o d e l    r e s u l t s




# L i n e a r   R e g r e s s i o n

results_lm1_cv
results_lm2_cv
lm3_cv
results_csv_PCA

# G B M

results_gbmFit1_pca
results_gbmFit2_pca

# X G B

results_xgbFit1_pca
xgbFit2_pca_results 
xgbFit3_pca_results
xgbFit4_pca_results

# R a n d o m  F o r e s t 

rfFit_pca1_results
rfFit_pca2_results

# S V M 

svm_pca1_results


#### Best Model

xgbFit4_pca_results

# Type: eXtreme Gradient Boosting 

# 'nrounds' 1000
# max_depth = 4
# eta = 0.1
# gamma = 0
# colsample_bytree = 0.7 
# min_child_weight = 1
# subsample = 1.



# RMSE       Rsquared   MAE
# 0.7217564  0.9835732  0.3410680



save.image("FIFA19_ML")



###   Things I could have done better


# 1. Imputation
# 2. Categorical Variables







