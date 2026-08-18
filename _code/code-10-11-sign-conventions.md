---
aliases: [10-11-sign-conventions.R]
tags: [code, generated]
---

# `R/10-11-sign-conventions.R`

Prove the sign convention to yourself. Do not take it on faith.

> [!info] Generated file
> Mirror of `R/10-11-sign-conventions.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[10-11-sign-conventions]]

```r
# 10-11 -- Prove the sign convention to yourself. Do not take it on faith.
source("R/_setup.R")

fit <- arima(lap, order = c(0, 1, 1), seasonal = list(order = c(0, 1, 1), period = 12))
cat("stats::arima() reports (PLUS convention):\n")
print(round(coef(fit), 4))
cat("\nsame model in CENSUS convention (negate the MA terms):\n")
print(round(ma_r_to_census(coef(fit)), 4))

# Now the same series through the actual X-13 binary -------------------------
if (requireNamespace("seasonal", quietly = TRUE)) {
  m <- seasonal::seas(AirPassengers, transform.function = "log",
                      arima.model = "(0 1 1)(0 1 1)", regression.aictest = NULL,
                      outlier = NULL)
  cat("\nseasonal::seas() -- i.e. the real X-13 -- reports:\n")
  print(round(coef(m), 4))
  cat("\nCompare with the two blocks above. Which convention does X-13 use?\n")
  cat("(Answer: Census. The MA coefficients come out POSITIVE.)\n")
} else {
  cat("\n[install 'seasonal' to run the X-13 comparison]\n")
}

# Sanity test on a case where you know the sign -----------------------------
# rho1 < 0  <=>  Census theta > 0
set.seed(9)
x <- diff(cumsum(rnorm(2000)) + rnorm(2000, sd = 2))
r1 <- acf(x, plot = FALSE)$acf[2]
th_census <- ma_r_to_census(coef(arima(x, order = c(0, 0, 1), include.mean = FALSE)))
cat(sprintf("\nrho1 = %.3f (negative)  ->  Census theta = %.3f (positive). Consistent.\n",
            r1, th_census))

# The converter you should use everywhere -----------------------------------
cat("\nma_r_to_census(0.4) =", ma_r_to_census(0.4), "\n")
cat("Write it once, use it always. Guessing costs hours.\n")
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/10-11-sign-conventions.R")
```

Back to [[10-11-sign-conventions]] · index: [[code-index]]
