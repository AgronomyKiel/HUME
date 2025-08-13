library(tools)
library(xml2)
library(dplyr)






ExtractXMLDocuInformation <- function(fn_xml_docu, ClassName = "TPenMonteith")  {


  doc <- read_xml(fn_xml_docu)

  # Find the<namespace node
  # this is always the first node in the XML file
  ns_node <- xml_find_first(doc, './/devnotes')

  # Extract relevant devnotes subfields for the markdown text
  # from the namespace node
#  summary_text <- xml_text(xml_find_first(ns_node, ".//summary"))
  summary_text <- paste0("- ", xml_text(xml_find_first(ns_node, ".//summary")), collapse = "\n")
  author_text <- xml_text(xml_find_first(ns_node, ".//author"))
  timestamp_text <- xml_text(xml_find_first(ns_node, ".//Timestamp"))

  # Extract reference items
  references <- xml_find_all(ns_node, ".//References/item")
  reference_list <- paste0("- ", xml_text(references), collapse = "\n")

  # Combine into markdown string
  md_text <- paste0(
    "## Short Info\n",
    summary_text, "\n\n",
    "## Author\n",
    author_text, "\n\n",
    "## Timestamp\n",
    timestamp_text, "\n\n",
    "## Key References\n",
    reference_list, "\n\n"
  )


  # find all class nodes
  classes_nodes <- xml_find_all(doc, ".//class")
  # Extract relevant information into a data frame
  classes_df <- data.frame(
    name = xml_attr(classes_nodes, "name"),
    type = xml_attr(classes_nodes, "type"),
    summary = sapply(classes_nodes, function(node) {
      summary_node <- xml_find_first(node, ".//summary")
      if (!is.na(summary_node)) xml_text(summary_node) else NA_character_
    }),
    value = sapply(classes_nodes, function(node) {
      value_node <- xml_find_first(node, "value")
      if (!is.na(value_node)) xml_text(value_node) else NA_character_
    }),
    stringsAsFactors = FALSE
  )



  # Find the node for the Class of function parameter ClassName

  ClassNoteText <- paste0(".//class[@name='", ClassName,"']")
  class_node <- xml_find_first(doc, ClassNoteText)
  #  class_node <- xml_find_first(doc, ".//class[@name='ClassName']")


  # Traverse all <ancestor> elements recursively
  ancestor_nodes <- xml_find_all(class_node, ".//ancestor")

  # Extract the name attribute of each ancestor
  ancestor_names <- xml_attr(ancestor_nodes, "name")


  # Extract <propertyref> elements of the class
  property_refs <- xml_find_all(class_node, ".//propertyref")

  property_df <- data.frame(
    name       = xml_attr(property_refs, "name"),
    visibility = xml_attr(property_refs, "visibility"),
    stringsAsFactors = FALSE
  )


  # find all nodes for enumeration nodes
  enum_nodes <- xml_find_all(doc, ".//enum")

  # Extract relevant data
  enum_df <- data.frame(
    name = xml_attr(enum_nodes, "name"),
    summary = sapply(enum_nodes, function(node) {
      summary_node <- xml_find_first(node, ".//summary")
      if (!is.na(summary_node)) xml_text(summary_node) else NA_character_
    }),
    elements = sapply(enum_nodes, function(node) {
      elements <- xml_find_all(node, ".//element")
      element_names <- xml_attr(elements, "name")
      paste(element_names, collapse = ", ")
    }),
    stringsAsFactors = FALSE
  )


  # Find all <const> nodes
  const_nodes <- xml_find_all(doc, ".//const")

  # Extract relevant information into a data frame
  const_df <- data.frame(
    name = xml_attr(const_nodes, "name"),
    type = xml_attr(const_nodes, "type"),
    summary = sapply(const_nodes, function(node) {
      summary_node <- xml_find_first(node, ".//summary")
      if (!is.na(summary_node)) xml_text(summary_node) else NA_character_
    }),
    value = sapply(const_nodes, function(node) {
      value_node <- xml_find_first(node, "value")
      if (!is.na(value_node)) xml_text(value_node) else NA_character_
    }),
    stringsAsFactors = FALSE
  )


  # enumeration nodes are also in the const nodes listed
  # they should not show up again
  const_df <- const_df %>% filter(!(type %in% enum_df$name))


  # Get all <function> nodes inside this class
  fun_nodes <- xml_find_all(class_node, ".//function")

  # Build the data frame
  fun_df <- data.frame(
    name = xml_attr(fun_nodes, "name"),
    visibility = xml_attr(fun_nodes, "visibility"),
    parameters = sapply(fun_nodes, function(fn) {
      params <- xml_find_all(fn, ".//parameters/parameter")
      if (length(params) == 0) return("")
      paste(
        sapply(params, function(p) {
          paste0(xml_attr(p, "name"), ": ", xml_attr(p, "type"))
        }),
        collapse = "; "
      )
    }),
    summary = sapply(fun_nodes, function(fn) {
      summary_node <- xml_find_first(fn, ".//devnotes/summary")
      if (!is.na(summary_node)) xml_text(summary_node) else NA_character_
    }),
    ParSummary = sapply(fun_nodes, function(fn) {
      param_nodes <- xml_find_all(fn, ".//devnotes/param")
      if (length(param_nodes) == 0) return("")
      paste(
        sapply(param_nodes, function(p) {
          pname <- xml_attr(p, "name")
          ptext <- xml_text(p)
          paste0(pname, ": ", trimws(ptext))
        }),
        collapse = "; "
      )
    }),
    stringsAsFactors = FALSE
  )


  # Get all <procedure> nodes inside this class
  proc_nodes <- xml_find_all(class_node, ".//procedure")

  # Build the data frame
  proc_df <- data.frame(
    name = xml_attr(proc_nodes, "name"),
    visibility = xml_attr(proc_nodes, "visibility"),
    parameters = sapply(proc_nodes, function(fn) {
      params <- xml_find_all(fn, ".//parameters/parameter")
      if (length(params) == 0) return("")
      paste(
        sapply(params, function(p) {
          paste0(xml_attr(p, "name"), ": ", xml_attr(p, "type"))
        }),
        collapse = "; "
      )
    }),
    summary = sapply(proc_nodes, function(fn) {
      summary_node <- xml_find_first(fn, ".//devnotes/summary")
      if (!is.na(summary_node)) xml_text(summary_node) else NA_character_
    }),
    ParSummary = sapply(proc_nodes, function(fn) {
      param_nodes <- xml_find_all(fn, ".//devnotes/param")
      if (length(param_nodes) == 0) return("")
      paste(
        sapply(param_nodes, function(p) {
          pname <- xml_attr(p, "name")
          ptext <- xml_text(p)
          paste0(pname, ": ", trimws(ptext))
        }),
        collapse = "; "
      )
    }),
    stringsAsFactors = FALSE
  )


  result <- list(
    md_text = md_text,
    classes_df = classes_df,
    ancestor_names = ancestor_names,
    property_df = property_df,
    enum_df = enum_df,
    const_df = const_df,
    fun_df = fun_df,
    proc_df = proc_df
  )

  return(result)

}



ExtractInformationFromCSV <- function(fn) {

  df <- read.delim(fn, header = TRUE, sep = ";")
  df.state <- df %>% filter( EntityType == "State") %>% dplyr::select(EntityName, Units, Value, Comment)
  names(df.state) <- c("State variable", "Units", "InitialValue", "Description")


  df.par <- df %>% filter( EntityType == "Parameter") %>% dplyr::select(EntityName, Units, Value, Comment)
  names(df.par) <- c("Parameter", "Units", "Value", "Description")

  df.var <- df %>% filter( EntityType == "Variable") %>% dplyr::select(EntityName, Units, Comment)
  names(df.var) <- c("Variable", "Units", "Description")

  df.ext <- df %>% filter( EntityType == "ExtVar") %>% dplyr::select(EntityName, Units, Comment, Option)
  names(df.ext) <- c("External variable", "Units", "Description", "Source")

  df.opt <- df %>% filter(EntityType == "Option" ) %>% dplyr::select(EntityName, Units, Comment)
  names(df.opt) <- c("Option", "Units", "Description")

  result <- list(
    df.state = df.state,
    df.par = df.par,
    df.var = df.var,
    df.ext = df.ext,
    df.opt = df.opt
  )

}






