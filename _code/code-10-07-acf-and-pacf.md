---
aliases: [10-07-acf-and-pacf.R]
tags: [code, generated]
---

# `R/10-07-acf-and-pacf.R`

Identification from ACF and PACF.

> [!info] Generated file
> Mirror of `R/10-07-acf-and-pacf.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[10-07-acf-and-pacf]]

```r
# 10-07 -- Identification from ACF and PACF.
source("R/_setup.R")
set.seed(41)

# EXERCISE 1: identify these cold -------------------------------------------
# Run this block, look at the six panels, and name each model BEFORE scrolling.
sims <- list(
  A = arima.sim(list(ar = c(0.6, -0.4)), 300),
  B = arima.sim(list(ma = c(0.7,  0.4)), 300),
  C = arima.sim(list(ar = 0.7, ma = 0.5), 300)
)
op <- par(mfrow = c(3, 2), mar = c(3, 4, 2, 1))
for (nm in names(sims)) {
  acf(sims[[nm]],  lag.max = 20, main = paste("series", nm, "- ACF"))
  pacf(sims[[nm]], lag.max = 20, main = paste("series", nm, "- PACF"))
}
par(op)
# ANSWERS: A = AR(2)  (PACF cuts at 2)
#          B = MA(2)  (ACF cuts at 2)
#          C = ARMA(1,1) (neither cuts cleanly)

# Now the honest version: n = 60, the real-data regime ----------------------
sims60 <- lapply(sims, function(x) x[1:60])
op <- par(mfrow = c(3, 2), mar = c(3, 4, 2, 1))
for (nm in names(sims60)) {
  acf(sims60[[nm]],  lag.max = 20, main = paste("n=60  series", nm, "- ACF"))
  pacf(sims60[[nm]], lag.max = 20, main = paste("n=60  series", nm, "- PACF"))
}
par(op)
# Much harder. This ambiguity is why automatic identification exists, and why
# two competent analysts can pick different models for the same series.

# EXERCISE 2: the airline signature, including the SATELLITES ---------------
w <- diff(diff(lap), 12)
a <- acf(w, lag.max = 40, main = "(1-B)(1-B^12) log(AirPassengers)")
band <- 1.96 / sqrt(length(w))
sig <- which(abs(a$acf[-1]) > band)
cat("lags exceeding the +/- 1.96/sqrt(n) band:", sig, "\n")
cat("\nread them as:\n")
cat("  lag 1      -> theta(B),   the regular MA\n")
cat("  lag 12     -> Theta(B^12), the seasonal MA\n")
cat("  lag 11, 13 -> the CROSS TERM theta*Theta*B^13 of the product. Satellites.\n")
cat("A purely additive seasonal model would not produce lags 11 and 13.\n")

# Nonstationary signature ---------------------------------------------------
op <- par(mfrow = c(1, 2), mar = c(3, 4, 3, 1))
acf(lap,  lag.max = 48, main = "nonstationary: ACF decays near-linearly")
pacf(lap, lag.max = 48, main = "nonstationary: phi_11 ~ 1, then little")
par(op)
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/10-07-acf-and-pacf.R")
```

Back to [[10-07-acf-and-pacf]] · index: [[code-index]]
