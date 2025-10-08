
library(xml2)

fn <- "XML_Delphi_Docu/UPenMonteith.xml"

doc <- read_xml(fn)

# Extract the root node
root_node <- xml_root(doc)
# Extract the first child node
first_child_node <- xml_children(root_node)[[1]]
# Extract the name of the first child node
first_child_name <- xml_name(first_child_node)
# Extract the attributes of the first child node
first_child_attrs <- xml_attrs(first_child_node)

fields <- xml_find_all(doc, ".//field")

fieldnames <- xml_attr(fields, "name")

fieldtypes <- xml_attr(fields, "type")

fielddevnotes <- xml_attr(fields, "devnotes")


devnotes_list <- sapply(fields, function(field) {
  devnote_node <- xml_find_first(field, "./devnotes")
  if (!is.na(devnote_node)) {
    trimws(xml_text(devnote_node))
  } else {
    NA_character_  # If <devnotes> is missing
  }
})

# Create a data frame with the extracted information
df.fields <- data.frame(
  fieldname = fieldnames,
  fieldtype = fieldtypes,
  devnotes = devnotes_list,
  stringsAsFactors = FALSE
)



Ancestors <- xml_find_all(doc, ".//ancestor")
ancestornames <- xml_attr(Ancestors, "name")


Consts <- xml_find_all(doc, ".//const")
constnames <- xml_attr(Consts, "name")
consttypes <- xml_attr(Consts, "type")
constdevnotes <- sapply(Consts, function(const) {
  devnote_node <- xml_find_first(const, "./devnotes")
  if (!is.na(devnote_node)) {
    trimws(xml_text(devnote_node))
  } else {
    NA_character_  # If <devnotes> is missing
  }
})

constvalues <- sapply(Consts, function(const) {
  value_node <- xml_find_first(const, "./value")
  if (!is.na(value_node)) {
    trimws(xml_text(value_node))
  } else {
    NA_character_  # If <value> is missing
  }
})

# Create a data frame with the extracted information
df.consts <- data.frame(
  constname = constnames,
  consttype = consttypes,
  constdevnotes = constdevnotes,
  constvalue = constvalues,
  stringsAsFactors = FALSE
)

Classes <- xml_find_all(doc, ".//class")

classnames <- xml_attr(Classes, "name")


# Find all <class> nodes
classes <- xml_find_all(doc, ".//class")


# Extract <devnotes> content and class names
result <- data.frame(
  class_name = xml_attr(classes, "name"),
  devnotes   = sapply(classes, function(class_node) {
    devnotes_node <- xml_find_first(class_node, "./devnotes")
    if (!is.na(devnotes_node)) trimws(xml_text(devnotes_node)) else NA_character_
  }),
  stringsAsFactors = FALSE
)

result

result <- data.frame(
  class_name = xml_attr(classes, "name"),
  devnotes = sapply(classes, function(class_node) {
    dn <- xml_find_first(class_node, ".//devnotes")  # robust: any descendant
    if (!is.na(dn)) trimws(xml_text(dn)) else NA_character_
  }),
  stringsAsFactors = FALSE
)

classdevnotes <- sapply(Classes, function(Class) {
  devnote_node <- xml_find_first(Classes, "./devnotes")
  if (!is.na(devnote_node)) {
    trimws(xml_text(devnote_node))
  } else {
    NA_character_  # If <devnotes> is missing
  }
})




classes <- xml_find_all(doc, ".//class")

# Extract <devnotes> content and class names
result <- data.frame(
  class_name = xml_attr(classes, "name"),
  devnotes   = sapply(classes, function(class_node) {
    devnotes_node <- xml_find_first(class_node, "./devnotes")
    if (!is.na(devnotes_node)) trimws(xml_text(devnotes_node)) else NA_character_
  }),
  stringsAsFactors = FALSE
)

print(result)



classdevnotes <- sapply(Classes, function(class) {
  devnote_node <- xml_find_first(class, "./devnotes")
  summary <- xml_find_first(class, "./summary")
  if (!is.na(devnote_node)) {
    trimws(xml_text(devnote_node))
  } else {
    NA_character_  # If <devnotes> is missing
  }
})

# Find all <class> nodes
classes <- xml_find_all(doc, ".//class")

result <- data.frame(
  class_name = xml_attr(classes, "name"),
  summary    = sapply(classes, function(class_node) {
    summary_node <- xml_find_first(class_node, "./devnotes/summary")
    if (!is.na(summary_node)) trimws(xml_text(summary_node)) else NA_character_
  }),
  stringsAsFactors = FALSE
)
result