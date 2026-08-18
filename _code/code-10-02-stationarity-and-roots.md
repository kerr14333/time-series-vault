---
aliases: [10-02-stationarity-and-roots.R]
tags: [code, generated]
---

# `R/10-02-stationarity-and-roots.R`

Stationarity is a statement about polynomial roots.

> [!info] Generated file
> Mirror of `R/10-02-stationarity-and-roots.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[10-02-stationarity-and-roots]]

```r
# 10-02 -- Stationarity is a statement about polynomial roots.
source("R/_setup.R")

# AR(1): phi(B) = 1 - phi B, root = 1/phi -----------------------------------
for (phi in c(0.5, 0.95, 1.0, 1.05)) {
  r <- polyroot(c(1, -phi))
  cat(sprintf("phi = %5.2f   root = %6.3f   |root| = %5.3f   %s\n",
              phi, Re(r), Mod(r),
              if (Mod(r) > 1) "stationary" else if (Mod(r) == 1) "UNIT ROOT" else "explosive"))
}

# EXERCISE 1: is 1 - 1.2B + 0.5B^2 stationary? -------------------------------
cat("\n1 - 1.2B + 0.5B^2:\n"); print(poly_roots(c(1, -1.2, 0.5)))
# complex roots, modulus > 1 -> stationary, and the ACF will oscillate.
# The 'period' column says how long one pseudo-cycle takes.

# EXERCISE 2: the 12 roots of 1 - B^12 --------------------------------------
cat("\nroots of 1 - B^12 (all on the unit circle):\n")
print(poly_roots(c(1, rep(0, 11), -1)))
# periods: Inf (freq 0 = trend), 12, 6, 4, 3, 2.4, 2 months.
# Those SIX seasonal frequencies + the trend frequency are what SEATS partitions.

# See it: unit-circle plot ---------------------------------------------------
op <- par(pty = "s")
r <- polyroot(c(1, rep(0, 11), -1))
plot(Re(r), Im(r), asp = 1, pch = 19, col = "steelblue",
     xlab = "Re", ylab = "Im", main = "roots of 1 - B^12")
symbols(0, 0, circles = 1, inches = FALSE, add = TRUE, fg = "grey60")
abline(h = 0, v = 0, col = "grey85")
par(op)

# Stationary vs unit root, visually ------------------------------------------
set.seed(1)
op <- par(mfrow = c(3, 1), mar = c(2, 4, 2, 1))
plot(arima.sim(list(ar = 0.5), 300), ylab = "", main = "AR(1) phi=0.5  (stationary)")
plot(arima.sim(list(ar = 0.95), 300), ylab = "", main = "AR(1) phi=0.95 (stationary, slow)")
plot(cumsum(rnorm(300)), type = "l", ylab = "", main = "random walk (unit root)")
par(op)

# Why detrending does not fix a unit root ------------------------------------
set.seed(2)
rw <- cumsum(rnorm(300))
res <- residuals(lm(rw ~ seq_along(rw)))
acf(res, main = "residuals after removing a fitted line -- still not stationary")
# The ACF still decays far too slowly: the nonstationarity was stochastic,
# and no fixed line can absorb it.
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/10-02-stationarity-and-roots.R")
```

Back to [[10-02-stationarity-and-roots]] · index: [[code-index]]
