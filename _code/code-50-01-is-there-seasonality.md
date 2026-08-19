---
aliases: [50-01-is-there-seasonality.R]
tags: [code, generated]
---

# `R/50-01-is-there-seasonality.R`

Should this series be adjusted at all?

> [!info] Generated file
> Mirror of `R/50-01-is-there-seasonality.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[50-01-is-there-seasonality]]

```r
# 50-01 -- Should this series be adjusted at all?
source("R/_setup.R"); source("R/_series.R")
suppressMessages(library(seasonal))

S <- vault_series()
# The negative control: monthly sunspots have an ~11-YEAR cycle and no annual
# seasonality. The Sun does not know about the calendar.
S$sunspots <- window(ts(as.numeric(sunspot.month), start = c(1749,1), frequency = 12),
                     start = c(1950,1))

g <- function(u, k) if (k %in% names(u)) suppressWarnings(as.numeric(u[[k]])[1]) else NA_real_

cat(sprintf("%-12s %9s %8s %7s %7s  %s\n", "series", "QS(orig)", "QS(SA)", "M7", "Q", "verdict"))
for (nm in names(S)) {
  r <- tryCatch({ u <- udg(seas(S[[nm]], x11 = ""))
                  c(g(u,"qsori"), g(u,"qssadj"), g(u,"f3.m07"), g(u,"f3.q")) },
                error = function(e) rep(NA, 4))
  v <- if (is.na(r[3])) "" else if (r[3] > 1) "M7 > 1: DO NOT ADJUST" else "seasonal"
  cat(sprintf("%-12s %9.1f %8.2f %7.2f %7.2f  %s\n", nm, r[1], r[2], r[3], r[4], v))
}
cat("\nQS is chi-square(2): above ~9 is significant at 1%. M7 > 1 means\n")
cat("identifiable seasonality is doubtful. sunspots fails both.\n\n")

# EXERCISE 3: the spectrum tells the same story --------------------------
op <- par(mfrow = c(2, 1), mar = c(4, 4, 2, 1))
for (nm in c("airline", "sunspots")) {
  x <- S[[nm]]
  sp <- spec.pgram(diff(as.numeric(x)), spans = c(5,5), taper = 0.1, plot = FALSE)
  plot(sp$freq, log(sp$spec), type = "l", lwd = 2, xlab = "cycles/month",
       ylab = "log power", main = paste(nm, "-- differenced"))
  abline(v = (1:6)/12, col = "firebrick", lty = 3)
}
par(op)

ss <- S$sunspots
sp <- spec.pgram(diff(as.numeric(ss)), spans = c(5,5), taper = 0.1, plot = FALSE)
cat("sunspots: power at the seasonal frequencies, relative to the median\n")
for (f in (1:6)/12) {
  i <- which.min(abs(sp$freq - f))
  cat(sprintf("  f = %.4f : %.2fx median %s\n", f, sp$spec[i]/median(sp$spec),
              if (sp$spec[i]/median(sp$spec) > 2) "<- peak" else ""))
}
cat("Nothing. At the annual frequency there is LESS power than typical.\n\n")

# EXERCISE 2: SEATS refuses; X-11 does not -------------------------------
cat("=== SEATS mode on a non-seasonal series ===\n")
r <- tryCatch({ seas(ss); "succeeded" },
              error = function(e) paste("FAILED:", substr(conditionMessage(e), 1, 90)))
cat("  ", r, "\n")
cat("=== X-11 mode on the same series ===\n")
r2 <- tryCatch({ m <- seas(ss, x11 = ""); "succeeded -- produced factors regardless" },
               error = function(e) "failed")
cat("  ", r2, "\n")
cat("\nThe model-based method fails LOUDLY; the filter-based one fails SILENTLY.\n")
cat("X-11 is a fixed recipe with no notion of whether the exercise makes sense.\n\n")

# EXERCISE 4: adjusting noise makes it WORSE -----------------------------
set.seed(9)
cat("=== what does adjusting pure noise cost? ===\n")
res <- replicate(20, {
  w <- ts(100 + cumsum(rnorm(180, sd = 0.5)), frequency = 12)
  a <- tryCatch(as.numeric(series(seas(w, x11 = ""), "d11")), error = function(e) NULL)
  if (is.null(a)) return(NA)
  sd(diff(a)) / sd(diff(as.numeric(w)))
})
cat(sprintf("  sd of month-to-month change, adjusted / original: %.3f (median of %d runs)\n",
            median(res, na.rm = TRUE), sum(!is.na(res))))
cat("  Above 1 means the 'adjustment' ADDED volatility that was never there.\n")
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/50-01-is-there-seasonality.R")
```

Back to [[50-01-is-there-seasonality]] · index: [[code-index]]
