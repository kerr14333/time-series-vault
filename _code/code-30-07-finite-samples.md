---
aliases: [30-07-finite-samples.R]
tags: [code, generated]
---

# `R/30-07-finite-samples.R`

Applying a doubly-infinite filter to 144 observations.

> [!info] Generated file
> Mirror of `R/30-07-finite-samples.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[30-07-finite-samples]]

```r
# 30-07 -- Applying a doubly-infinite filter to 144 observations.
source("R/_setup.R"); source("R/_spectral.R"); source("R/_x11.R")   # gain() lives in _x11.R
set.seed(404)

f <- seq(1e-4, 0.5, length.out = 2000)
nu <- wk_gain(arma_spectrum(ar_poly = c(1, -1), sigma2 = 1, freq = f),
              arma_spectrum(ar_poly = c(1, -1), sigma2 = 1, freq = f) + 4 / (2 * pi))

# EXERCISE 1: how fast do the weights decay? ------------------------------
w <- wk_weights(nu, f, max_lag = 80)
below <- which(abs(w) < 1e-4)[1] - 1
cat("WK weights: w0 =", round(w[1], 5), "  w10 =", signif(w[11], 3),
    "  w40 =", signif(w[41], 3), "\n")
cat("first lag with |w| < 1e-4:", below, "\n")
cat("total (2-sided) weight:", round(w[1] + 2 * sum(w[-1]), 5), "\n")
cat("  -- should be exactly 1 (the gain at frequency 0). It is not, because we\n")
cat("     stopped at lag 80. That shortfall IS the truncation error, and it is\n")
cat("     the whole subject of this note.\n\n")
plot(0:80, abs(w), type = "h", log = "y", lwd = 2, col = "steelblue",
     xlab = "lag", ylab = "|weight| (log)", main = "geometric decay sets the filter's reach")

# EXERCISE 2: truncation, with and without renormalisation ---------------
trunc_gain <- function(w, L, renorm) {
  ww <- w[1:(L + 1)]
  full <- c(rev(ww[-1]), ww)                 # symmetric, 2L+1 terms
  if (renorm) full <- full / sum(full)
  gain(full, f)
}
plot(f, nu, type = "l", lwd = 3, col = "grey60", xlab = "cycles/period",
     ylab = "gain", main = "truncating the WK filter")
lines(f, trunc_gain(w, 5,  FALSE), col = "firebrick", lwd = 2)
lines(f, trunc_gain(w, 5,  TRUE),  col = "firebrick", lwd = 2, lty = 2)
lines(f, trunc_gain(w, 20, FALSE), col = "steelblue", lwd = 2)
legend("topright", c("exact", "L=5 truncated", "L=5 renormalised", "L=20"),
       col = c("grey60", "firebrick", "firebrick", "steelblue"),
       lwd = 2, lty = c(1,1,2,1), bty = "n", cex = 0.8)
for (L in c(5, 10, 20, 40)) {
  cat(sprintf("L=%2d: gain at freq 0 = %.5f (want %.5f), max abs gain error %.5f\n",
              L, trunc_gain(w, L, FALSE)[1], nu[1],
              max(abs(trunc_gain(w, L, FALSE) - nu))))
}
cat("\nShort truncation distorts the gain, most visibly at low frequencies where\n")
cat("the filter is supposed to pass everything.\n\n")

# EXERCISES 3-5: forecast extension converges to the exact answer --------
# Signal-plus-noise data whose exact WK estimate we can approach by extending.
n  <- 200
sig <- cumsum(rnorm(n, sd = 1))
z   <- ts(sig + rnorm(n, sd = 2))

apply_sym <- function(x, w) {
  full <- c(rev(w[-1]), w)
  as.numeric(stats::filter(x, full, method = "convolution", sides = 2))
}

# "exact": filter the middle of a long series, where no truncation bites
long   <- ts(c(as.numeric(z), rep(NA, 0)))
interior_ok <- apply_sym(as.numeric(z), w[1:60])

# extend with ARIMA forecasts of increasing length, and watch the LAST value
fit <- arima(z, order = c(0, 1, 1))
cat("estimate of the signal at the FINAL observation, by extension length:\n")
prev <- NA
for (ah in c(0, 6, 12, 24, 48, 96)) {
  ext <- if (ah == 0) as.numeric(z) else c(as.numeric(z), as.numeric(predict(fit, n.ahead = ah)$pred))
  ww  <- w[1:min(60, length(w))]
  full <- c(rev(ww[-1]), ww)
  m <- (length(full) - 1) / 2
  # value at the original final observation, index n
  idx <- n
  lo <- idx - m; hi <- idx + m
  padded <- c(rep(ext[1], max(0, 1 - lo)), ext, rep(tail(ext, 1), max(0, hi - length(ext))))
  off <- max(0, 1 - lo)
  val <- sum(full * padded[(lo + off):(hi + off)])
  cat(sprintf("  extend %2d months: %8.4f%s\n", ah, val,
              if (!is.na(prev)) sprintf("   (change %+.5f)", val - prev) else ""))
  prev <- val
}
cat("\nThe estimate converges as the extension lengthens. Once the omitted\n")
cat("weights are negligible, more extension changes nothing -- that limit IS\n")
cat("the exact finite-sample answer (what Burman's algorithm computes directly).\n\n")

cat("And the revision problem, arrived at for the THIRD time:\n")
cat("  10-14: the filter needs future values that do not exist\n")
cat("  20-07: the end filter differs structurally from the interior filter\n")
cat("  30-07: the WK filter is infinite and must be completed with forecasts\n")
cat("Three derivations, one phenomenon.\n")
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/30-07-finite-samples.R")
```

Back to [[30-07-finite-samples]] · index: [[code-index]]
