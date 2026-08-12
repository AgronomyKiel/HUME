# Quarto may retain an absolute physical Windows path in a document's
# supporting-files metadata when the project is opened through a mapped drive.
# During a later Q:-based preview, Quarto can incorrectly append that C: path
# to the document directory. Remove only affected generated execution caches;
# Quarto will rebuild them using the current project path.

project_dir <- Sys.getenv("QUARTO_PROJECT_DIR", unset = getwd())
freeze_dir <- file.path(project_dir, ".quarto", "_freeze")

if (!dir.exists(freeze_dir)) {
  quit(save = "no", status = 0)
}

cache_files <- list.files(
  freeze_dir,
  pattern = "\\.json$",
  recursive = TRUE,
  full.names = TRUE
)

affected_cache_dirs <- character()

for (cache_file in cache_files) {
  cache_text <- paste(
    readLines(cache_file, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )
  supporting_match <- regexpr(
    '"supporting"\\s*:\\s*\\[[^]]*\\]',
    cache_text,
    perl = TRUE
  )

  if (supporting_match[1] < 0) {
    next
  }

  supporting_text <- regmatches(cache_text, supporting_match)
  if (grepl('[A-Za-z]:\\\\\\\\', supporting_text, perl = TRUE)) {
    affected_cache_dirs <- c(
      affected_cache_dirs,
      dirname(dirname(cache_file))
    )
  }
}

affected_cache_dirs <- unique(affected_cache_dirs)
if (length(affected_cache_dirs) > 0) {
  unlink(affected_cache_dirs, recursive = TRUE, force = TRUE)
  message(
    "Removed ", length(affected_cache_dirs),
    " Quarto execution cache(s) containing absolute Windows support paths."
  )
}

