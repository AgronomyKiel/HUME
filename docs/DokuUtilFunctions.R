

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