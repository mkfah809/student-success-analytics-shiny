## Random Forest Regression 
# Install if not already available
if(!require(randomForest)) install.packages("randomForest")
if(!require(ggplot2)) install.packages("ggplot2")
if(!require(caret)) install.packages("caret")
if(!require(dplyr)) install.packages("dplyr")

# Load libraries
library(randomForest)
library(ggplot2)
library(caret)
library(dplyr)

df <- read.csv("data.csv", header = TRUE)

# Check structure
str(df)
summary(df$Target)


#We’ll predict a continuous numeric grade, for example:
  
# Remove NAs and keep relevant columns
df_reg <- df %>%
  select(Admission.grade,
         Curricular.units.1st.sem..grade.,
         Curricular.units.2nd.sem..grade.,
         Age.at.enrollment,
         Gender,
         Debtor,
         Scholarship.holder) %>%
  na.omit()

# Make categorical variables factors
df_reg$Gender <- as.factor(df_reg$Gender)
df_reg$Debtor <- as.factor(df_reg$Debtor)
df_reg$Scholarship.holder <- as.factor(df_reg$Scholarship.holder)

#Step 4: Split into train/test
set.seed(123)
trainIndex <- createDataPartition(df_reg$Curricular.units.2nd.sem..grade., p = 0.8, list = FALSE)
train_reg <- df_reg[trainIndex, ]
test_reg  <- df_reg[-trainIndex, ]


#Step 5: Train Random Forest Regression
rf_reg <- randomForest(
  Curricular.units.2nd.sem..grade. ~ .,
  data = train_reg,
  ntree = 500,
  mtry = 3,
  importance = TRUE
)
print(rf_reg)


#Step 6: Evaluate the model
pred_reg <- predict(rf_reg, newdata = test_reg)
mse <- mean((pred_reg - test_reg$Curricular.units.2nd.sem..grade.)^2)
rmse <- sqrt(mse)
cat("RMSE:", rmse)


#Step 7: Visualize regression results
ggplot(data = NULL, aes(x = test_reg$Curricular.units.2nd.sem..grade., y = pred_reg)) +
  geom_point(color = "steelblue") +
  geom_abline(slope = 1, intercept = 0, color = "red") +
  labs(x = "Actual Grades", y = "Predicted Grades", title = "Random Forest Regression Results")


# Step 9: Now for Classification

##Let’s predict the Target variable (“Dropout”, “Enrolled”, “Graduate”):
  
df_class <- df %>%
  select(Gender, Age.at.enrollment, Admission.grade,
         Curricular.units.1st.sem..grade.,
         Curricular.units.2nd.sem..grade.,
         Scholarship.holder, Debtor, Target) %>%
  na.omit()

# Convert categorical variables to factors
df_class$Gender <- as.factor(df_class$Gender)
df_class$Scholarship.holder <- as.factor(df_class$Scholarship.holder)
df_class$Debtor <- as.factor(df_class$Debtor)
df_class$Target <- as.factor(df_class$Target)

#Split and train:
set.seed(123)
trainIndex <- createDataPartition(df_class$Target, p = 0.8, list = FALSE)
train_class <- df_class[trainIndex, ]
test_class  <- df_class[-trainIndex, ]

rf_class <- randomForest(
  Target ~ .,
  data = train_class,
  ntree = 500,
  mtry = 3,
  importance = TRUE
)
print(rf_class)

#Evaluate classification:
  pred_class <- predict(rf_class, newdata = test_class)
confusionMatrix(pred_class, test_class$Target)


#Interpretation:
  
#The confusion matrix tells you how well the model classified students.

#Diagonal values = correct predictions.

#Off-diagonal = misclassifications.

#Accuracy = overall success rate.

#Plot variable importance (classification)
varImpPlot(rf_class)


#Reading this plot:
  
#Shows which features best separate classes.

#For example:
  
#  Curricular.units.2nd.sem..grade. → strong predictor of “Graduate”.

#Debtor or Scholarship.holder → strong predictors of “Dropout”.

#Visualization of classification predictions:
ggplot(data.frame(Predicted = pred_class, Actual = test_class$Target),
         aes(x = Actual, fill = Predicted)) +
  geom_bar(position = "fill") +
  labs(title = "Random Forest Classification Results",
       x = "Actual Status", y = "Proportion") +
  scale_y_continuous(labels = scales::percent)

