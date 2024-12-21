
## Install package "raster" if necessary and load it
if(!require("raster")) {install.packages("raster")} else
 {library("raster")}

##########################################################################################

## Function Arguments
# start:  First day of simulation (class: Date)
# end:    Last day of simulation (class: Date)
# step:   Step size of simulation (class: Numeric)
# project: Name of Project in file system (class: Character)
# year: Year of Project in file system (class: Character or Numeric)
# variants: Vector of variants (class: Character)
# project.location: Location of the project in file system (class: Character)
# weather.source: Location of the weather file in file system (class: Character)
# template.opt: Location of the template for options in file system (class: Character)
# template.param: Location of the template for parameters in file system (class: Character)
# template.state: Location of the template for states in file system (class: Character)

InitializeHUME <- function(start, end, step = 1, project, year, variants, project.location, weather.source, template.opt = FALSE, template.param = FALSE, template.state = FALSE) {
  
  ## Checks
  if(!file.exists(project.location)) {stop("Error: Project location does not exist!")}
  if(!file.exists(weather.source)) {stop("Error: File with data for weather does not exist!")}
  if(template.opt != FALSE) {if(!file.exists(template.opt)) {stop("Error: File with template for options does not exist!")}}
  if(template.param != FALSE) {if(!file.exists(template.param)) {stop("Error: File with template for parameters does not exist!")}}
  if(template.state != FALSE) {if(!file.exists(template.state)) {stop("Error: File with template for states does not exist!")}}
  if(!is.numeric(step)) {stop("Error: step is not numeric!")}
  if(!is.character(project)) {stop("Error: project is not a character!")}
  if(!(is.character(year) | is.numeric(year))) {stop("Error: year is not a character or numeric!")}
  if(!is.character(variants)) {stop("Error: variants is not a character vector!")}
  if(!is.character(project.location)) {stop("Error: project.location is not of type character!")}
  if(!is.character(weather.source)) {stop("Error: project.location is not of type character!")}
  if(!is.character(template.opt)) {stop("Error: template.opt is not of type character!")}
  if(!is.character(template.param)) {stop("Error: template.param is not of type character!")}
  if(!is.character(template.state)) {stop("Error: template.state is not of type character!")}
  
  ## Eventuelles abwandeln von year in class: Character
  year <- as.character(year)
  
  ## Aendern des Datums von y-m-d in Excel-Nummer
  start.time <- as.numeric(as.Date(start)) + 25569
  end.time <- as.numeric(as.Date(end)) + 25569

  
  ## Ordnerstruktur
  if(file.exists(file.path(project.location, "Data", fsep = "\\"))) {print("Hinweis: Der Data-pfad existiert bereits")} else {dir.create(file.path(project.location, "Data", fsep = "\\"))}
  if(file.exists(file.path(project.location, "INI", fsep = "\\"))) {print("Hinweis: Der INI-pfad existiert bereits")} else {dir.create(file.path(project.location, "INI", year, fsep = "\\"))}
  if(file.exists(file.path(project.location, "Data", project, fsep = "\\"))) {print("Hinweis: Der Measurementspfad zu diesem Projekt existiert bereits")} else {dir.create(file.path(project.location, "Data", project, fsep = "\\"))}
  if(file.exists(file.path(project.location, "Data", project, year, fsep = "\\"))) {print("Hinweis: Das Jahr im Measurementspfad zu diesem Projekt existiert bereits")} else {dir.create(file.path(project.location, "Data", project, year, fsep = "\\"))}
  if(file.exists(file.path(project.location, "INI", project, fsep = "\\"))) {print("Hinweis: Der Inipfad zu diesem Projekt existiert bereits")} else {dir.create(file.path(project.location, "INI", project, fsep = "\\"))}
  if(file.exists(file.path(project.location, "INI", project, year, fsep = "\\"))) {print("Hinweis: Das Jahr im Inipfad zu diesem Projekt existiert bereits")} else {dir.create(file.path(project.location, "INI", project, year, fsep = "\\"))}
  if(file.exists(file.path(project.location, "INI", project, year, "IniFn", fsep = "\\"))) {print("Hinweis: Der IniFN-pfad zu diesem Projekt existiert bereits")} else {dir.create(file.path(project.location, "INI", project, year, "IniFn", fsep = "\\"))}
  if(file.exists(file.path(project.location, "INI", project, year, "Opt", fsep = "\\"))) {print("Hinweis: Der Opt-pfad zu diesem Projekt existiert bereits")} else {dir.create(file.path(project.location, "INI", project, year, "Opt", fsep = "\\"))}
  if(file.exists(file.path(project.location, "INI", project, year, "Param", fsep = "\\"))) {print("Hinweis: Der Param-pfad zu diesem Projekt existiert bereits")} else {dir.create(file.path(project.location, "INI", project, year, "Param", fsep = "\\"))}
  if(file.exists(file.path(project.location, "INI", project, year, "State", fsep = "\\"))) {print("Hinweis: Der State-pfad zu diesem Projekt existiert bereits")} else {dir.create(file.path(project.location, "INI", project, year, "State", fsep = "\\"))}

    
  ## Ini-Files fuer Varianten
  reference.list <- NULL
  
  for(i in seq_along(variants)) {
    
    name <- variants[i]
    
    state.path <- file.path(project.location, "INI", project, year, "State", paste0("State_", project, "_", name, ".ini"), fsep = "\\")
    param.path <- file.path(project.location, "INI", project, year, "Param", paste0("Param_", project, "_", name, ".ini"), fsep = "\\")
    option.path <- file.path(project.location, "INI", project, year, "Opt", paste0("Opt_", project, "_", name, ".ini"), fsep = "\\")
    
    path.ini <- file.path(project.location, "INI", project, year, "IniFN", paste0(project, "_", name, ".ini"), fsep = "\\")
    path.fn <- file.path(project.location, "INI", project, year, "IniFN", paste0(project, "_", name, ".fn"), fsep = "\\")
    
    variant.ini <- paste0("[TimeInit]\n",
                          "Startzeit=", start.time, "\n",
                          "Endzeit=", end.time, "\n",
                          "Timestep=", step, "\n\n",
                          "[FileNames]\n",
                          "StateIniFN=", state.path, "\n",
                          "ParamIniFN=", param.path, "\n",
                          "OptionsIniFN=", option.path, "\n",
                          "WeatherFileFN=", weather.source, "\n\n")
    
    write.table(variant.ini, file = path.ini, quote = FALSE, row.names = FALSE, col.names = FALSE)
    write.table(path.ini, file = path.fn, quote = FALSE, row.names = FALSE, col.names = FALSE)
    
    if(template.opt == FALSE) {write.table("", file = opt.path, quote = FALSE, row.names = FALSE, col.names = FALSE)} else
    {file.copy(template.opt, option.path)}
    
    if(template.param == FALSE) {write.table("", file = param.path, quote = FALSE, row.names = FALSE, col.names = FALSE)} else
    {file.copy(template.param, param.path)}
    
    if(template.state == FALSE) {write.table("", file = state.path, quote = FALSE, row.names = FALSE, col.names = FALSE)} else
    {file.copy(template.state, state.path)}
    
    reference.list <- c(reference.list, path.ini)
    
  }
  
  ## Zentrale fn. Datei
  length_reference <- length(reference.list)
  
  if(length_reference > 1) {
    
    reference.list <- paste(reference.list, collapse = "\n")
    write.table(reference.list, file = file.path(project.location, "INI", project, year, "IniFN", paste0(project, "_", year, ".fn"), fsep = "\\"), quote = FALSE, row.names = FALSE, col.names = FALSE)
  
  }
  
}


