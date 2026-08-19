---
aliases: [50-03-m-and-q-statistics.R]
tags: [code, generated]
---

# `R/50-03-m-and-q-statistics.R`

The M and Q statistics, and their limits.

> [!info] Generated file
> Mirror of `R/50-03-m-and-q-statistics.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[50-03-m-and-q-statistics]]

```r
# 50-03 -- The M and Q statistics, and their limits.
source("R/_setup.R"); source("R/_series.R")
suppressMessages(library(seasonal))
S <- vault_series()
S$sunspots <- window(ts(as.numeric(sunspot.month), start = c(1749,1), frequency = 12),
                     start = c(1950,1))
g <- function(u, k) if (k %in% names(u)) suppressWarnings(as.numeric(u[[k]])[1]) else NA_real_

# EXERCISE 1: all eleven, for a good series and a bad one ---------------
cat("=== M1..M11, Q -- AirPassengers vs sunspots ===\n")
mk <- function(x) {
  u <- tryCatch(udg(seas(x, x11 = "")), error = function(e) NULL)
  if (is.null(u)) return(rep(NA, 13))
  c(sapply(sprintf("f3.m%02d", 1:11), function(k) g(u, k)), g(u, "f3.q"), g(u, "f3.qm2"))
}
a <- mk(AirPassengers); b <- mk(S$sunspots)
tab <- data.frame(stat = c(paste0("M", 1:11), "Q", "Q-M2"),
                  airline = round(a, 2), sunspots = round(b, 2))
tab$verdict <- ifelse(is.na(tab$sunspots), "",
                ifelse(tab$sunspots > 1, "sunspots FAILS", ""))
print(tab, row.names = FALSE)
cat("\nEach statistic is scaled so BELOW 1 is acceptable. Q is a weighted\n")
cat("average of the eleven; Q-M2 drops M2, which is unreliable on short series.\n\n")

# The whole catalogue ---------------------------------------------------
cat("=== M7 and Q across the catalogue ===\n")
cat(sprintf("%-12s %7s %7s  %s\n", "series", "M7", "Q", "note"))
for (nm in names(S)) {
  r <- tryCatch({ u <- udg(seas(S[[nm]], x11 = "")); c(g(u,"f3.m07"), g(u,"f3.q")) },
                error = function(e) c(NA, NA))
  cat(sprintf("%-12s %7.2f %7.2f  %s\n", nm, r[1], r[2],
              if (!is.na(r[1]) && r[1] > 1) "FAILS -- do not adjust" else ""))
}
cat("\ncpi has the highest M7 among the genuine series -- and it is also the one\n")
cat("SEATS cannot decompose (40-02). Independent diagnostics converging on the\n")
cat("same awkward series is a sign they measure something real.\n\n")

# EXERCISE 3: does Q pick the filter you would? ------------------------
cat("=== does Q choose the seasonal filter sensibly? ===\n")
for (nm in c("airline", "ukgas")) {
  cat(" ", nm, "\n")
  for (f in c("s3x3", "s3x5", "s3x9")) {
    r <- tryCatch({ u <- udg(seas(S[[nm]], x11.seasonalma = f, x11 = ""))
                    c(g(u,"f3.q"), g(u,"qssadj"), g(u,"f3.m08"), g(u,"f3.m10")) },
                  error = function(e) rep(NA,4))
    cat(sprintf("    %-5s Q = %.2f  QS(SA) = %5.2f  M8 = %.2f  M10 = %.2f\n",
                f, r[1], r[2], r[3], r[4]))
  }
}
cat("\nM8-M11 measure how much the SEASONAL moves, so they reward long filters\n")
cat("even when a long filter is wrong. Q inherits that. Use QS as the check.\n\n")

# EXERCISE 4: SEATS produces no M or Q ---------------------------------
cat("=== SEATS mode: are there M statistics? ===\n")
u <- udg(seas(AirPassengers))
cat("  keys matching 'f3.m':", length(grep("^f3\\.m", names(u))), "\n")
cat("  So you CANNOT compare an X-11 and a SEATS adjustment via Q.\n")
cat("  Comparing methods needs revision history (50-05) or the spectrum.\n")
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/50-03-m-and-q-statistics.R")
```

Back to [[50-03-m-and-q-statistics]] · index: [[code-index]]
