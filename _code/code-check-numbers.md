---
aliases: [check-numbers.R]
tags: [code, generated]
---

# `R/check-numbers.R`

Guard against stale numbers in the notes.

> [!info] Generated file
> Mirror of `R/check-numbers.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> No concept note; this is a shared helper.

````r
# check-numbers.R -- guard against stale numbers in the notes.
#
# The vault's rule is that every number in a note is reproducible by running
# a script. Nothing enforced that, and twice it silently broke: the X-11 d11
# agreement drifted (0.88% -> 0.52%) and every measured number in 50-06 was
# left over from an earlier analysis. This script enforces it.
#
# It runs each numbered script, caches the output under .audit/, then scans
# every note for numbers that look computed (two or more decimal places) and
# reports any that no script produced. Rounding is allowed: a note may print
# 1.14 for a script's 1.137.
#
#   Rscript R/check-numbers.R           # reuse cached output where still valid
#   Rscript R/check-numbers.R --fresh   # re-run every script from scratch
#
# Exit status is 1 if anything is unexplained, so it can gate a commit.
#
# Cache invalidation: a script's output is re-run when that script changes,
# and ALSO when any helper in R/_*.R changes -- the quarterly retrofit to
# _x11.R is exactly the kind of edit that moves numbers in notes that do not
# mention _x11.R at all.

AUDIT_DIR <- ".audit"

# Numbers with >= 2 decimals are almost certainly computed rather than prose.
# The lookbehind keeps us from slicing into version strings and identifiers.
NUM_RE <- "(?<![0-9A-Za-z.])-?[0-9]{1,6}[.][0-9]{2,6}"

# Numbers that are legitimately in the notes but are not script output.
# Keep this list short and give a reason for every entry -- it is the only
# way a wrong number can hide from this check.
ALLOW <- data.frame(
  file  = c("50-diagnostics/50-10-calendar-effects.md",
            "40-seats/40-03-canonical-decomposition.md",
            "_meta/checking-the-vault.md",
            "_meta/checking-the-vault.md",
            "_meta/solutions.md",
            "_meta/solutions.md"),
  value = c("0.00001",
            "0.2977",
            "1.82",
            "1.18",
            "1.111",
            "2.33"),
  why   = c("a significance threshold ('p < 0.00001'), not a measured value",
            "a sum worked in the text (0.2238 + 0.0514 + 0.0225); the three
             addends are each checked against script output",
            "the superseded 50-06 ratio, quoted as the error this check exists
             to catch -- it is meant not to match any script",
            "the superseded 50-06 curvature figure, quoted for the same reason",
            "1/0.9, arithmetic worked in a solution's text",
            "7/3, arithmetic worked in a solution's text"),
  stringsAsFactors = FALSE
)

numbered_scripts <- function() {
  sort(list.files("R", pattern = "^[0-9].*[.]R$", full.names = TRUE))
}

helper_mtime <- function() {
  h <- list.files("R", pattern = "^_.*[.]R$", full.names = TRUE)
  if (!length(h)) return(-Inf)
  max(as.numeric(file.mtime(h)))
}

# Blank every line from a marker matching `pat` up to the next line matching
# `stop_pat`. The stop pattern must be given explicitly: in solutions.md the
# practice block is delimited by "**Practice set.**" and its own answers start
# "**P1.**", so a bold-line stop pattern would end the section immediately.
blank_section <- function(lines, pat, stop_pat = "^#{1,6} ") {
  st <- grep(pat, lines)
  if (!length(st)) return(lines)
  stops <- grep(stop_pat, lines)
  for (s in st) {
    nxt <- stops[stops > s]
    e <- if (length(nxt)) nxt[1] - 1L else length(lines)
    lines[s:e] <- ""
  }
  lines
}

extract_numbers <- function(txt) {
  m <- gregexpr(NUM_RE, txt, perl = TRUE)
  unlist(regmatches(txt, m))
}

note_files <- function() {
  f <- list.files(".", pattern = "[.]md$", recursive = TRUE, full.names = FALSE)
  # _code/ mirrors the scripts, so its numbers are the scripts' own; .obsidian
  # and .trash are the app's, and Welcome.md is Obsidian's stock file.
  # _meta/figure-index.md is generated and quotes make-figures.R verbatim, so
  # its numbers are plotting parameters (margins, colours, line widths), not
  # measurements -- checking them would be checking source code against output.
  f <- f[!grepl("^([.]|_code/|.*[.]trash/)", f) & basename(f) != "Welcome.md"]
  f[f != "_meta/figure-index.md"]
}

run_all <- function(fresh = FALSE) {
  dir.create(AUDIT_DIR, showWarnings = FALSE)
  scripts <- numbered_scripts()
  hm <- helper_mtime()
  n_run <- 0L
  failures <- character(0)
  for (f in scripts) {
    stem <- sub("[.]R$", "", basename(f))
    out  <- file.path(AUDIT_DIR, paste0(stem, ".out"))
    stale <- fresh || !file.exists(out) ||
             as.numeric(file.mtime(out)) < as.numeric(file.mtime(f)) ||
             as.numeric(file.mtime(out)) < hm
    if (!stale) next
    cat(sprintf("  running %-38s ", stem)); utils::flush.console()
    res <- suppressWarnings(system2("Rscript", shQuote(f), stdout = out, stderr = FALSE))
    n_run <- n_run + 1L
    if (identical(res, 0L)) cat("ok\n") else {
      cat(sprintf("EXIT %s\n", res)); failures <- c(failures, stem)
    }
  }
  cat(sprintf("  %d script(s) re-run, %d cached\n", n_run, length(scripts) - n_run))
  if (length(failures))
    cat(sprintf("  !! %d script(s) failed: %s\n", length(failures),
                paste(failures, collapse = ", ")))
  invisible(failures)
}

check_numbers <- function(verbose = TRUE) {
  outs <- list.files(AUDIT_DIR, pattern = "[.]out$", full.names = TRUE)
  if (!length(outs))
    stop("no cached output in ", AUDIT_DIR, "/ -- run run_all() first")

  blob <- unlist(lapply(outs, readLines, warn = FALSE))

  # Inline snippet output counts as script output. Those blocks are executed by
  # R/inline.R and verified by its --check, so a number a note quotes in prose
  # is legitimately reproducible if a snippet in the vault prints it.
  for (rel in note_files()) {
    ln <- readLines(rel, warn = FALSE, encoding = "UTF-8")
    runs <- grep("^<!--\\s*run\\s*-->\\s*$", ln)
    ends <- grep("^<!--\\s*end\\s*-->\\s*$", ln)
    for (s in runs) {
      e <- ends[ends > s]
      if (!length(e)) next
      seg <- ln[s:e[1]]
      tf <- grep("^```text\\s*$", seg)
      cf <- grep("^```\\s*$", seg)
      if (!length(tf)) next
      cl <- cf[cf > tf[1]][1]
      if (!is.na(cl) && cl > tf[1] + 1L)
        blob <- c(blob, seg[(tf[1] + 1L):(cl - 1L)])
    }
  }

  out_nums <- suppressWarnings(as.numeric(extract_numbers(paste(blob, collapse = "\n"))))
  out_nums <- abs(out_nums[is.finite(out_nums)])

  bad <- list()
  n_checked <- 0L
  for (rel in note_files()) {
    lines <- readLines(rel, warn = FALSE, encoding = "UTF-8")
    # Blank out <!-- run --> ... <!-- end --> blocks. Those snippets and their
    # printed output are executed and verified by run_inline(check = TRUE) in
    # R/inline.R -- a stricter test than this one, since it re-runs the code.
    runs <- grep("^<!--\\s*run\\s*-->\\s*$", lines)
    ends <- grep("^<!--\\s*end\\s*-->\\s*$", lines)
    for (s in runs) {
      e <- ends[ends > s]
      if (length(e)) lines[s:e[1]] <- ""
    }
    # Blank out the practice tier. Those exercises and answers are hand-worked
    # arithmetic (0.5^5, 2/sqrt(n), Yule-Walker by hand) and invented scenario
    # values ("suppose t = 1.02") -- neither is derived from the code, so
    # neither can go stale when the code changes, which is what this guard is
    # for. See _meta/checking-the-vault.md: this IS a blind spot, and the guard
    # caught two wrong answers in this tier before the exclusion existed.
    lines <- blank_section(lines, "^## Practice set\\s*$")
    lines <- blank_section(lines, "^\\*\\*Practice set[.]\\*\\*\\s*$")
    for (i in seq_along(lines)) {
      for (s in extract_numbers(lines[i])) {
        n_checked <- n_checked + 1L
        # strip a leading ASCII hyphen; a unicode minus is not part of the match
        v <- suppressWarnings(as.numeric(sub("^-", "", s)))
        if (!is.finite(v)) next
        d <- nchar(sub("^[^.]*[.]", "", s))
        # allow the note to be a correctly rounded version of the script value
        tol <- 0.51 * 10^(-d)
        if (any(abs(out_nums - v) <= tol)) next
        if (any(ALLOW$file == rel & ALLOW$value == sub("^-", "", s))) next
        bad[[length(bad) + 1L]] <- data.frame(
          file = rel, line = i, value = s,
          context = substr(trimws(lines[i]), 1, 90), stringsAsFactors = FALSE)
      }
    }
  }

  res <- if (length(bad)) do.call(rbind, bad) else
    data.frame(file = character(0), line = integer(0),
               value = character(0), context = character(0))

  if (verbose) {
    cat(sprintf("\n  %d computed-looking numbers checked across %d notes\n",
                n_checked, length(note_files())))
    if (!nrow(res)) {
      cat("  every one is reproduced by a script (allowing for rounding).\n")
    } else {
      cat(sprintf("  %d NOT produced by any script:\n\n", nrow(res)))
      for (k in seq_len(nrow(res)))
        cat(sprintf("    %-52s line %-4d %-10s | %s\n",
                    res$file[k], res$line[k], res$value[k], res$context[k]))
      cat("\n  Either the note is stale, or the script should print the number",
          "\n  so a reader can reproduce it. Add a genuine constant to ALLOW",
          "\n  in R/check-numbers.R, with a reason.\n")
    }
  }
  invisible(res)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  cat("== running scripts ==\n")
  failures <- run_all(fresh = "--fresh" %in% args)
  cat("\n== checking notes against their output ==")
  res <- check_numbers()
  quit(status = if (nrow(res) || length(failures)) 1L else 0L)
}
````

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/check-numbers.R")
```

Index: [[code-index]]
