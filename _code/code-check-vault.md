---
aliases: [check-vault.R]
tags: [code, generated]
---

# `R/check-vault.R`

Every staleness check in the vault, one command.

> [!info] Generated file
> Mirror of `R/check-vault.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> No concept note; this is a shared helper.

```r
# check-vault.R -- every staleness check in the vault, one command.
#
#   Rscript R/check-vault.R           # all checks, using cached script output
#   Rscript R/check-vault.R --fresh   # re-run all 48 scripts first (~10 min)
#
# Exits 1 if anything is stale, so it can gate a commit.
#
# The vault has four things that can silently drift apart, and every one of
# them has drifted at least once:
#
#   numbers    a note quotes a figure no script produces      (50-06: all of them)
#   mirrors    _code/ no longer matches R/                    (fence bug)
#   figures    the appendix no longer matches make-figures.R
#   inline     a snippet's printed output is not what it prints now
#
# Reading cannot catch any of these. That is the whole argument for the file.

pass <- character(0); fail <- character(0)

report <- function(label, ok, detail = "") {
  cat(sprintf("  %-10s %s%s\n", label, if (ok) "OK" else "STALE",
              if (nzchar(detail)) paste0("  -- ", detail) else ""))
  if (ok) pass <<- c(pass, label) else fail <<- c(fail, label)
}

args  <- commandArgs(trailingOnly = TRUE)
fresh <- "--fresh" %in% args

cat("== vault checks ==\n")

# 1. numbers in notes vs fresh script output --------------------------------
suppressWarnings(source("R/check-numbers.R"))
invisible(utils::capture.output(failed <- run_all(fresh = fresh)))
if (length(failed)) {
  report("scripts", FALSE, sprintf("%d script(s) errored: %s",
                                   length(failed), paste(failed, collapse = ", ")))
} else {
  report("scripts", TRUE, sprintf("%d ran clean", length(numbered_scripts())))
}

bad <- utils::capture.output(res <- check_numbers(verbose = FALSE))
report("numbers", nrow(res) == 0L,
       if (nrow(res)) sprintf("%d unreproducible: %s", nrow(res),
                              paste(unique(res$file), collapse = ", ")) else "")

# 2. code mirrors ------------------------------------------------------------
suppressWarnings(source("R/make-code-notes.R"))
drift <- utils::capture.output(d <- check_code_notes())
report("mirrors", length(d) == 0L, if (length(d)) paste(d, collapse = ", ") else "")

# 3. figure appendix ---------------------------------------------------------
suppressWarnings(source("R/make-figure-index.R"))
fi <- utils::capture.output(f <- check_figure_index())
report("figures", length(f) == 0L, if (length(f)) "run R/make-figure-index.R" else "")

# 4. inline snippet output ---------------------------------------------------
suppressWarnings(source("R/inline.R"))
il <- utils::capture.output(stale <- run_inline(check = TRUE))
report("inline", length(stale) == 0L,
       if (length(stale)) paste(stale, collapse = ", ") else "")

cat("\n")
if (length(fail)) {
  cat(sprintf("FAILED: %s\n", paste(fail, collapse = ", ")))
  cat("Fix with:  Rscript R/check-numbers.R   (see which numbers)\n")
  cat("           Rscript R/make-code-notes.R\n")
  cat("           Rscript R/make-figure-index.R\n")
  cat("           Rscript R/inline.R          (refresh snippet output)\n")
  quit(status = 1L)
}
cat("all checks pass\n")
quit(status = 0L)
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/check-vault.R")
```

Index: [[code-index]]
