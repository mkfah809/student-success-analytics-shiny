server <- function(input, output, session) {
  
  errorMsg <- reactiveVal("")
  logMessages <- reactiveVal(
    sprintf("[%s] %s", format(Sys.time(), "%H:%M:%S"), "App initialized")
  )
  
  appendLog <- function(msg) {
    msgs <- isolate(logMessages())
    nowTime <- format(Sys.time(), "%H:%M:%S")
    newMsg <- paste0("[", nowTime, "] ", msg)
    msgs <- c(msgs, newMsg)
    if (length(msgs) > 500) {
      msgs <- tail(msgs, 500)
    }
    logMessages(msgs)
  }
  
  output$log_display <- renderText({
    paste(logMessages(), collapse = "\n")
  })
  
  output$predictor_selector <- renderUI({
    mod <- input$model_choice
    
    if (is.null(mod) || !(mod %in% names(modelInfo))) {
      return(tags$em("Select a model first."))
    }
    
    allowed <- unique(modelInfo[[mod]]$allowed)
    
    if (length(allowed) == 0) {
      return(tags$em("No predictors allowed for this model."))
    }
    
    checkboxGroupInput(
      "selected_predictors",
      label = NULL,
      choices = allowed,
      selected = allowed[1:min(8, length(allowed))],
      inline = TRUE
    )
  })
  
  trainedResult <- eventReactive(input$update_model, {
    req(input$model_choice)
    
    mod  <- input$model_choice
    type <- if (mod %in% names(modelInfo)) modelInfo[[mod]]$type else NULL
    req(type)
    
    preds <- input$selected_predictors
    req(preds)
    
    errorMsg("")
    appendLog(paste("Training model:", mod))
    
    response <- if (type == "reg") "Curricular.units.2nd.sem..grade." else colTarget
    requiredCols <- unique(c(preds, response))
    
    dat <- df %>%
      select(all_of(requiredCols)) %>%
      na.omit()
    
    if (type == "clf") {
      y <- tolower(as.character(dat[[response]]))
      dat$TargetNum <- ifelse(y %in% c("graduate", "pass", "1", "true", "yes"), 1, 0)
      dat$TargetClass <- factor(
        ifelse(dat$TargetNum == 1, "Graduate", "Dropout"),
        levels = c("Dropout", "Graduate")
      )
    }
    
    for (colName in colnames(dat)) {
      if (is.character(dat[[colName]]) ||
          is.factor(dat[[colName]]) ||
          length(unique(dat[[colName]])) < 20) {
        dat[[colName]] <- as.factor(dat[[colName]])
      }
    }
    
    if (nrow(dat) < 10) {
      errorMsg("Too few rows for modeling.")
      appendLog("Too few rows for modeling.")
      return(NULL)
    }
    
    set.seed(123)
    if (type == "reg") {
      trainIdx <- createDataPartition(dat[[response]], p = 0.8, list = FALSE)
    } else {
      trainIdx <- createDataPartition(dat$TargetClass, p = 0.8, list = FALSE)
    }
    
    train <- dat[trainIdx, , drop = FALSE]
    test  <- dat[-trainIdx, , drop = FALSE]
    
    facs <- names(which(sapply(train, is.factor)))
    for (f in facs) {
      allLvls <- union(levels(train[[f]]), levels(test[[f]]))
      train[[f]] <- factor(train[[f]], levels = allLvls)
      test[[f]]  <- factor(test[[f]],  levels = allLvls)
      if (any(is.na(test[[f]]))) {
        fillVal <- names(sort(table(train[[f]]), decreasing = TRUE))[1]
        test[[f]][is.na(test[[f]])] <- fillVal
      }
    }
    
    predsFormula <- paste(preds, collapse = " + ")
    modelObj <- NULL
    metricText <- "No metric"
    predsVals <- NULL
    
    if (mod == "Random Forest Regression") {
      frm <- as.formula(paste(response, "~", predsFormula))
      modelObj <- randomForest(frm, data = train, ntree = 200, mtry = min(3, length(preds)))
      predsVals <- predict(modelObj, newdata = test)
      metricText <- sprintf(
        "RMSE: %.3f",
        sqrt(mean((predsVals - test[[response]])^2, na.rm = TRUE))
      )
      
    } else if (mod == "Gradient Boosting Regression") {
      frm <- as.formula(paste(response, "~", predsFormula))
      modelObj <- gbm(
        frm,
        data = train,
        distribution = "gaussian",
        n.trees = 200,
        interaction.depth = 3,
        shrinkage = 0.1,
        n.minobsinnode = 10,
        verbose = FALSE
      )
      predsVals <- predict(modelObj, newdata = test, n.trees = 200)
      metricText <- sprintf(
        "RMSE: %.3f",
        sqrt(mean((predsVals - test[[response]])^2, na.rm = TRUE))
      )
      
    } else if (mod == "Lasso Regression") {
      yTrain <- train[[response]]
      xTrain <- model.matrix(as.formula(paste(response, "~", predsFormula)),
                             data = train)[, -1, drop = FALSE]
      lassoFit <- cv.glmnet(xTrain, yTrain, alpha = 1)
      modelObj <- lassoFit
      
      xTest <- model.matrix(as.formula(paste(response, "~", predsFormula)),
                            data = test)[, -1, drop = FALSE]
      predsVals <- predict(lassoFit, newx = xTest, s = "lambda.min")
      metricText <- sprintf(
        "RMSE: %.3f",
        sqrt(mean((predsVals - test[[response]])^2, na.rm = TRUE))
      )
      
    } else if (mod == "Random Forest Classifier") {
      frm <- as.formula(paste("TargetClass ~", predsFormula))
      modelObj <- randomForest(frm, data = train, ntree = 200, mtry = min(3, length(preds)))
      predsVals <- predict(modelObj, newdata = test)
      metricText <- sprintf(
        "Accuracy: %.2f%%",
        100 * mean(predsVals == test$TargetClass, na.rm = TRUE)
      )
      
    } else if (mod == "Decision Tree Classifier") {
      frm <- as.formula(paste("TargetClass ~", predsFormula))
      modelObj <- rpart(frm, data = train, method = "class")
      predsVals <- predict(modelObj, newdata = test, type = "class")
      metricText <- sprintf(
        "Accuracy: %.2f%%",
        100 * mean(predsVals == test$TargetClass, na.rm = TRUE)
      )
    }
    
    appendLog(paste("Training completed:", metricText))
    
    list(
      model_choice = mod,
      model        = modelObj,
      preds        = predsVals,
      test         = test,
      metric_text  = metricText,
      predictors   = preds,
      response_col = response,
      type         = type
    )
  })
  
  output$model_outputs <- renderUI({
    res <- trainedResult()
    
    if (!is.null(res)) {
      tagList(
        h4("Model Code:"),           verbatimTextOutput("model_code"),   hr(),
        h4("Metric:"),               verbatimTextOutput("model_metric"), hr(),
        h4("Prediction Plot:"),      plotOutput("model_plot", height = "400px"), hr(),
        h4("Insights & Recommendations:"), verbatimTextOutput("model_story"), hr(),
        h4("Errors:"),               verbatimTextOutput("debug_error")
      )
    } else {
      div(
        style = "text-align:center;padding:50px;background-color:#e9ecef;border-radius:5px;",
        h4("Select a model, predictors, and click 'Update Model'", style = "#6c757d;")
      )
    }
  })
  
  output$model_code <- renderText({
    res <- trainedResult()
    if (is.null(res)) {
      return("Waiting for model selection...")
    }
    paste(
      res$model_choice,
      "trained with predictors:",
      paste(res$predictors, collapse = ", ")
    )
  })
  
  output$model_metric <- renderText({
    res <- trainedResult()
    if (is.null(res)) {
      "Waiting..."
    } else {
      res$metric_text
    }
  })
  
  output$model_plot <- renderPlot({
    res <- trainedResult()
    
    if (is.null(res)) {
      plot.new()
      text(0.5, 0.5, "Waiting for model selection...", cex = 1.4)
      return()
    }
    
    test  <- res$test
    preds <- res$preds
    
    if (res$type == "reg") {
      dfPlot <- data.frame(
        Actual    = test[[res$response_col]],
        Predicted = as.numeric(preds)
      )
      ggplot(dfPlot, aes(x = Actual, y = Predicted)) +
        geom_point(alpha = 0.7, size = 2.2, color = "#577590") +
        geom_abline(slope = 1, intercept = 0, color = "#43aa8b", size = 1.1, alpha = 0.84) +
        labs(x = "Actual", y = "Predicted", title = res$model_choice) +
        theme_minimal(base_size = 19)
      
    } else {
      actual <- as.factor(test$TargetClass)
      dfPlot <- data.frame(Actual = actual, Predicted = preds)
      ggplot(dfPlot, aes(x = Actual, fill = Predicted)) +
        geom_bar(position = "dodge", color = "grey50") +
        labs(
          title = paste(res$model_choice, "Actual vs Predicted"),
          x = "Actual Class",
          fill = "Predicted"
        ) +
        theme_minimal(base_size = 19)
    }
  })
  
  output$model_story <- renderText({
    res <- trainedResult()
    
    if (is.null(res)) {
      return("No insights yet. Select a model and update.")
    }
    
    if (res$type == "reg") {
      rmse <- sqrt(
        mean((as.numeric(res$preds) - res$test[[res$response_col]])^2, na.rm = TRUE)
      )
      paste0("Regression RMSE: ", round(rmse, 2))
    } else {
      acc <- mean(res$preds == res$test$TargetClass, na.rm = TRUE)
      paste0("Classifier Accuracy: ", round(acc * 100, 1), "%")
    }
  })
  
  output$debug_error <- renderText({
    err <- errorMsg()
    if (is.null(err) || err == "") {
      "No errors"
    } else {
      err
    }
  })
}