##########################################################################################

## Function Arguments
# data: data.frame with measurements, variants and dates
# measurement.variable: Named vector, name is the name in HUME, string is the name in data.frame (class: Character)
# date.variable: Name of the date variable in the data frame, column has to be of type date (class: Character)
# variant.variable: Name of the variant variable in the data frame, column has to be of type character (class: Character)
# project: Name of Project in file system (class: Character)
# year: Year of Project in file system (class: Character or Numeric)
# project.location: Location of the project in file system (class: Character)
# model.documentation: data.frame which contains the Docu_Docu export from HUME


MeasurementToHUME <- function(data, measurement.variable, date.variable, variant.variable, project, year, project.location, model.documentation) {
  
  data <- as.data.frame(data)
  variants <- unique(data[ ,variant.variable])

  ## Checks
  if(!is.character(measurement.variable)) {stop("Error: measurement.variable is not of type character!")}
  if(length(measurement.variable) != 1) {stop("Error: measurement.variable is not of length 1! A valid example is c(LAI = 'Green.Area.Index_m2_m2')")}
  if(length(names(measurement.variable)) != 1) {stop("Error: measurement.variable is not a named vector! A valid example is c(LAI = 'Green.Area.Index_m2_m2')")}
  if(class(data[,date.variable]) != "Date") {stop("Error: date.variable is not of type date!")}
  if(!is.character(variant.variable)) {stop("Error: variant.variable is not of type character!")}
  if(!is.character(project)) {stop("Error: project is not a character!")}
  if(!(is.character(year) | is.numeric(year))) {stop("Error: year is not a character or numeric!")}
  if(!is.character(project.location)) {stop("Error: project.location is not of type character!")}
  
  ## Aendern von NA-Werten in 0
  data[is.na(data)] <- 0
  
  ## Aendern des Datums von y-m-d in Excel-Nummer
  data[,date.variable] <- as.numeric(as.Date(data[,date.variable])) + 25569
  
  ## Lookup des Submodels
  submodel <- model.documentation$Submodel[model.documentation$EntityName == names(measurement.variable)]
  
  
  for(i in seq_along(variants)) {
    
    name <- variants[i]
    
    data_red <- data[data[variant.variable] == name,]
    measurement.data <- data.frame(data_red[, unname(measurement.variable)])
    names(measurement.data) <- names(measurement.variable)
    time.data <- data.frame(Time = data_red[, unname(date.variable)])
    measurement.data <- cbind(time.data, measurement.data)
    
    units <- data.frame(matrix(unname(c("[d]", model.documentation$Units[model.documentation$EntityName == names(measurement.variable)])), ncol = 2), stringsAsFactors = FALSE)
    names(units) <- names(measurement.data)
    measurement.data <- rbind(units, measurement.data)
    
    measurement.path <-  file.path(project.location, "Data", project, year, paste0(project, "_", name, "_", submodel, ".txt"), fsep = "\\") 
    ini.path  <- file.path(project.location, "INI", project, year, "IniFn", paste0(project, "_", name, ".ini"), fsep = "\\") 
    
    new.line <- data.frame(section = "MeasurementFiles", name = submodel, value = measurement.path) 
    existing.ini <- data.frame(readIniFile(filename = ini.path, token = "=", commenttoken = ";", aslist = FALSE), stringsAsFactors = FALSE)
    
    if(!any(existing.ini$section == "MeasurementFiles" & existing.ini$name == submodel & existing.ini$value == measurement.path)) {
      new.ini <- rbind(existing.ini, new.line);
      writeIniFile(new.ini, ini.path)
    }
    
    
    if(file.exists(measurement.path)) { existing.data <- read.table(measurement.path, header = TRUE, stringsAsFactors = FALSE);
    existing.data <- as.data.frame(existing.data);
    new.data <- merge(existing.data, measurement.data, by = "Time", all = TRUE);
    if(any(names(new.data) == paste0(names(measurement.data)[-1], ".x"))) {new.data[,names(new.data) == paste0(names(measurement.data)[-1], ".x")] <- NULL};
    names(new.data)[names(new.data) == paste0(names(measurement.data)[-1], ".y")] <- names(measurement.data)[-1];
    new.data[is.na(new.data)] <- 0
    write.table(new.data, file = measurement.path, quote = FALSE, row.names = FALSE)
    } else {write.table(measurement.data, file = measurement.path, quote = FALSE, row.names = FALSE)}
    
  }
  
}

