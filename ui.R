ui <- fluidPage(
  tags$head(tags$style(HTML("
    .card { background-color: #F9FAFB; border-radius: 14px; padding: 26px; margin-bottom: 22px; border: 1px solid #e5e7eb;}
    .section-title { color: #2F3A4F; margin-bottom: 12px;}
    .main-bg { background: #f4f4f7;}
    .big-btn { width:240px; font-size:21px; margin:10px auto 6px auto; display: block;}
    .main-panel { background:white; border-radius:14px; padding:28px 32px 32px 32px; border:1px solid #e5e7eb;}
    .log-box { max-height: 200px; overflow-y: auto; background-color: #ffffff; font-family: monospace; font-size: 13px; border:1px solid #d1d5db; border-radius:7px; padding:10px;}
    .top-row { margin-bottom: 10px; }
    .left-col-inner { padding-right: 10px; border-right: 1px solid #e5e7eb;}
    .right-col-inner { padding-left: 20px;}
  "))),
  
  titlePanel("Student Success Analytics"),
  
  tabsetPanel(
    id = "main_tabs",
    
    tabPanel(
      "About",
      div(class = "main-bg", HTML(aboutContent))
    ),
    
    tabPanel(
      "EDA",
      div(class = "main-bg", HTML(edaContent))
    ),
    
    tabPanel(
      "Tutorial",
      div(class = "main-bg", HTML(tutorialContent))
    ),
    
    tabPanel(
      "App",
      div(
        class = "main-panel",
        
        fluidRow(
          class = "top-row",
          
          column(
            4,
            div(
              class = "left-col-inner",
              h4("Select a model"),
              selectInput(
                "model_choice",
                label = NULL,
                choices = modelChoices,
                width = "100%"
              ),
              actionButton(
                "update_model",
                "Update Model",
                class = "btn-primary big-btn"
              )
            )
          ),
          
          column(
            8,
            div(
              class = "right-col-inner",
              h4("Choose predictors"),
              uiOutput("predictor_selector")
            )
          )
        ),
        
        div(
          class = "card",
          h4(class = "section-title", "System Log:"),
          div(class = "log-box", verbatimTextOutput("log_display"))
        ),
        
        div(class = "card", uiOutput("model_outputs"))
      )
    )
  )
)
