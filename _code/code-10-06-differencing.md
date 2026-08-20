---
aliases: [10-06-differencing.R]
tags: [code, generated]
---

# `R/10-06-differencing.R`

Differencing: logs first, then (1-B) and (1-B^12).

> [!info] Generated file
> Mirror of `R/10-06-differencing.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[10-06-differencing]]

```r
# 10-06 -- Differencing: logs first, then (1-B) and (1-B^12).
source("R/_setup.R")

# EXERCISE 1: the four stages ------------------------------------------------
op <- par(mfrow = c(4, 1), mar = c(2, 4, 2, 1))
plot(AirPassengers, ylab = "raw", main = "raw: level rises AND swings widen")
plot(lap,           ylab = "log", main = "log: swings now roughly constant width")
plot(diff(lap),     ylab = "(1-B)", main = "(1-B) log: level gone, seasonality remains")
plot(diff(diff(lap), 12), ylab = "(1-B)(1-B^12)", main = "(1-B)(1-B^12) log: looks stationary")
par(op)

# EXERCISE 2: variance at each stage -----------------------------------------
stages <- list(
  "log"                 = lap,
  "(1-B)"               = diff(lap),
  "(1-B^12)"            = diff(lap, 12),
  "(1-B)(1-B^12)"       = diff(diff(lap), 12),
  "(1-B)^2(1-B^12)"     = diff(diff(diff(lap)), 12)
)
cat("variance by stage:\n")
print(round(sapply(stages, var), 6))
# Variance falls, then RISES again at the last one -> you have gone too far.

# ACF at each stage: what "needs differencing" looks like --------------------
op <- par(mfrow = c(2, 2), mar = c(3, 4, 3, 1))
acf(lap, lag.max = 48, main = "log: slow near-linear decay -> difference")
acf(diff(lap), lag.max = 48, main = "(1-B): big spikes at 12,24,36 -> seasonal difference")
acf(diff(lap, 12), lag.max = 48, main = "(1-B^12): still slow decay -> also regular difference")
acf(diff(diff(lap), 12), lag.max = 48, main = "(1-B)(1-B^12): dies quickly. Done.")
par(op)

# EXERCISE 3: the roots of 1 - B^12, as periods ------------------------------
r <- poly_roots(c(1, rep(0, 11), -1))
cat("\nperiods (months) implied by the roots of 1 - B^12:\n")
print(sort(unique(round(r$period[is.finite(r$period)], 2))))
cat("plus one root at z=1 (period Inf) -- that is the TREND root.\n")

# The factorisation that drives SEATS ---------------------------------------
S <- rep(1, 12)                                  # 1 + B + ... + B^11
cat("\n(1-B) * S(B) =", poly_show(poly_mult(c(1, -1), S)), "\n")
cat("so (1-B)(1-B^12) = (1-B)^2 * S(B):",
    all.equal(poly_mult(c(1, -1), poly_mult(c(1, -1), S)), diff_poly(1, 1, 12)), "\n")
# (1-B)^2 -> trend component;  S(B) -> seasonal component. That split IS step 1
# of the SEATS algorithm.

# CONSTANT IN A DIFFERENCED MODEL = DRIFT ------------------------------------
fit <- arima(lap, order = c(0, 1, 1), seasonal = list(order = c(0, 1, 1), period = 12))
cat("\nairline fit has no constant by default (d+D=2). Now with d=1 only:\n")
# TRAP: arima() SILENTLY IGNORES include.mean when d >= 1. No intercept is
# fitted, and coef(fit2)["intercept"] is NA -- not zero, and not an error.
fit2 <- arima(lap, order = c(0, 1, 1), include.mean = TRUE)
cat("  include.mean = TRUE with d = 1 gives coefficients:",
    paste(names(coef(fit2)), collapse = ", "), "\n")
cat("  -> no intercept at all. R drops it silently; asking is not enough.\n")

# To fit a drift you must supply it yourself as a regressor.
n    <- length(lap)
fit3 <- arima(lap, order = c(0, 1, 1), xreg = 1:n)
k    <- length(coef(fit3))
dft  <- as.numeric(coef(fit3)[k])
sdft <- as.numeric(sqrt(diag(fit3$var.coef))[k])
cat(sprintf("  with xreg = 1:n the drift is %+.6f per month in logs (se %.6f, t = %.2f)\n",
            dft, sdft, dft / sdft))
cat(sprintf("  i.e. %+.3f%% per month = %+.2f%% per year\n",
            100 * dft, 100 * (exp(12 * dft) - 1)))
# It is NOT a level. It is a slope -- a straight-line ramp in the original.
cat("  Note the t-statistic: with d = 1 plus an MA term the drift is only\n")
cat("  weakly identified, because differencing already removed the level.\n")

# ---- the variance check on a series where it CHANGES the answer ---------
cat("\n=== ldeaths: differencing too far ===\n")
v <- c(`undifferenced`      = var(log(ldeaths)),
       `(1-B^12)`           = var(diff(log(ldeaths), 12)),
       `(1-B)(1-B^12)`      = var(diff(diff(log(ldeaths)), 12)))
print(round(v, 5))
cat("The seasonal difference helps; the regular one makes it WORSE.\n")
cat("So d = 0, D = 1 -- which is exactly what X-13 picks unaided.\n\n")
cat("Contrast AirPassengers, where both differences reduce the variance:\n")
v2 <- c(`undifferenced` = var(lap), `(1-B)(1-B^12)` = var(diff(diff(lap), 12)))
print(round(v2, 5))
cat("\nOne line, no model, and it catches the commonest modelling error there is.\n")
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/10-06-differencing.R")
```

Back to [[10-06-differencing]] · index: [[code-index]]