##########################################################################################

## All Credits to Wiebke Weymann

writeIniFile <- function(x, file = ""){   #arg: needs matrix!! of Form 
  submodels <- levels(as.factor(x[,1]))
  print(length(submodels))
  for(i in 1:length(submodels)){
    print(submodels[i])
    if(i == 1){
      cat(paste("[",submodels[i],"]", sep = ""),eol = "\n", file = file)
    }else{
      cat("\n", file = file, append = TRUE)
      cat(paste("[",submodels[i],"]", sep = ""),eol = "\n", file = file, append = TRUE)
    }
    write.table(paste(x[x[ ,1] == submodels[i] , 2], 
                      x[x[ ,1] == submodels[i] , 3], sep = "="),
                file = file, sep = "", 
                row.names = FALSE, col.names = FALSE, quote = FALSE, append = TRUE)
  }
} # WriteIniFile

##########################################################################################



















################## Not Working #########################

# InputToHUME <- function(date, input.value, input.variable, variants, trial, year, inifn.path, override = FALSE) {
#   
#   date <- as.numeric(as.Date(date)) + 25569
#   input <- cbind(date, input.value)
#   grid <- expand.grid(date = date, input.variable = input.variable)
#   grid <- merge(grid, input)
#   names(grid) <- c("section", "name", "value")
#   
#   ## Ordnerstruktur
#   if(file.exists(file.path(inifn.path, trial, fsep = "\\"))) {print("Hinweis: Der Initialisierungspfad zu diesem Projekt existiert bereits")} else {dir.create(file.path(inifn.path, trial, fsep = "\\"))}
#   if(file.exists(file.path(inifn.path, trial, year, fsep = "\\"))) {print("Hinweis: Der Initialisierungspfad zu diesem Projekt und year existiert bereits")} else {dir.create(file.path(inifn.path, trial, year, fsep = "\\"))}
#   if(file.exists(file.path(inifn.path, trial, year, "State", fsep = "\\"))) {print("Hinweis: Der Initialisierungspfad zu diesem Projekt und Modelljahr und State existiert bereits")} else {dir.create(file.path(inifn.path, trial, year, "State", fsep = "\\"))}
#   
#   for(i in 1:nrow(variants)) {
#     
#     name <- NULL
#     
#     for(j in 1:ncol(variants)) {
#       
#       name <- if(j == 1) {paste(names(variants)[j], variants[i,j], sep = "")} else {paste(name, paste(names(variants)[j], variants[i,j], sep = ""), sep = "_")}
#       
#       path <- paste0(file.path(inifn.path, trial, year, fsep = "\\"), "\\", "IniFn\\", trial, "_", name, "_Input.ini")
#       
#       if(file.exists(path) & !override) { existing.input <- data.frame(readIniFile(filename = path, token = "=", commenttoken = ";", aslist = FALSE), stringsAsFactors = FALSE);
#       updated.input <- rbind(existing.input, grid);
#       writeIniFile(x = updated.input, file = path)}
#       
#       if(!file.exists(path) | override) {writeIniFile(x = grid, file = path)}
#       
#     }}
#   
# }
# 
# ##########################################################################################
# 
# StateToHUME <- function(date, input.value, input.variable, variants, project, year, project.location) {
#   
#   ## Checks
#   if(length(date) != length(input.value)) {stop("Error: Vectors for date and input.value don't have the same length!")}
#   
#   ## Aufspannen der Varianten
#   variants <- data.frame(expand.grid(variants, stringsAsFactors = FALSE))
#   
#   date <- strftime(as.Date(date), format = "%d.%m.%Y")
#   input <- cbind(date, input.value)
#   grid <- expand.grid(input.variable = input.variable, date = date)
#   grid <- merge(grid, input)
#   names(grid) <- c("name", "section", "value")
#   grid <- data.frame(section = grid$section, name = grid$name, value = grid$value)
#   date.input <- data.frame(date, input.value)
#   
#   for(i in 1:nrow(variants)) {
#     
#     name <- NULL
#     
#     for(j in 1:ncol(variants)) {
#       
#       name <- if(j == 1) {paste(names(variants)[j], variants[i,j], sep = "")} else {paste(name, paste(names(variants)[j], variants[i,j], sep = ""), sep = "_")}
#       
#       path <- paste0(file.path(project.location, project, fsep = "\\"), "\\Ini\\", year, "\\State\\", "State_", project, "_", name, ".ini")
#       
#       existing.input <- data.frame(readIniFile(filename = path, token = "=", commenttoken = ";", aslist = FALSE), stringsAsFactors = FALSE);
#       
#       for(date.act in date) {
#         
#         if(nrow(existing.input[existing.input$section == input.variable & existing.input$name == date.act,]) > 0) {existing.input$value[existing.input$section == input.variable & existing.input$name == date.act] <- date.input$input.value[date.input$date == date.act]}
#         if(nrow(existing.input[existing.input$section == input.variable & existing.input$name == date.act,]) == 0) {existing.input <- rbind(existing.input, grid[grid$name == date.act,])}
#       }
#       
#       writeIniFile(x = existing.input, file = path)}
#     
#   }
# }
# 
# ##########################################################################################