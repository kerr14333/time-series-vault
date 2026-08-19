---
aliases: [40-01-unobserved-components-and-reduced-form.R]
tags: [code, generated]
---

# `R/40-01-unobserved-components-and-reduced-form.R`

A structural model has an ARIMA reduced form. SEATS runs it backwards.

> [!info] Generated file
> Mirror of `R/40-01-unobserved-components-and-reduced-form.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[40-01-unobserved-components-and-reduced-form]]

```r
# 40-01 -- A structural model has an ARIMA reduced form. SEATS runs it backwards.
source("R/_setup.R"); source("R/_spectral.R")
set.seed(501)

# Simulate the basic structural model directly:
#   (1-B)^2 T = eta        trend: level and slope both wander
#   S(B) S    = omega      seasonal: 12 factors that drift, summing to ~0
#   I         = eps        white noise
sim_structural <- function(n = 240, s = 12, sd_eta = 0.02, sd_omega = 0.03, sd_eps = 0.05) {
  m <- n + 200
  # trend: double integration of eta
  Tt <- cumsum(cumsum(rnorm(m, sd = sd_eta)))
  # seasonal: S(B) S_t = omega_t  =>  S_t = omega_t - S_{t-1} - ... - S_{t-11}
  St <- numeric(m); om <- rnorm(m, sd = sd_omega)
  for (t in (s + 1):m) St[t] <- om[t] - sum(St[(t - s + 1):(t - 1)])
  It <- rnorm(m, sd = sd_eps)
  list(z = ts(tail(Tt + St + It, n), frequency = s),
       trend = ts(tail(Tt, n), frequency = s),
       seasonal = ts(tail(St, n), frequency = s),
       irregular = ts(tail(It, n), frequency = s))
}

d <- sim_structural()
op <- par(mfrow = c(4, 1), mar = c(2, 4, 2, 1))
plot(d$z, ylab = "z", main = "simulated: z = T + S + I")
plot(d$trend, ylab = "T", main = "trend (1-B)^2 T = eta")
plot(d$seasonal, ylab = "S", main = "seasonal S(B) S = omega")
plot(d$irregular, ylab = "I", main = "irregular (white)")
par(op)

# EXERCISE 1: the reduced form is an MA(13) after (1-B)(1-B^12) ------------
w <- diff(diff(d$z), 12)
a <- acf(w, lag.max = 30, plot = FALSE)
cat("autocorrelations of (1-B)(1-B^12) z, lags 12..20:\n")
print(round(a$acf[13:21], 3))
band <- 1.96 / sqrt(length(w))
big <- which(abs(a$acf[-1]) > band)
cat("lags exceeding the band:", big, "\n")
cat("Nothing material beyond lag 13 -- the reduced form is an MA(13), which is\n")
cat("exactly the shape of (1 - theta B)(1 - Theta B^12) a_t.\n\n")

fit <- arima(d$z, c(0,1,1), list(order = c(0,1,1), period = 12))
cat(sprintf("fitted reduced form (Census): theta = %.3f  Theta = %.3f\n\n",
            -coef(fit)["ma1"], -coef(fit)["sma1"]))

# EXERCISE 2: which structural variance drives which parameter? ------------
cat("=== vary one structural variance at a time ===\n")
cat(sprintf("%-28s %8s %8s\n", "setting", "theta", "Theta"))
base <- list(sd_eta = 0.02, sd_omega = 0.03, sd_eps = 0.05)
runs <- list(
  "baseline"                    = base,
  "trend shock x4  (sd_eta)"    = modifyList(base, list(sd_eta = 0.08)),
  "seasonal shock x4 (sd_omega)"= modifyList(base, list(sd_omega = 0.12)),
  "noise x4 (sd_eps)"           = modifyList(base, list(sd_eps = 0.20))
)
for (nm in names(runs)) {
  set.seed(77)
  p <- runs[[nm]]
  dd <- sim_structural(sd_eta = p$sd_eta, sd_omega = p$sd_omega, sd_eps = p$sd_eps)
  f <- arima(dd$z, c(0,1,1), list(order = c(0,1,1), period = 12))
  cat(sprintf("%-28s %8.3f %8.3f\n", nm, -coef(f)["ma1"], -coef(f)["sma1"]))
}
cat("\nMore trend shock -> trend is rougher -> theta FALLS (less smoothing).\n")
cat("More seasonal shock -> seasonality evolves faster -> Theta FALLS.\n")
cat("More noise -> both rise: the components look smoother relative to the noise.\n\n")

# EXERCISE 3: no seasonal shock => deterministic seasonality ---------------
set.seed(77)
d0 <- sim_structural(sd_omega = 1e-8)
f0 <- arima(d0$z, c(0,1,1), list(order = c(0,1,1), period = 12))
cat(sprintf("sd_omega ~ 0  ->  Theta = %.4f\n", -coef(f0)["sma1"]))
cat("Theta near 1 cancels the seasonal unit roots: a FIXED seasonal pattern.\n")
cat("Exactly the reading given in 10-10.\n")
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/40-01-unobserved-components-and-reduced-form.R")
```

Back to [[40-01-unobserved-components-and-reduced-form]] · index: [[code-index]]
