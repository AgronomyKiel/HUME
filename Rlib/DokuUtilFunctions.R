

GetFirstDevNotes <- function(XMLFilename) {
  # 2. Locate the TDevelopment class using XPath
  doc <- xml2::read_xml(XMLFilename)

  devnotes <- xml_find_first(doc, "devnotes")

    if (length(devnotes) > 0) {
      # 3. Convert content to Markdown and cat() it to the document
      md_output <- xml_to_markdown(devnotes)
      cat(trimws(md_output))
    } else {
      cat("No <devnotes> found")
    }
}


GetClassDevNotes <- function(ClassName, XMLFilename) {
  # 2. Locate the TDevelopment class using XPath
  doc <- xml2::read_xml(XMLFilename)
  target_class <- xml_find_first(doc, paste0(".//class[@name='", ClassName, "']"))

  if (length(target_class) > 0) {
    devnotes <- xml_find_first(target_class, "devnotes")

    if (length(devnotes) > 0) {
      # 3. Convert content to Markdown and cat() it to the document
      md_output <- xml_to_markdown(devnotes)
      cat(trimws(md_output))
    } else {
      cat("No <devnotes> found for TSoilWaterModelR")
    }
  } else {
    cat(paste0("Class ", ClassName, " not found in the XML."))
  }
}



# Recursive function to convert XML nodes to Markdown
xml_to_markdown <- function(node) {
  parts <- character()

  # xml_contents returns both element nodes and text nodes
  nodes <- xml_contents(node)

  for (n in nodes) {
    if (xml_type(n) == "element") {
      tag <- xml_name(n)

      if (tag == "para") {
        parts <- c(parts, "\n\n", xml_to_markdown(n))
      } else if (tag == "b") {
        parts <- c(parts, "**", xml_to_markdown(n), "**")
      } else if (tag == "list") {
        parts <- c(parts, "\n", xml_to_markdown(n))
      } else if (tag == "item") {
        # Check if there is a <description> child, otherwise use item text
        desc <- xml_find_first(n, ".//description")
        if (length(desc) > 0) {
          parts <- c(parts, "\n- ", xml_to_markdown(desc))
        } else {
          parts <- c(parts, "\n- ", xml_to_markdown(n))
        }
      } else if (tag == "description") {
        parts <- c(parts, xml_to_markdown(n))
      } else {
        # Default for summary or unknown tags: just process children
        parts <- c(parts, xml_to_markdown(n))
      }
    } else if (xml_type(n) == "text") {
      # Add text nodes directly
      parts <- c(parts, xml_text(n))
    }
  }

  return(paste(parts, collapse = ""))
}





#' Title
#'
#' @param XMLFile File path to the XML documentation file
#' @param ClassName Name of the class for which to retrieve ancestor classes
#'
#' @returns a data frame with two columns: 'AncestorClass' and 'Namespace', listing all ancestor classes of the specified class along with their namespaces.
#' @export
#'
#' @examples
GetAncestorClasses <- function(XMLFile, ClassName) {


  # 1. Load the XML file
  doc <- read_xml(XMLFile)

  # 2. Locate the specific class node for 'TLayeredSoil'
  class_node <- xml_find_first(doc, paste0("//class[@name='",ClassName,"']"))

  # 3. Find all nested ancestor nodes descending from this class
  ancestor_nodes <- xml_find_all(class_node, ".//ancestor")

  # 4. Extract the 'name' and 'namespace' attributes into a data frame
  ancestors_df <- data.frame(
    AncestorClass = xml_attr(ancestor_nodes, "name"),
    Namespace = xml_attr(ancestor_nodes, "namespace"),
    stringsAsFactors = FALSE
  )
return(ancestors_df)
}

