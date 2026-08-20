---
aliases: [50-04-sliding-spans.R]
tags: [code, generated]
---

# `R/50-04-sliding-spans.R`

Sliding spans: is the answer robust to moving the window?

> [!info] Generated file
> Mirror of `R/50-04-sliding-spans.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[50-04-sliding-spans]]

```r
# 50-04 -- Sliding spans: is the answer robust to moving the window?
source("R/_setup.R"); source("R/_series.R")
suppressMessages(library(seasonal))

# X-13 computes this natively via the slidingspans spec.
run_ss <- function(x, label) {
  m <- tryCatch(seas(x, slidingspans = "", x11 = ""), error = function(e) NULL)
  if (is.null(m)) { cat(sprintf("%-14s could not run (series too short?)\n", label)); return(invisible()) }
  u <- udg(m)
  # The percentages live in the s2.* keys, NOT in anything matching "sspan".
  # udg("sspans") is just the string "yes" -- the spec ran, nothing more.
  # s2.a.per = c(n flagged, n tested, percent) for the seasonal factors;
  # s2.d.per is the same for month-to-month changes.
  per <- function(key) {
    if (!key %in% names(u)) return(c(NA, NA, NA))
    suppressWarnings(as.numeric(u[[key]]))
  }
  a <- per("s2.a.per"); d <- per("s2.d.per")
  if (is.na(a[3])) {
    # X-13 does not emit the breakdown for every series. Say so rather than
    # printing a silent NA -- sspans tells you whether the spec even ran.
    st <- if ("sspans" %in% names(u)) u[["sspans"]] else "absent"
    cat(sprintf("%-14s n=%3d  no s2.a.per from X-13 (sspans = %s)\n",
                label, length(x), st))
  } else {
    cat(sprintf("%-14s n=%3d  SF flagged %5.2f%% (%g/%g)   MM changes %5.2f%%   %s\n",
                label, length(x), a[3], a[1], a[2], d[3],
                if (a[3] > 15) "<- FAILS (>15%)" else "ok"))
  }
  invisible(u)
}

cat("=== sliding spans across the catalogue ===\n")
S <- vault_series()
for (nm in names(S)) run_ss(S[[nm]], nm)

cat("\nTRAP: the obvious grep finds the wrong thing.\n")
m <- seas(AirPassengers, slidingspans = "", x11 = "")
u <- udg(m)
cat("  keys matching 'sspan'   :", paste(grep("sspan", names(u), value = TRUE),
      collapse = ", "), "  value:", u[["sspans"]], "\n")
cat("  -> that is just a yes/no that the spec ran. The numbers are here:\n")
for (k in c("s2.a.per", "s2.d.per", "s2.e.per")) {
  if (k %in% names(u))
    cat(sprintf("     %-9s %s\n", k, paste(format(u[[k]]), collapse = "  ")))
}
cat("  read as: n flagged, n tested, percent flagged.\n")
cat("\nNot every series yields s2.a.per: accdeaths reports sspans = 'failed'\n")
cat("(6 years is too short to build 4 spans), and temperature, co2, unemp and\n")
cat("cpi report sspans = 'yes' but emit ssa/sscut/ssdiff instead. That is NOT\n")
cat("the additive-vs-multiplicative split -- co2 and cpi are both log. The rule\n")
cat("X-13 uses here was not established; read out(m) for the printed S 2 tables\n")
cat("when the udg key is missing.\n")

# A hand-rolled version, so the idea is visible ------------------------
cat("\n=== hand-rolled sliding spans (the idea, without X-13) ===\n")
hand_spans <- function(x, span_years = 8, n_span = 4, s = 12) {
  n <- length(x); L <- span_years * s
  if (n < L + (n_span - 1) * s) { cat("  series too short\n"); return(invisible()) }
  starts <- seq(1, by = s, length.out = n_span)
  facs <- matrix(NA, nrow = n, ncol = n_span)
  for (j in seq_len(n_span)) {
    i0 <- starts[j]; i1 <- i0 + L - 1
    z <- ts(as.numeric(x)[i0:i1], start = time(x)[i0], frequency = s)
    f <- tryCatch(as.numeric(series(seas(z, x11 = ""), "d10")), error = function(e) NULL)
    if (!is.null(f)) facs[i0:i1, j] <- f
  }
  covered <- rowSums(!is.na(facs)) >= 2
  rng <- apply(facs[covered, , drop = FALSE], 1,
               function(v) { v <- v[!is.na(v)]; 100 * (max(v) - min(v)) / mean(v) })
  cat(sprintf("  months covered by >=2 spans : %d\n", sum(covered)))
  cat(sprintf("  mean max%% difference        : %.2f%%\n", mean(rng)))
  cat(sprintf("  flagged (>3%%)               : %.1f%% of months\n", 100*mean(rng > 3)))
  cat(sprintf("  VERDICT: %s\n",
              if (mean(rng > 3) > 0.25) "UNSTABLE -- do not publish as is" else "stable"))
  invisible(rng)
}
for (nm in c("airline", "co2", "unemp")) {
  cat(" ", nm, "\n"); hand_spans(S[[nm]])
}
cat("\nThresholds (Findley et al. 1990): flag a month if the seasonal factors\n")
cat("differ by more than 3% across spans; the adjustment is unstable if more\n")
cat("than 25% of months are flagged.\n")
cat("\nNote how much data this needs: four 8-year spans shifted a year each\n")
cat("require 11 years. Short series cannot be assessed -- and short series are\n")
cat("exactly the ones most likely to be unstable.\n")
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/50-04-sliding-spans.R")
```

Back to [[50-04-sliding-spans]] · index: [[code-index]]
