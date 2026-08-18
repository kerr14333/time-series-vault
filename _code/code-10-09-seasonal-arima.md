---
aliases: [10-09-seasonal-arima.R]
tags: [code, generated]
---

# `R/10-09-seasonal-arima.R`

Multiplicative seasonal ARIMA: four polynomials.

> [!info] Generated file
> Mirror of `R/10-09-seasonal-arima.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[10-09-seasonal-arima]]

```r
# 10-09 -- Multiplicative seasonal ARIMA: four polynomials.
source("R/_setup.R")
set.seed(61)

# EXERCISE 1: expand (1 - phi B)(1 - Phi B^12) ------------------------------
p <- poly_mult(c(1, -0.5), c(1, rep(0, 11), -0.8))
cat("(1 - 0.5B)(1 - 0.8B^12) =", poly_show(p), "\n")
cat("nonzero lags:", which(abs(p) > 1e-12) - 1L, "\n\n")
# lags 0, 1, 12, 13. The 13 is the CROSS TERM and it is free -- no extra parameter.

# EXERCISE 2: (0,1,1)(1,0,0)_12 written out ---------------------------------
cat("(0,1,1)(1,0,0)_12 is:\n")
cat("  (1 - Phi B^12)(1 - B) z_t = (1 - theta B) a_t\n")
cat("  LHS =", poly_show(poly_mult(c(1, rep(0, 11), -0.8), c(1, -1))), "applied to z\n")
cat("  i.e. z_t - z_{t-1} - Phi z_{t-12} + Phi z_{t-13} = a_t - theta a_{t-1}\n\n")

# Seasonal AR vs seasonal differencing --------------------------------------
n <- 240
sim_sarima <- function(theta, Theta, P = 0, Phi = 0, D = 1, n = 240) {
  # simulate via the expanded polynomials
  ma <- poly_mult(c(1, -theta), c(1, rep(0, 11), -Theta))
  a  <- rnorm(n + 400)
  w  <- stats::filter(a, ma_census_to_r(ma[-1]), method = "convolution", sides = 1)
  w  <- na.omit(w)
  if (D == 1) {
    z   <- cumsum(w)                                  # undo (1-B)
    out <- numeric(length(z))                         # undo (1-B^12)
    for (t in seq_along(z)) out[t] <- z[t] + if (t > 12) out[t - 12] else 0
    z <- out
  }
  ts(tail(z, n), frequency = 12)
}

x_evolving <- sim_sarima(theta = 0.4, Theta = 0.6, D = 1)
# stationary seasonal AR instead:
ar12 <- poly_mult(c(1), c(1, rep(0, 11), -0.9))
x_reverting <- ts(arima.sim(list(order = c(12, 1, 0), ar = c(rep(0, 11), 0.9)), n), frequency = 12)

op <- par(mfrow = c(2, 1), mar = c(3, 4, 2, 1))
plot(x_evolving,  ylab = "", main = "D=1: seasonal unit roots -- pattern is a random walk year to year")
plot(x_reverting, ylab = "", main = "P=1, Phi=0.9: stationary seasonal -- pattern reverts to a fixed shape")
par(op)
# Most real economic seasonality is the first kind. Hence D=1 >> P=1 in practice.

# EXERCISE 3: satellite spikes in the airline ACF ---------------------------
ma_air <- poly_mult(c(1, -0.4), c(1, rep(0, 11), -0.6))
cat("airline MA polynomial theta(B)Theta(B^12) =", poly_show(round(ma_air, 4)), "\n")
th_acf <- ARMAacf(ma = ma_census_to_r(ma_air[-1]), lag.max = 26)
plot(0:26, th_acf, type = "h", lwd = 3, col = "steelblue",
     main = "theoretical ACF of the differenced airline model",
     xlab = "lag", ylab = "rho")
abline(h = 0, col = "grey60")
text(c(1, 11, 12, 13), th_acf[c(2, 12, 13, 14)], c("1", "11", "12", "13"), pos = 3, cex = 0.8)
cat("\nnote lags 11 and 13 -- the satellites. And rho_k = 0 for k > 13:\n")
print(round(th_acf[15:27], 6))
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/10-09-seasonal-arima.R")
```

Back to [[10-09-seasonal-arima]] · index: [[code-index]]
