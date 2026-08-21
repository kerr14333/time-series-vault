# make-figure-index.R -- generate _meta/figure-index.md, the figure appendix.
#
# Every PNG in the vault is produced by exactly one block of R/make-figures.R,
# between a png_() call and the matching dev.off(). This script pairs each
# figure with the code that made it, and with the notes that embed it, so a
# reader looking at a plot can always get to the lines that drew it.
#
#   Rscript R/make-figure-index.R      # regenerate the appendix
#
# Generated -- never edit _meta/figure-index.md by hand. Edit make-figures.R
# and re-run. check_figure_index() reports drift, the same contract as
# make-code-notes.R.

SRC   <- "R/make-figures.R"
INDEX <- "_meta/figure-index.md"

# --- parse make-figures.R into one record per figure ------------------------
figure_blocks <- function(path = SRC) {
  lines <- readLines(path, warn = FALSE)
  starts <- grep("png_\\(", lines)
  ends   <- grep("^\\s*dev[.]off\\(\\)", lines)
  out <- list()
  for (s in starts) {
    e <- ends[ends > s]
    if (!length(e)) next
    e <- e[1]
    name <- sub('.*png_\\("([^"]+)".*', "\\1", lines[s])
    if (identical(name, lines[s])) next          # no quoted filename, skip
    # nearest preceding section banner, if there is one
    hdr <- grep("^# ---", lines[seq_len(s)])
    section <- if (length(hdr))
      trimws(gsub("^# ---\\s*|\\s*-+$", "", lines[max(hdr)])) else ""
    out[[length(out) + 1L]] <- list(
      name = name, section = section,
      first = s, last = e, code = lines[s:e])
  }
  out
}

# --- which notes embed a given figure ---------------------------------------
note_files <- function() {
  f <- list.files(".", pattern = "[.]md$", recursive = TRUE)
  f[!grepl("^([.]|_code/)", f) & basename(f) != "Welcome.md"]
}

embedders <- function(figs) {
  # exclude the appendix itself: it embeds every figure by construction
  notes <- setdiff(note_files(), INDEX)
  used <- setNames(vector("list", length(figs)), vapply(figs, `[[`, "", "name"))
  for (nf in notes) {
    txt <- paste(readLines(nf, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    for (nm in names(used))
      if (grepl(paste0("![[", nm, "]]"), txt, fixed = TRUE))
        used[[nm]] <- c(used[[nm]], nf)
  }
  used
}

make_figure_index <- function() {
  figs <- figure_blocks()
  used <- embedders(figs)
  on_disk <- list.files("figures", pattern = "[.]png$")

  L <- c(
    "---",
    "aliases: [Figure index, Figures, Appendix]",
    "tags: [meta, generated, appendix]",
    "---",
    "",
    "# Appendix: every figure, and the code that made it",
    "",
    paste0("**Generated** by `R/make-figure-index.R` — do not edit by hand. ",
           "Every PNG in the vault comes from exactly one block of ",
           "[[code-make-figures|`R/make-figures.R`]], between a `png_()` call and its ",
           "`dev.off()`. Regenerate the images with `Rscript R/make-figures.R`, then ",
           "this page with `Rscript R/make-figure-index.R`."),
    "",
    sprintf("%d figures, all produced by one script.", length(figs)),
    "")

  # contents table
  L <- c(L, "| Figure | Appears in | Lines in `make-figures.R` |", "|---|---|---|")
  for (f in figs) {
    u <- used[[f$name]]
    links <- if (length(u))
      paste(sprintf("[[%s]]", tools::file_path_sans_ext(basename(u))), collapse = ", ")
    else "**not embedded anywhere**"
    L <- c(L, sprintf("| [[#%s]] | %s | %d–%d |", f$name, links, f$first, f$last))
  }
  L <- c(L, "")

  # orphan checks, stated rather than hidden
  drawn <- vapply(figs, `[[`, "", "name")
  orphan_file <- setdiff(on_disk, drawn)
  never_used  <- drawn[vapply(drawn, function(n) is.null(used[[n]]), logical(1))]
  if (length(orphan_file) || length(never_used)) {
    L <- c(L, "> [!warning] Loose ends", "")
    if (length(orphan_file))
      L <- c(L, sprintf("> - in `figures/` but not drawn by `make-figures.R`: %s",
                        paste0("`", orphan_file, "`", collapse = ", ")))
    if (length(never_used))
      L <- c(L, sprintf("> - drawn but embedded in no note: %s",
                        paste0("`", never_used, "`", collapse = ", ")))
    L <- c(L, "")
  }

  for (f in figs) {
    u <- used[[f$name]]
    L <- c(L, "---", "", paste0("## ", f$name), "")
    if (nzchar(f$section)) L <- c(L, paste0("*", f$section, "*"), "")
    L <- c(L, paste0("![[", f$name, "]]"), "")
    L <- c(L, if (length(u))
      paste0("Embedded in: ",
             paste(sprintf("[[%s]]", tools::file_path_sans_ext(basename(u))), collapse = ", "))
      else "**Embedded in no note.**", "")
    L <- c(L, sprintf("Drawn by `R/make-figures.R`, lines %d–%d:", f$first, f$last),
           "", "```r", f$code, "```", "")
  }

  dir.create("_meta", showWarnings = FALSE)
  writeLines(L, INDEX, useBytes = TRUE)
  cat(sprintf("wrote %s (%d figures)\n", INDEX, length(figs)))
  invisible(INDEX)
}

# --- drift guard, same contract as check_code_notes() -----------------------
check_figure_index <- function() {
  if (!file.exists(INDEX)) { cat("figure index missing\n"); return(INDEX) }
  before <- readLines(INDEX, warn = FALSE)
  tmp <- tempfile(); on.exit(unlink(tmp), add = TRUE)
  file.copy(INDEX, tmp, overwrite = TRUE)
  suppressMessages(capture.output(make_figure_index()))
  after <- readLines(INDEX, warn = FALSE)
  if (identical(before, after)) {
    cat("figure index matches make-figures.R\n"); invisible(character(0))
  } else {
    file.copy(tmp, INDEX, overwrite = TRUE)   # leave the stale file for inspection
    cat("FIGURE INDEX IS STALE -- run Rscript R/make-figure-index.R\n")
    invisible(INDEX)
  }
}

if (sys.nframe() == 0L) make_figure_index()
