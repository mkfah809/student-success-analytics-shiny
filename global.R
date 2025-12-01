rsconnect::writeManifest()

library(randomForest)
library(gbm)
library(caret)
library(DT)
library(dplyr)
library(ggplot2)
library(glmnet)
library(rpart)
library(rmarkdown)

# --- Simple content loader ----
loadHtmlOrRmd <- function(htmlPath, rmdPath) {
  if (file.exists(htmlPath)) {
    paste(readLines(htmlPath, warn = FALSE), collapse = "\n")
  } else {
    tmpFile <- tempfile(fileext = ".html")
    rmarkdown::render(rmdPath, output_file = tmpFile, quiet = TRUE)
    paste(readLines(tmpFile, warn = FALSE), collapse = "\n")
  }
}

aboutContent    <- loadHtmlOrRmd("About.html",    "About.Rmd")
edaContent      <- loadHtmlOrRmd("EDA.html",      "EDA.Rmd")
tutorialContent <- loadHtmlOrRmd("Tutorial.html", "Tutorial.Rmd")

# --- Load data ----
rawDf <- read.csv("data.csv", header = TRUE, stringsAsFactors = FALSE)
colnames(rawDf) <- make.names(colnames(rawDf), unique = TRUE)
df <- rawDf

# --- Predictors ----
allPredictors <- unique(c(
  "Marital.status", "Application.mode", "Application.order", "Course", "Daytime.evening.attendance",
  "Previous.qualification", "Previous.qualification..grade.", "Nacionality", "Mothers.qualification",
  "Fathers.qualification", "Mothers.occupation", "Fathers.occupation", "Admission.grade", "Displaced",
  "Educational.special.needs", "Debtor", "Tuition.fees.up.to.date", "Gender", "Scholarship.holder",
  "Age.at.enrollment", "International", "Curricular.units.1st.sem..credited.",
  "Curricular.units.1st.sem..enrolled.", "Curricular.units.1st.sem..evaluations.",
  "Curricular.units.1st.sem..approved.", "Curricular.units.1st.sem..grade.",
  "Curricular.units.1st.sem..without.evaluations.", "Curricular.units.2nd.sem..credited.",
  "Curricular.units.2nd.sem..enrolled.", "Curricular.units.2nd.sem..evaluations.",
  "Curricular.units.2nd.sem..approved.", "Curricular.units.2nd.sem..grade.",
  "Curricular.units.2nd.sem..without.evaluations.", "Unemployment.rate",
  "Inflation.rate", "GDP"
))

availablePredictors <- allPredictors[allPredictors %in% colnames(df)]
colTarget <- if ("Target" %in% colnames(df)) "Target" else "Curricular.units.2nd.sem..grade."

# --- Helper functions for types ----
isNum  <- function(x) is.numeric(df[[x]])
isFact <- function(x) {
  is.factor(df[[x]]) || is.character(df[[x]]) || length(unique(df[[x]])) < 20
}

numericCols <- Filter(isNum,  availablePredictors)
factorCols  <- Filter(isFact, availablePredictors)

# --- Model info ----
modelInfo <- list(
  "Random Forest Regression"      = list(type = "reg", allowed = numericCols),
  "Gradient Boosting Regression"  = list(type = "reg", allowed = numericCols),
  "Lasso Regression"              = list(type = "reg", allowed = numericCols),
  "Random Forest Classifier"      = list(type = "clf", allowed = c(numericCols, factorCols)),
  "Decision Tree Classifier"      = list(type = "clf", allowed = c(numericCols, factorCols))
)

modelChoices <- c("-- Select Model --", names(modelInfo))



