# Student Success Analytics – Shiny App 
This project is an interactive R Shiny application to explore and model student success outcomes using a real-world higher-education dataset. The app lets you run several machine learning models, compare performance, and visually inspect predictions.

Dataset: https://archive.ics.uci.edu/dataset/697/predict+students+dropout+and+academic+success

# Features
Multi-tab interface:
# About – overview of the project and context.
# EDA – exploratory data analysis, distributions, and key relationships.
# Tutorial – short guide on how to use the app.
# App – interactive modeling dashboard.
## Multiple models:
### Random Forest Regression
### Gradient Boosting Regression
### Lasso Regression
### Random Forest Classifier
### Decision Tree Classifier
### Flexible predictor selection: choose which variables to include in the model.
### System log to show training events and simple debugging messages.
# Visual outputs:
## Regression: Actual vs Predicted scatter plot with 45° reference line.
## Classification: Actual vs Predicted bar plot.
# Simple performance metrics:
## RMSE for regression models.
## Accuracy for classification models.
# Recommended structure for this project:
## app.R
### Small launcher script that sources other files and calls shinyApp(ui, server).
## global.R
### Loads libraries.
### Loads data.csv and prepares df.
### Defines predictor lists, helper functions (isNum, isFact, loadHtmlOrRmd, etc.).
### Loads rendered/static content for the About, EDA, and Tutorial tabs.
### Defines modelInfo and modelChoices.
## ui.R
### Defines the UI:
### Page layout and CSS.
## Tabs: About, EDA, Tutorial, App.
## App tab layout with:
## Left: model selection and Update Model button.
## Right: predictor checkboxes.
## System log and model outputs sections.
## server.R
### Contains all server logic:
### Logging helper (appendLog) and reactive values.
### Rendering the predictor checkbox UI based on the chosen model.
### trainedResult reactive that:
### Filters data to selected predictors and target.
### Creates classification labels when needed.
### Splits train/test.
### Trains the chosen model.
### Computes RMSE or accuracy.
### Render functions for:
### Model code summary text.
### Metric text.
### Prediction plot.
### Short “story” text (metric summary).
### Error text.
# Installation
## Install R and RStudio.
## Install required packages:
**r
install.packages(c(
  "shiny", "randomForest", "gbm", "caret", "DT",
  "dplyr", "ggplot2", "glmnet", "rpart", "rmarkdown"
))
**
## Clone this repository and set the working directory to the project folder in RStudio.
## Running the App
## If using the split-file structure:
r
# In R/RStudio, from the project directory:
**source("app.R")**
Or, if you use a single app.R file that contains everything:
**r
shiny::runApp()
**The app will open in your default browser or in the RStudio Viewer.
# How to Use the App
## Go to the App tab.
## Select a model from the dropdown.
## Choose one or more predictors.
## Click Update Model.
