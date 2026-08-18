---
aliases: [10-14-forecasting.R]
tags: [code, generated]
---

# `R/10-14-forecasting.R`

Forecasting, and the revision experiment that motivates everything.

> [!info] Generated file
> Mirror of `R/10-14-forecasting.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[10-14-forecasting]]

```r
# 10-14 -- Forecasting, and the revision experiment that motivates everything.
source("R/_setup.R")

fit <- arima(lap, c(0,1,1), list(order = c(0,1,1), period = 12))

# EXERCISE 1: forecast 24 months, plot on the original scale ---------------
fc <- predict(fit, n.ahead = 24)
lo <- exp(fc$pred - 1.96 * fc$se); hi <- exp(fc$pred + 1.96 * fc$se)
plot(AirPassengers, xlim = c(1949, 1963), ylim = c(100, 900),
     ylab = "passengers", main = "airline-model forecast, 95% interval")
lines(exp(fc$pred), col = "firebrick", lwd = 2)
lines(lo, col = "firebrick", lty = 2); lines(hi, col = "firebrick", lty = 2)
cat("interval half-width at h=1: ", round(1.96 * fc$se[1], 4), " (logs)\n")
cat("interval half-width at h=24:", round(1.96 * fc$se[24], 4), " (logs)\n")

# EXERCISE 2: psi-weights of the airline model do NOT decay to zero --------
ma_air <- poly_mult(c(1, -ma_r_to_census(coef(fit)["ma1"])),
                    c(1, rep(0, 11), -ma_r_to_census(coef(fit)["sma1"])))
ar_air <- diff_poly(d = 1, D = 1, s = 12)      # the differencing, as AR
psi <- ARMAtoMA(ar = -ar_air[-1], ma = ma_census_to_r(ma_air[-1]), 48)
plot(psi, type = "h", lwd = 2, col = "steelblue", xlab = "j", ylab = "psi_j",
     main = "psi-weights: unit roots mean they never die")
abline(h = 0, col = "grey60")
cat("\npsi_48 =", round(psi[48], 3), "\n")
cat("The weights GROW, they do not decay: two unit roots at frequency 0 means a\n")
cat("single shock permanently shifts both level and slope. Hence V(h) is unbounded\n")
cat("and the forecast bands widen forever.\n")

# EXERCISE 3: hold out the last two years ----------------------------------
train <- window(lap, end = c(1958, 12))
truth <- window(lap, start = c(1959, 1))
f2 <- arima(train, c(0,1,1), list(order = c(0,1,1), period = 12))
p2 <- predict(f2, n.ahead = 24)
err <- truth - p2$pred
plot(err, type = "h", lwd = 3, col = "firebrick", ylab = "log error",
     main = "forecast errors 1959-60 (fit through 1958)")
abline(h = 0)
cat("\nmean abs forecast error (logs):", round(mean(abs(err)), 4), "\n")
cat("errors grow with horizon -- and they are WORST where the trend changes pace.\n")

# EXERCISE 4 -- THE KEY EXPERIMENT: a revision path ------------------------
# Adjust the series repeatedly, each time pretending it ends earlier, and watch
# one month's seasonal factor move as more data arrives.
if (requireNamespace("seasonal", quietly = TRUE)) {
  target <- c(1958, 1)
  ends <- list(c(1958,3), c(1958,6), c(1958,12), c(1959,6), c(1959,12), c(1960,12))
  vals <- sapply(ends, function(e) {
    x <- window(AirPassengers, end = e)
    m <- seasonal::seas(x, transform.function = "log",
                        arima.model = "(0 1 1)(0 1 1)",
                        regression.aictest = NULL, outlier = NULL)
    s10 <- seasonal::series(m, "s10")
    as.numeric(window(s10, start = target, end = target))
  })
  labs <- sapply(ends, function(e) sprintf("%d-%02d", e[1], e[2]))
  plot(seq_along(vals), vals, type = "b", pch = 19, xaxt = "n", lwd = 2,
       xlab = "data available through", ylab = "seasonal factor for Jan 1958",
       main = "REVISION PATH: the same month, re-adjusted as data arrives")
  axis(1, at = seq_along(vals), labels = labs)
  cat("\nseasonal factor for Jan 1958 by vintage:\n")
  print(setNames(round(vals, 4), labs))
  cat("\nrange:", round(diff(range(vals)), 4),
      " -- that spread is pure end-of-sample uncertainty.\n")
  cat("It shrinks as the symmetric filter fills in. Module 5 quantifies it.\n")
} else {
  cat("\n[install 'seasonal' + 'x13binary' for the revision experiment]\n")
}
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/10-14-forecasting.R")
```

Back to [[10-14-forecasting]] · index: [[code-index]]
