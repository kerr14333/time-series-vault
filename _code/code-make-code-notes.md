---
aliases: [make-code-notes.R]
tags: [code, generated]
---

# `R/make-code-notes.R`

Mirror every R/*.R script into a readable note in _code/.

> [!info] Generated file
> Mirror of `R/make-code-notes.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> No concept note; this is a shared helper.

```r
# make-code-notes.R -- mirror every R/*.R script into a readable note in _code/.
#
# The scripts in R/ stay the single source of truth. These notes are GENERATED,
# so they can be read inside Obsidian (with syntax highlighting) and on GitHub
# without leaving the vault. Never edit _code/*.md by hand -- edit R/*.R and
# re-run this.
#
#   Rscript R/make-code-notes.R                          # regenerate
#   source("R/make-code-notes.R"); make_code_notes()     # same, interactively
#   source("R/make-code-notes.R"); check_code_notes()    # report drift only

CODE_DIR <- "_code"

.script_files <- function() sort(list.files("R", pattern = "[.][Rr]$", full.names = TRUE))

# Every note stem in the vault, so a script can link back to its concept note.
.note_stems <- function() {
  f <- list.files(".", pattern = "[.]md$", recursive = TRUE)
  f <- f[!grepl("^(\\.obsidian|_code)/", f)]
  tools::file_path_sans_ext(basename(f))
}

.first_comment <- function(lines) {
  hdr <- character(0)
  for (l in lines) {
    if (grepl("^\\s*#", l)) hdr <- c(hdr, sub("^\\s*#+\\s?", "", l)) else break
  }
  hdr <- hdr[nzchar(trimws(hdr))]
  if (!length(hdr)) return("")
  # drop a leading "filename.R -- " or "10-01 -- " prefix if present
  d <- sub("^[A-Za-z0-9_.-]+[.][Rr]\\s*--\\s*", "", hdr[1])
  d <- sub("^[0-9]{2}-[0-9]{2}\\s*--\\s*", "", d)
  sub("^(.)", "\\U\\1", d, perl = TRUE)
}

.render_one <- function(path, stems) {
  lines <- readLines(path, warn = FALSE)
  stem  <- tools::file_path_sans_ext(basename(path))
  desc  <- .first_comment(lines)
  linked <- stem %in% stems

  out <- c(
    "---",
    sprintf("aliases: [%s.R]", stem),
    "tags: [code, generated]",
    "---",
    "",
    sprintf("# `R/%s.R`", stem),
    "",
    if (nzchar(desc)) desc else "(no description in the script header)",
    "",
    "> [!info] Generated file",
    sprintf("> Mirror of `R/%s.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.", stem),
    if (linked) sprintf("> Concept note: [[%s]]", stem) else "> No concept note; this is a shared helper.",
    "",
    "```r",
    lines,
    "```",
    "",
    "## Run it",
    "",
    "```r",
    'setwd("D:/time-series-vault/time-series-vault")',
    sprintf('source("R/%s.R")', stem),
    "```",
    "",
    if (linked) sprintf("Back to [[%s]] · index: [[code-index]]", stem)
    else "Index: [[code-index]]"
  )
  out[!vapply(out, is.null, logical(1))]
}

.render_index <- function(files, stems) {
  rows <- vapply(files, function(p) {
    stem <- tools::file_path_sans_ext(basename(p))
    n    <- length(readLines(p, warn = FALSE))
    desc <- .first_comment(readLines(p, warn = FALSE))
    note <- if (stem %in% stems) sprintf("[[%s]]", stem) else "—"
    sprintf("| [[code-%s\\|`%s.R`]] | %s | %d | %s |", stem, stem, desc, n, note)
  }, character(1))

  c("---",
    "aliases: [Code index, Scripts]",
    "tags: [code, generated, moc]",
    "---",
    "",
    "# Code index",
    "",
    "Every script in `R/`, mirrored here so it is readable inside Obsidian with syntax highlighting. The scripts themselves remain the source of truth.",
    "",
    "> [!info] Generated",
    "> Produced by `R/make-code-notes.R`. Edit the scripts, not these notes.",
    "",
    "| Script | What it does | Lines | Concept note |",
    "|---|---|---|---|",
    rows,
    "",
    "## Regenerating",
    "",
    "```r",
    'setwd("D:/time-series-vault/time-series-vault")',
    'source("R/make-code-notes.R")   # defines the functions',
    'make_code_notes()               # rewrite _code/',
    'check_code_notes()              # or: just report which notes drifted',
    "```",
    "",
    "Running the file directly (`Rscript R/make-code-notes.R`) regenerates immediately. Sourcing it interactively only defines the functions, so `check_code_notes()` can actually detect drift instead of silently repairing it first.",
    "",
    "Shared helpers `_setup.R` (polynomial and sign-convention utilities) and `_x11.R` (the hand-coded X-11) have no concept note of their own — they are sourced by the others.")
}

make_code_notes <- function(verbose = TRUE) {
  dir.create(CODE_DIR, showWarnings = FALSE)
  files <- .script_files()
  stems <- .note_stems()

  for (p in files) {
    stem <- tools::file_path_sans_ext(basename(p))
    writeLines(.render_one(p, stems), file.path(CODE_DIR, paste0("code-", stem, ".md")), useBytes = TRUE)
  }
  writeLines(.render_index(files, stems), file.path(CODE_DIR, "code-index.md"), useBytes = TRUE)

  # remove notes whose script is gone
  want <- c(paste0("code-", tools::file_path_sans_ext(basename(files)), ".md"), "code-index.md")
  have <- list.files(CODE_DIR, pattern = "[.]md$")
  for (f in setdiff(have, want)) {
    file.remove(file.path(CODE_DIR, f))
    if (verbose) cat("removed stale", f, "\n")
  }
  if (verbose) cat(sprintf("wrote %d code notes + index to %s/\n", length(files), CODE_DIR))
  invisible(files)
}

# Report which generated notes no longer match their script.
check_code_notes <- function() {
  files <- .script_files(); stems <- .note_stems(); drift <- character(0)
  for (p in files) {
    stem <- tools::file_path_sans_ext(basename(p))
    f    <- file.path(CODE_DIR, paste0("code-", stem, ".md"))
    if (!file.exists(f)) { drift <- c(drift, paste(stem, "(missing)")); next }
    if (!identical(readLines(f, warn = FALSE), .render_one(p, stems)))
      drift <- c(drift, stem)
  }
  if (length(drift)) {
    cat("OUT OF DATE:\n"); cat(paste0("  ", drift, collapse = "\n"), "\n")
    cat("run make_code_notes() to refresh\n")
  } else cat("all code notes match their scripts\n")
  invisible(drift)
}

# Run as a file (Rscript R/make-code-notes.R) -> regenerate.
# source()d -> only define the functions. sys.nframe() is 0 at top level and
# nonzero inside source(), which is what separates the two cases; interactive()
# does not, because `Rscript -e 'source(...)'` is non-interactive too.
# Without this, check_code_notes() could never report drift: sourcing the file
# would have silently repaired it first.
if (sys.nframe() == 0L) make_code_notes()
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/make-code-notes.R")
```

Index: [[code-index]]
