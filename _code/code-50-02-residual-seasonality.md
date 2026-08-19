---
aliases: [50-02-residual-seasonality.R]
tags: [code, generated]
---

# `R/50-02-residual-seasonality.R`

Did any seasonality survive?

> [!info] Generated file
> Mirror of `R/50-02-residual-seasonality.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[50-02-residual-seasonality]]

```r
# 50-02 -- Did any seasonality survive?
source("R/_setup.R"); source("R/_series.R")
suppressMessages(library(seasonal))
S <- vault_series()
g <- function(u, k) if (k %in% names(u)) suppressWarnings(as.numeric(u[[k]])[1]) else NA_real_

# EXERCISE 1: QS before and after, on three series each ------------------
cat(sprintf("%-12s %9s %8s %8s %8s\n", "series", "QS(orig)", "QS(SA)", "QS(irr)", "QS(rsd)"))
for (nm in names(S)) {
  r <- tryCatch({ u <- udg(seas(S[[nm]], x11 = ""))
                  c(g(u,"qsori"), g(u,"qssadj"), g(u,"qsirr"), g(u,"qsrsd")) },
                error = function(e) rep(NA, 4))
  cat(sprintf("%-12s %9.1f %8.2f %8.2f %8.2f\n", nm, r[1], r[2], r[3], r[4]))
}
cat("\nWhere you find leftover seasonality tells you what is wrong:\n")
cat("  in the ADJUSTED series -> the adjustment failed\n")
cat("  in the IRREGULAR       -> seasonality leaking into what should be noise\n")
cat("  in the RESIDUALS       -> the MODEL is wrong; fix that, not the filter\n\n")

# EXERCISE 2: check it yourself rather than trusting a key --------------
m <- seas(AirPassengers, x11 = "")
d11 <- series(m, "d11")
sp <- spec.pgram(diff(log(as.numeric(d11))), spans = c(3,3), taper = 0.1, plot = FALSE)
med <- median(sp$spec)
cat("=== own spectral check on the ADJUSTED AirPassengers ===\n")
for (f in (1:6)/12) {
  i <- which.min(abs(sp$freq - f))
  cat(sprintf("  f = %.4f  power/median = %5.2f %s\n", f, sp$spec[i]/med,
              if (sp$spec[i]/med > 2) " <- PEAK" else ""))
}
u <- udg(m)
cat("\nX-13's formal test : QS(SA) =", u[["qssadj"]][1], " (0 = clean)\n")
cat("X-13's peaks.seas  :", paste(u[["peaks.seas"]], collapse = " "), "\n")
cat("\nThe undocumented peaks.seas key LOOKS alarming, but both the formal test\n")
cat("and our own spectrum say clean. Do not build claims on keys you cannot\n")
cat("find documented -- prefer statistics with a stated null distribution.\n\n")

op <- par(mfrow = c(2, 1), mar = c(4, 4, 2, 1))
for (lab in c("original", "adjusted")) {
  y <- diff(log(as.numeric(if (lab == "original") AirPassengers else d11)))
  s <- spec.pgram(y, spans = c(3,3), taper = 0.1, plot = FALSE)
  plot(s$freq, log(s$spec), type = "l", lwd = 2, xlab = "cycles/month",
       ylab = "log power", main = paste("differenced log", lab))
  abline(v = (1:6)/12, col = "firebrick", lty = 3)
}
par(op)

# EXERCISE 3: force residual seasonality with too slow a filter ---------
cat("=== forcing a failure: a very long seasonal filter on volatile seasonality ===\n")
x <- UKgas                                     # Theta = 0.235, fast-evolving
for (f in c("s3x1", "s3x3", "s3x5", "s3x9")) {
  r <- tryCatch({ u <- udg(seas(x, x11.seasonalma = f, x11 = ""))
                  c(g(u,"qssadj"), g(u,"f3.m07")) }, error = function(e) c(NA, NA))
  cat(sprintf("  %-5s : QS(SA) = %6.2f   M7 = %.2f\n", f, r[1], r[2]))
}
cat("A filter that is too slow cannot track evolving seasonality, and the\n")
cat("leftover shows up as residual seasonality.\n")
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/50-02-residual-seasonality.R")
```

Back to [[50-02-residual-seasonality]] · index: [[code-index]]
