# Shiny app for event registration stored on Google Drive / Google Sheets.
#
# Before running the app, make sure you have authenticated with your Google
# account:
#   library(googledrive)
#   library(googlesheets4)
#   drive_auth()
#   gs4_auth(token = drive_token())
#
# Optionally set a Google Drive folder ID in the environment variable
# EVENT_REGISTRATION_FOLDER_ID so the sheet is created inside a specific
# folder. Otherwise, it will be created in your drive root. If you already
# created a sheet, set EVENT_REGISTRATION_SHEET_NAME to its name to reuse it.
#
# To target the folder "AnmeldungenMarktfruchtforum", run once in R:
#   library(googledrive)
#   folder <- drive_get("AnmeldungenMarktfruchtforum")
#   Sys.setenv(EVENT_REGISTRATION_FOLDER_ID = folder$id)
#
# To persist that setting across sessions, add this line to ~/.Renviron
# (replace the ID with the value from drive_get):
#   EVENT_REGISTRATION_FOLDER_ID=1Abc2D...xyz

library(shiny)
library(googledrive)
library(googlesheets4)
library(tibble)

sheet_name <- Sys.getenv("EVENT_REGISTRATION_SHEET_NAME", unset = "Event registrations")
parent_folder_id <- Sys.getenv("EVENT_REGISTRATION_FOLDER_ID", unset = NA)

if (is.character(parent_folder_id) && parent_folder_id == "") {
  parent_folder_id <- NA
}

ensure_sheet <- function() {
  existing <- suppressMessages(gs4_find(sheet_name, exact = TRUE))

  if (nrow(existing) > 0) {
    return(as_sheets_id(existing))
  }

  empty_registrations <- tibble(
    timestamp = as.POSIXct(character()),
    first_name = character(),
    last_name = character(),
    email = character(),
    event_option = character(),
    dinner = logical()
  )

  created <- if (is.na(parent_folder_id)) {
    gs4_create(sheet_name, sheets = list(registrations = empty_registrations))
  } else {
    gs4_create(
      sheet_name,
      path = as_id(parent_folder_id),
      sheets = list(registrations = empty_registrations)
    )
  }

  created$spreadsheet_id
}

ui <- fluidPage(
  titlePanel("Event and Dinner Registration"),
  sidebarLayout(
    sidebarPanel(
      textInput("first_name", "First name"),
      textInput("last_name", "Last name"),
      textInput("email", "Email address"),
      radioButtons(
        "event_option",
        "Select your event option",
        choices = c(
          "Full event pass" = "full_event",
          "Workshop only" = "workshop_only"
        ),
        inline = TRUE
      ),
      checkboxInput("dinner", "I want to attend the dinner", value = TRUE),
      actionButton("submit", "Register", class = "btn-primary")
    ),
    mainPanel(
      h4("Status"),
      textOutput("status"),
      hr(),
      h4("Recent registrations"),
      tableOutput("recent")
    )
  )
)

server <- function(input, output, session) {
  ssid <- ensure_sheet()

  observeEvent(input$submit, {
    req(input$first_name, input$last_name, input$email, input$event_option)

    new_entry <- tibble(
      timestamp = Sys.time(),
      first_name = input$first_name,
      last_name = input$last_name,
      email = input$email,
      event_option = input$event_option,
      dinner = isTRUE(input$dinner)
    )

    sheet_append(ss = ssid, data = new_entry, sheet = "registrations")

    output$status <- renderText(
      sprintf(
        "Thanks %s, your registration has been saved.",
        input$first_name
      )
    )
  })

  poll_registrations <- reactivePoll(
    intervalMillis = 10000,
    session = session,
    checkFunc = function() {
      drive_ls(as_id(ssid))$updatedTime
    },
    valueFunc = function() {
      suppressMessages(read_sheet(ss = ssid, sheet = "registrations"))
    }
  )

  output$recent <- renderTable({
    registrations <- poll_registrations()
    head(registrations[order(registrations$timestamp, decreasing = TRUE), ], 10)
  })
}

shinyApp(ui = ui, server = server)
