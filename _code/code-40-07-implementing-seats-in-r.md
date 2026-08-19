---
aliases: [40-07-implementing-seats-in-r.R]
tags: [code, generated]
---

# `R/40-07-implementing-seats-in-r.R`

The build, walked through, plus the traps that produce plausible output.

> [!info] Generated file
> Mirror of `R/40-07-implementing-seats-in-r.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[40-07-implementing-seats-in-r]]

```r
# 40-07 -- The build, walked through, plus the traps that produce plausible output.
source("R/_setup.R"); source("R/_spectral.R"); source("R/_seats.R"); source("R/_series.R")

x   <- AirPassengers
fit <- arima(log(x), c(0,1,1), list(order = c(0,1,1), period = 12))
th  <- unname(-coef(fit)["ma1"]); Th <- unname(-coef(fit)["sma1"])
cat(sprintf("STEP 1  fit: theta = %.4f  Theta = %.4f  sigma^2 = %.6f\n", th, Th, fit$sigma2))

sp <- seats_ar_split(1, 1, 12)
cat("STEP 2  AR split: trend", poly_show(sp$trend), " | seasonal S(B), degree",
    length(sp$seasonal) - 1, "\n")

ma <- poly_mult(c(1, -th), c(1, rep(0, 11), -Th))
pf <- seats_partial_fractions(ma, sp$trend, sp$seasonal)
cat("STEP 3-4 partial fractions, residual:", signif(pf$residual, 3), "\n")

cn <- seats_canonical(pf)
cat("STEP 5  admissible:", cn$admissible,
    sprintf(" (minima: T %.4f  S %.4f  I %.4f)\n", cn$min_gT, cn$min_gS, cn$min_gI))
cat("STEP 6  canonical shifts: mT =", round(cn$mT, 5), " mS =", round(cn$mS, 5), "\n")

L <- seats_max_lag(th, Th)
cat("STEP 7-8 filter length:", L, "lags (", round(L/12, 1), "years )\n")
d <- seats_decompose(x, th, Th)
cat("STEP 9  normalised. Done.\n\n")

# The internal checks -- these need no reference implementation -----------
cat("=== internal checks (each caught a real bug during development) ===\n")
sw <- function(v) sum(c(rev(v[-1]), v))
cat(sprintf("  partial-fraction residual : %.2e   (want < 1e-12)\n", pf$residual))
cat(sprintf("  sum of trend weights      : %.6f   (want 1)\n", sw(d$weights$trend)))
cat(sprintf("  sum of seasonal weights   : %.6f   (want 0)\n", sw(d$weights$seasonal)))
cat(sprintf("  sum of irregular weights  : %.6f   (want 0)\n", sw(d$weights$irregular)))
rec <- as.numeric(d$trend + d$seasonal + d$irregular) - as.numeric(log(x))
cat(sprintf("  max |T + S + I - log z|   : %.2e   (the best end-to-end test)\n", max(abs(rec))))

op <- par(mfrow = c(4, 1), mar = c(2, 4, 2, 1))
plot(log(x), ylab = "log z", main = "SEATS decomposition of log(AirPassengers)")
lines(d$trend, col = "firebrick", lwd = 2)
plot(d$sa, ylab = "SA", main = "seasonally adjusted (trend + irregular)")
plot(d$seasonal, ylab = "S", main = "seasonal"); abline(h = 0, col = "grey60")
plot(d$irregular, ylab = "I", main = "irregular"); abline(h = 0, col = "grey60")
par(op)

# TRAP 1: truncate too early -> a CONSTANT offset, not noise -------------
cat("\n=== TRAP 1: truncating the filter too early ===\n")
# Compare with normalize = FALSE on BOTH sides. The normalisation step of
# step 9 re-centres the seasonal, which would hide exactly the effect being
# demonstrated -- so switch it off to see the raw damage.
full_r  <- seats_decompose(x, th, Th, normalize = FALSE)
short_r <- seats_decompose(x, th, Th, max_lag = 60, extend = 72, normalize = FALSE)
off <- as.numeric(short_r$seasonal) - as.numeric(full_r$seasonal)
cat(sprintf("  max_lag = 60 vs %d\n", L))
cat(sprintf("  mean difference in the seasonal : %+.6f\n", mean(off)))
cat(sprintf("  sd of that difference           : %.2e\n", sd(off)))
cat(sprintf("  ratio sd/|mean|                 : %.4f  <- near 0 means CONSTANT\n",
            sd(off) / abs(mean(off))))
cat(sprintf("  correlation with the correct one: %.6f\n",
            cor(as.numeric(short_r$seasonal), as.numeric(full_r$seasonal))))
cat("  sum of the truncated seasonal weights:", round(sw(short_r$weights$seasonal), 5),
    " (should be 0)\n")
cat("Shape essentially perfect, level wrong. If your component correlates at\n")
cat("0.999 but sits a fixed distance from the reference, this is why.\n")
cat("NOTE: the step-9 normalisation MASKS this, because re-centring the seasonal\n")
cat("absorbs the constant. A bug hidden by a convention is still a bug -- check\n")
cat("the weight sums directly rather than trusting the final output.\n")

# TRAP 2: extension shorter than the filter -> silent NAs ---------------
cat("\n=== TRAP 2: extension shorter than the filter ===\n")
r <- tryCatch(seats_decompose(x, th, Th, max_lag = 120, extend = 60),
              error = function(e) conditionMessage(e))
cat("  ", if (is.character(r)) paste("caught by the assertion:", r) else "no error (bad!)", "\n")
cat("Without stopifnot(extend >= max_lag) this returns all NA, or worse,\n")
cat("NAs only near the ends where you may not look.\n")

# TRAP 3: the normalisation constant ------------------------------------
cat("\n=== TRAP 3: the trend/seasonal constant is a CONVENTION ===\n")
raw <- seats_decompose(x, th, Th, normalize = FALSE)
cat(sprintf("  log-seasonal mean, un-normalised : %+.6f  (theory says 0)\n",
            mean(as.numeric(raw$seasonal))))
cat(sprintf("  log-seasonal mean, normalised    : %+.6f\n", mean(as.numeric(d$seasonal))))
cat(sprintf("  -var/2 of the log factors        : %+.6f\n", -var(as.numeric(d$seasonal))/2))
cat(sprintf("  mean of exp(seasonal), normalised: %.6f  (want 1)\n",
            mean(exp(as.numeric(d$seasonal)))))
cat("nu_S(0) = 0, so the seasonal filter kills constants -- the theory CANNOT\n")
cat("say whether a constant belongs to the trend or the seasonal. X-13 fixes it\n")
cat("by making multiplicative factors average 1 in LEVELS.\n")

# EXERCISE 3: a series with much more persistent seasonality ------------
cat("\n=== co2: Theta = 0.912, so a much longer filter ===\n")
f2 <- airline_fit(co2)
cat(sprintf("  theta = %.3f  Theta = %.3f  -> max_lag %d (%.0f years)\n",
            f2$theta, f2$Theta, seats_max_lag(f2$theta, f2$Theta),
            seats_max_lag(f2$theta, f2$Theta)/12))
d2 <- seats_decompose(co2, f2$theta, f2$Theta)
rec2 <- as.numeric(d2$trend + d2$seasonal + d2$irregular) - as.numeric(log(co2))
cat(sprintf("  max |T + S + I - log z| : %.2e\n", max(abs(rec2))))
cat("  Stable seasonality needs a longer filter, exactly as 30-06 predicts.\n")
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/40-07-implementing-seats-in-r.R")
```

Back to [[40-07-implementing-seats-in-r]] · index: [[code-index]]
