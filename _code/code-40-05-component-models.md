---
aliases: [40-05-component-models.R]
tags: [code, generated]
---

# `R/40-05-component-models.R`

What ARIMA does each component follow?

> [!info] Generated file
> Mirror of `R/40-05-component-models.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[40-05-component-models]]

```r
# 40-05 -- What ARIMA does each component follow?
source("R/_setup.R"); source("R/_spectral.R"); source("R/_seats.R")

x   <- AirPassengers
fit <- arima(log(x), c(0,1,1), list(order = c(0,1,1), period = 12))
th  <- unname(-coef(fit)["ma1"]); Th <- unname(-coef(fit)["sma1"])
ma  <- poly_mult(c(1, -th), c(1, rep(0, 11), -Th))
sp  <- seats_ar_split(1, 1, 12)
cn  <- seats_canonical(seats_partial_fractions(ma, sp$trend, sp$seasonal))

# THE KEY SIMPLIFICATION --------------------------------------------------
# The canonical trend has spectrum  Acan(w) / DT(w).  Differencing it twice
# multiplies its spectrum by |1 - e^{-iw}|^4 = DT(w).  So
#
#     spectrum of (1-B)^2 T  =  DT(w) * Acan(w)/DT(w)  =  Acan(w)
#
# and Acan is a COSINE POLYNOMIAL whose coefficients ARE the autocovariances.
# So we can read the component's model straight off the vector -- no spectral
# factorisation, no numerical integration.

cat("=== the trend ===\n")
cat("cosine coefficients of Acan (= autocovariances of (1-B)^2 T):\n")
print(round(cn$Acan, 6))
cat("\ndegree", length(cn$Acan) - 1, "-> autocovariances vanish beyond lag",
    length(cn$Acan) - 1, "\n")
cat("An MA(q) has autocovariances vanishing beyond lag q, so (1-B)^2 T is an\n")
cat("MA(2), i.e. the TREND IS AN ARIMA(0,2,2).\n")
cat("That is the reduced form of a local linear trend (level and slope both\n")
cat("random walks) -- a model you would have written down yourself.\n\n")

cat("=== the seasonal ===\n")
cat("degree of Ccan:", length(cn$Ccan) - 1, " -> S(B) S_t is an MA(",
    length(cn$Ccan) - 1, ")\n", sep = "")
cat("first 5 autocovariances:", round(cn$Ccan[1:5], 6), "\n")
cat("so the seasonal follows  S(B) S_t = theta_S(B) b_t  with deg theta_S = 11.\n\n")

cat("=== the irregular ===\n")
cat("Dcan (constant):", round(cn$Dcan, 6), "\n")
cat("A constant spectrum is EXACTLY white noise -- not approximately.\n\n")

# EXERCISE 5: the canonical step raises the degree by one -----------------
pf <- seats_partial_fractions(ma, sp$trend, sp$seasonal)
cat("=== the canonical step adds a degree (and a unit MA root) ===\n")
cat("deg A  before canonical:", length(pf$A) - 1, "\n")
cat("deg A  after  canonical:", length(cn$Acan) - 1, "\n")
cat("Subtracting mT*DT (degree 2) from A (degree 1) gives degree 2. That extra\n")
cat("degree IS the unit MA root the canonical rule creates (40-03).\n\n")

# EXERCISES 1-3: verify numerically, independent of the argument above ----
# Compute autocovariances by inverse Fourier of each component's spectrum
# times its own differencing operator. Should match the cosine coefficients.
acov_from_spectrum <- function(cospoly_num, mult = NULL, max_lag = 16, ngrid = 6000) {
  w <- seq(0, pi, length.out = ngrid)
  f <- cospoly_eval(cospoly_num, w)
  if (!is.null(mult)) f <- f * cospoly_eval(mult, w)
  vapply(0:max_lag, function(k) {
    y <- f * cos(k * w)
    (1 / pi) * sum((head(y, -1) + tail(y, -1)) / 2 * diff(w))
  }, numeric(1))
}
gT <- acov_from_spectrum(cn$Acan)                 # spectrum of (1-B)^2 T is Acan
cat("=== independent numerical check: autocovariances of (1-B)^2 T ===\n")
print(round(gT[1:8], 6))
cat("lag 3 onwards are zero to", signif(max(abs(gT[4:17])), 3), "-> MA(2) confirmed\n\n")

gS <- acov_from_spectrum(cn$Ccan, max_lag = 16)
cat("autocovariances of S(B) S_t, lags 10..16:\n")
print(round(gS[11:17], 6))
cat("zero beyond lag 11 to", signif(max(abs(gS[13:17])), 3), "-> MA(11) confirmed\n\n")

gI <- acov_from_spectrum(cn$Dcan, max_lag = 6)
cat("autocovariances of the irregular:", round(gI, 6), "\n")
cat("only lag 0 is nonzero -> exactly white\n\n")

# EXERCISE 4: how is the innovation variance shared? ---------------------
cat("=== variance shares ===\n")
tot <- gT[1] + gS[1] + gI[1]
cat(sprintf("  trend innovation    %.5f  (%4.1f%%)\n", gT[1], 100*gT[1]/tot))
cat(sprintf("  seasonal innovation %.5f  (%4.1f%%)\n", gS[1], 100*gS[1]/tot))
cat(sprintf("  irregular           %.5f  (%4.1f%%)\n", gI[1], 100*gI[1]/tot))
cat("\nThese are the models SEATS uses to forecast the components and to report\n")
cat("their standard errors. They are IMPLIED by the fitted reduced form plus\n")
cat("the canonical convention -- never estimated from component data, because\n")
cat("no component data exists.\n")
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/40-05-component-models.R")
```

Back to [[40-05-component-models]] · index: [[code-index]]
