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
#
# The percentages live in the s2.* keys of udg(). WHICH key, and whether any
# key appears at all, depends on three gates inside X-13 -- see the section
# "why the percentage summary is sometimes absent" below.
ss_stat <- function(u) {
  # seasonal factors for a multiplicative run; implied adjustment factors for
  # an additive run that has been asked to report percentages.
  for (k in c("s2.a.per", "s2.c.per"))
    if (k %in% names(u)) return(list(key = k, v = suppressWarnings(as.numeric(u[[k]]))))
  list(key = NA_character_, v = c(NA, NA, NA))
}

run_ss <- function(x, label) {
  m <- tryCatch(seas(x, slidingspans = "", x11 = ""), error = function(e) NULL)
  if (is.null(m)) { cat(sprintf("%-14s could not run (series too short?)\n", label)); return(invisible()) }
  u <- udg(m)
  a <- ss_stat(u)
  d <- if ("s2.d.per" %in% names(u)) suppressWarnings(as.numeric(u[["s2.d.per"]])) else c(NA, NA, NA)
  if (is.na(a$v[3])) {
    st <- if ("sspans" %in% names(u)) u[["sspans"]] else "absent"
    cat(sprintf("%-14s n=%3d  no percentage summary (sspans = %s)\n", label, length(x), st))
  } else {
    cat(sprintf("%-14s n=%3d  %s %5.2f%% (%g/%g)   MM changes %5.2f%%   %s\n",
                label, length(x), a$key, a$v[3], a$v[1], a$v[2], d[3],
                if (a$v[3] > 15) "<- FAILS (>15%)" else "ok"))
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

# ---------------------------------------------------------------------
# Why the key is sometimes missing. Three gates, all in the Census source.
# ---------------------------------------------------------------------
cat("\n=== why the percentage summary is sometimes absent ===\n")
gk <- function(u, k) if (k %in% names(u)) paste(u[[k]], collapse = " ") else "-"
cat(sprintf("%-12s %-14s %-6s %-6s %8s  %s\n",
            "series", "mode", "ssdiff", "s2.pct", "SFrange", "key"))
for (nm in names(S)) {
  m <- tryCatch(seas(S[[nm]], slidingspans = "", x11 = ""), error = function(e) NULL)
  if (is.null(m)) next
  u <- udg(m)
  r <- suppressWarnings(as.numeric(u[["ssran.all"]]))
  r <- if (length(r) == 3) r[3] else NA_real_
  k <- ss_stat(u)$key
  cat(sprintf("%-12s %-14s %-6s %-6s %8s  %s\n", nm, gk(u, "finmode"),
              gk(u, "ssdiff"), gk(u, "s2.pct"),
              if (is.na(r)) "-" else sprintf("%.2f", r),
              if (is.na(k)) "none" else k))
}

cat("\nGATE 1 -- additive adjustment (ssdiff = yes). setssp.f forces Ssdiff to\n")
cat("  FALSE only when the mode is multiplicative; the default is TRUE. So an\n")
cat("  additive run compares spans by DIFFERENCES and no percentage summary is\n")
cat("  computed at all -- s2.pct is not even written. That is temperature and\n")
cat("  unemp, both of which X-13 fits with no transformation.\n")
cat("\nGATE 2 -- the seasonal factors barely move. ssrng.f takes the range\n")
cat("  (max - min) of the mean seasonal factor across all spans, which is the\n")
cat("  third field of ssran.all, and sets Lrange = (range >= 10). Below 10 it\n")
cat("  prints the warning 'Range of seasonal factors is too low for summary\n")
cat("  sliding spans measures to be reliable', writes s2.pct: no, and never\n")
cat("  calls pctrit. That is co2 and cpi. The cutoff is a bare 10 in the\n")
cat("  Fortran -- IF(xran(Ns1).lt.10) -- not a fraction of anything.\n")
cat("\nGATE 3 -- which letter. The five estimates are a = seasonal factors,\n")
cat("  b = trading day factors, c = final SA series, d = month-to-month\n")
cat("  changes, e = year-to-year changes. In an ADDITIVE run the seasonal\n")
cat("  factor slot is replaced by the IMPLIED ADJUSTMENT FACTORS (original\n")
cat("  divided by adjusted -- a ratio, so percentages mean something again),\n")
cat("  and those are reported in slot c. Code that greps only for s2.a.per\n")
cat("  still finds nothing. Demonstrated below.\n")

cat("\n--- gate 2: the cutoff is exactly 10 ---\n")
set.seed(1)
n <- 20 * 12
tr <- 100 * exp(seq(0, 0.4, length.out = n))
sea <- sin(2 * pi * (1:n) / 12) + 0.4 * cos(4 * pi * (1:n) / 12)
sea <- sea / diff(range(sea[1:12]))
eps <- rnorm(n, 0, 0.002)
cat(sprintf("%14s  %8s  %-7s %s\n", "seasonal amp", "SFrange", "s2.pct", "summary"))
for (amp in c(0.06, 0.08, 0.09, 0.10, 0.11)) {
  y <- ts(tr * exp(amp * sea + eps), start = c(1990, 1), frequency = 12)
  mm <- tryCatch(seas(y, slidingspans = "", x11 = "", transform.function = "log",
                      arima.model = "(0 1 1)(0 1 1)", regression.aictest = NULL,
                      outlier = NULL), error = function(e) NULL)
  if (is.null(mm)) next
  uu <- udg(mm)
  rr <- suppressWarnings(as.numeric(uu[["ssran.all"]]))[3]
  cat(sprintf("%13.0f%%  %8.2f  %-7s %s\n", 100 * amp, rr,
              if ("s2.pct" %in% names(uu)) uu[["s2.pct"]] else "-",
              if (is.na(ss_stat(uu)$v[3])) "suppressed" else "printed"))
}
cat("  The flip happens between a range of 9.08 and 10.05. Nothing else about\n")
cat("  these five runs differs: same model, same seed, same noise.\n")

cat("\n--- gate 3: forcing percentages on an additive run ---\n")
for (nm in c("temperature", "unemp")) {
  mm <- seas(S[[nm]], slidingspans.additivesa = "percent", x11 = "")
  uu <- udg(mm)
  a <- ss_stat(uu)
  cat(sprintf("  %-12s ssdiff=%-4s s2.pct=%-4s key=%-9s %5.2f%% flagged (%g/%g)\n",
              nm, gk(uu, "ssdiff"), gk(uu, "s2.pct"), a$key, a$v[3], a$v[1], a$v[2]))
}
cat("  The seasonal factor slot (a) is still empty; the numbers are in c.\n")

cat("\nRecommended limits, printed by X-13 itself (pctrit.f):\n")
cat("  seasonal / implied adjustment factors : 15% too high, 25% much too high\n")
cat("  month-to-month changes                : 35% too high, 40% much too high\n")
cat("  year-to-year changes                  : 10% usually too high\n")
cat("The month-to-month tolerance is LOOSER, not tighter: those changes are\n")
cat("differences of two noisy numbers, so more of them cross 3% by chance.\n")

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
cat("\nThe hand-rolled version happily reports a number for co2 and unemp where\n")
cat("X-13 refuses to. That is not X-13 being unhelpful: for co2 the entire\n")
cat("seasonal swing is smaller than two of the 3% flags, and for unemp the\n")
cat("factors are in persons, so a percentage of them is not meaningful.\n")

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
