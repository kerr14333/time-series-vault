# inline.R -- run the R snippets embedded in the notes and fill in their output.
#
# The vault's rule is that no number is transcribed by hand. That applies to
# worked examples inside the notes too: a snippet whose output was pasted in
# is stale the moment the code around it changes, and nothing would catch it.
#
# So a note marks an example like this:
#
#   <!-- run -->
#   ```r
#   poly_show(diff_poly(1, 1, 12))
#   ```
#   ```text
#   (filled in automatically)
#   ```
#   <!-- end -->
#
# and this script executes every snippet and rewrites the text block with the
# real output. The HTML comments are invisible in Obsidian's reading view.
#
#   Rscript R/inline.R          # run every snippet, rewrite outputs
#   Rscript R/inline.R --check  # fail if any output is stale (exit 1)
#
# All snippets in one note share an environment and run top to bottom, so a
# later snippet can use a variable an earlier one defined. Each note starts
# fresh, with R/_setup.R and the other helpers already sourced -- that is
# where `lap` (log AirPassengers) and the polynomial helpers come from.

MAX_OUT <- 24L          # lines of output kept per snippet; longer is truncated

note_files <- function() {
  f <- list.files(".", pattern = "[.]md$", recursive = TRUE)
  f <- f[!grepl("^([.]|_code/|.*[.]trash/)", f) & basename(f) != "Welcome.md"]
  f[f != "_meta/figure-index.md"]
}

# --- locate the marked blocks in one note -----------------------------------
# returns a list of records: r_start/r_end (code fence body), out_start/out_end
# (the text fence body to replace, or NA if the note has none yet)
inline_blocks <- function(lines) {
  runs <- grep("^<!--\\s*run\\s*-->\\s*$", lines)
  ends <- grep("^<!--\\s*end\\s*-->\\s*$", lines)
  out <- list()
  for (s in runs) {
    e <- ends[ends > s]
    if (!length(e)) stop("unclosed <!-- run --> at line ", s)
    e <- e[1]
    seg <- lines[s:e]
    rf <- grep("^```r\\s*$", seg)
    tf <- grep("^```text\\s*$", seg)
    cf <- grep("^```\\s*$", seg)
    if (!length(rf)) stop("<!-- run --> block at line ", s, " has no ```r fence")
    r_close <- cf[cf > rf[1]][1]
    rec <- list(code = seg[(rf[1] + 1L):(r_close - 1L)],
                r_abs_end = s + r_close - 1L)
    if (length(tf)) {
      t_close <- cf[cf > tf[1]][1]
      rec$out_start <- s + tf[1] - 1L      # the ```text line itself
      rec$out_end   <- s + t_close - 1L    # its closing fence
    } else {
      rec$out_start <- NA_integer_; rec$out_end <- NA_integer_
    }
    out[[length(out) + 1L]] <- rec
  }
  out
}

# --- run one note's snippets, return the rewritten lines ---------------------
render_note <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  blocks <- inline_blocks(lines)
  if (!length(blocks)) return(NULL)

  env <- new.env(parent = globalenv())
  local({
    source("R/_setup.R", local = env)
    source("R/_x11.R", local = env)
    source("R/_spectral.R", local = env)
    source("R/_seats.R", local = env)
    source("R/_series.R", local = env)
  })
  # Module 5 snippets call seas()/udg()/series(); load it once here rather than
  # making every snippet say so.
  suppressMessages(library(seasonal))

  # rewrite from the bottom up so earlier line numbers stay valid
  outs <- vector("list", length(blocks))
  for (i in seq_along(blocks)) {
    code <- paste(blocks[[i]]$code, collapse = "\n")
    txt <- tryCatch(
      utils::capture.output(eval(parse(text = code), envir = env)),
      error = function(e) paste("Error:", conditionMessage(e)),
      warning = function(w) paste("Warning:", conditionMessage(w)))
    if (!length(txt)) txt <- "(no printed output)"
    if (length(txt) > MAX_OUT)
      txt <- c(txt[seq_len(MAX_OUT)], sprintf("... [%d more lines]", length(txt) - MAX_OUT))
    outs[[i]] <- txt
  }

  for (i in rev(seq_along(blocks))) {
    b <- blocks[[i]]
    new <- c("```text", outs[[i]], "```")
    if (is.na(b$out_start)) {
      lines <- append(lines, new, after = b$r_abs_end)
    } else {
      lines <- c(lines[seq_len(b$out_start - 1L)], new,
                 if (b$out_end < length(lines)) lines[(b$out_end + 1L):length(lines)])
    }
  }
  lines
}

run_inline <- function(check = FALSE) {
  changed <- character(0); n_notes <- 0L; n_blocks <- 0L
  for (p in note_files()) {
    before <- readLines(p, warn = FALSE, encoding = "UTF-8")
    if (!length(grep("^<!--\\s*run\\s*-->\\s*$", before))) next
    n_notes <- n_notes + 1L
    n_blocks <- n_blocks + length(grep("^<!--\\s*run\\s*-->\\s*$", before))
    after <- render_note(p)
    if (is.null(after)) next
    if (!identical(before, after)) {
      changed <- c(changed, p)
      if (!check) writeLines(after, p, useBytes = TRUE)
    }
  }
  cat(sprintf("%d inline snippets across %d notes\n", n_blocks, n_notes))
  if (!length(changed)) {
    cat("every snippet's output is current\n")
  } else if (check) {
    cat("STALE OUTPUT in:\n"); cat(paste0("  ", changed, collapse = "\n"), "\n")
  } else {
    cat(sprintf("refreshed %d note(s)\n", length(changed)))
  }
  invisible(changed)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  chk <- "--check" %in% args
  res <- run_inline(check = chk)
  if (chk && length(res)) quit(status = 1L)
}
