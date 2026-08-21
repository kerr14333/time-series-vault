---
aliases: [30-03-spectrum-of-an-arma.R]
tags: [code, generated]
---

# `R/30-03-spectrum-of-an-arma.R`

The central formula: f(w) = (sigma^2/2pi) |theta|^2 / |phi|^2.

> [!info] Generated file
> Mirror of `R/30-03-spectrum-of-an-arma.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[30-03-spectrum-of-an-arma]]

```r
# 30-03 -- The central formula: f(w) = (sigma^2/2pi) |theta|^2 / |phi|^2.
source("R/_setup.R"); source("R/_spectral.R")

# EXERCISE 5 FIRST: verify the closed form against the definition ----------
# Definition: Fourier transform of the autocovariances. Closed form: the ratio.
ar <- 0.7; ma_r <- 0.4                        # R sign for ARMAacf
g  <- ARMAacf(ar = ar, ma = ma_r, lag.max = 400) *
      (1 + 2*ar*ma_r + ma_r^2) / (1 - ar^2)   # gamma_k = rho_k * gamma_0
f_def <- spectrum_from_acov(as.numeric(g), FREQ)
f_cf  <- arma_spectrum(ma_poly = c(1, ma_r), ar_poly = c(1, -ar), sigma2 = 1)
cat("closed form vs definition, max abs difference:",
    signif(max(abs(f_def - f_cf)), 3), "\n")
cat("(they are the same function; the closed form is just far cheaper)\n\n")

# EXERCISE 1: AR(1) -- peaks follow the root ------------------------------
op <- par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))
plot(NA, xlim = c(0, 0.5), ylim = c(0.005, 5), log = "y", xlab = "cycles/period",
     ylab = "spectrum", main = "AR(1): where does the power sit?")
cols <- c("steelblue", "firebrick", "darkgreen")
for (i in seq_along(c(0.5, 0.9, -0.9))) {
  p <- c(0.5, 0.9, -0.9)[i]
  lines(FREQ, arma_spectrum(ar_poly = c(1, -p)), col = cols[i], lwd = 2)
}
legend("top", paste("phi =", c(0.5, 0.9, -0.9)), col = cols, lwd = 2, bty = "n", cex = 0.8)

# EXERCISE 2: AR(2) with complex roots -- a peak AT the root's angle -------
plot(NA, xlim = c(0, 0.5), ylim = c(0.01, 50), log = "y", xlab = "cycles/period",
     ylab = "spectrum", main = "AR(2), roots at angle 2pi/12")
for (i in seq_along(c(0.80, 0.92, 0.98))) {
  r <- c(0.80, 0.92, 0.98)[i]
  a1 <- 2 * r * cos(2*pi/12); a2 <- -r^2
  lines(FREQ, arma_spectrum(ar_poly = c(1, -a1, -a2)), col = cols[i], lwd = 2)
}
abline(v = 1/12, lty = 2)
legend("topright", paste("modulus", c(0.80, 0.92, 0.98)), col = cols, lwd = 2, bty = "n", cex = 0.8)
par(op)
cat("AR roots near the unit circle => PEAKS. The closer to the circle, the\n")
cat("sharper. At modulus exactly 1 the peak becomes infinite (see 30-04).\n")
# Where exactly is the peak? NOT at the root angle unless the modulus -> 1.
for (r in c(0.80, 0.92, 0.98)) {
  s <- arma_spectrum(ar_poly = c(1, -2 * r * cos(2*pi/12), r^2))
  i <- which.max(s)
  cat(sprintf("  modulus %.2f: peak at f = %.4f (%+.4f from 1/12), height %7.2f\n",
              r, FREQ[i], FREQ[i] - 1/12, s[i]))
}
cat("The peak sits BELOW the root frequency and climbs onto it as r -> 1,\n")
cat("while its height grows without bound. Read a period off a broad peak\n")
cat("and you will read it slightly wrong.\n\n")

# EXERCISE 3: MA roots => troughs, and unit MA root => exact zero ---------
op <- par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))
plot(NA, xlim = c(0, 0.5), ylim = c(0, 0.8), xlab = "cycles/period", ylab = "spectrum",
     main = "MA(1): theta=1 gives an EXACT zero at freq 0")
for (i in seq_along(c(0.5, 0.9, 1.0))) {
  th <- c(0.5, 0.9, 1.0)[i]                    # Census sign: theta(B) = 1 - th B
  lines(FREQ, arma_spectrum(ma_poly = c(1, -th)), col = cols[i], lwd = 2)
}
legend("topleft", paste("theta =", c(0.5, 0.9, 1.0)), col = cols, lwd = 2, bty = "n", cex = 0.8)
# Near the circle is NOT on it: f(0) = (1-theta)^2 / 2pi, zero only at theta = 1.
for (th in c(0.5, 0.9, 1.0))
  cat(sprintf("  theta = %.1f : spectrum at freq 0 = %.4f  (theory (1-th)^2/2pi = %.4f)\n",
              th, arma_spectrum(ma_poly = c(1, -th), freq = 0), (1 - th)^2 / (2*pi)))
cat("Only theta = 1 -- the root ON the circle -- gives an EXACT zero.\n")

# (1 - B^12) AS A FILTER: zeros at all six seasonal freqs AND at 0 --------
s12 <- arma_spectrum(ma_poly = c(1, rep(0, 11), -1))
plot(FREQ, s12, type = "l", lwd = 2, xlab = "cycles/month", ylab = "spectrum",
     main = "(1 - B^12) as an MA: 7 zeros")
mark_seasonal_freq(); abline(v = 0, col = "firebrick", lty = 3)
par(op)
cat("\nvalue of |1-B^12|^2 spectrum at the six seasonal frequencies:\n")
print(signif(arma_spectrum(ma_poly = c(1, rep(0,11), -1), freq = SEAS_F), 3))
cat("and at frequency 0:", signif(arma_spectrum(ma_poly = c(1, rep(0,11), -1), freq = 0), 3), "\n")
cat("Seasonal differencing is a filter whose gain is zero exactly where the\n")
cat("seasonal lives. No magic.\n\n")

# EXERCISE 4: theory vs data for the airline model ------------------------
fit <- arima(lap, c(0,1,1), list(order = c(0,1,1), period = 12))
th  <- ma_r_to_census(coef(fit)["ma1"]); Th <- ma_r_to_census(coef(fit)["sma1"])
cat(sprintf("fitted (Census): theta = %.3f, Theta = %.3f, sigma2 = %.5f\n",
            th, Th, fit$sigma2))
d  <- diff(diff(lap), 12)
sp <- spec.pgram(d, spans = c(3,3), taper = 0.1, plot = FALSE)
theo <- arma_spectrum(ma_poly = airline_ma(th, Th), sigma2 = fit$sigma2, freq = sp$freq)
plot(sp$freq, log(sp$spec), type = "l", col = "grey55", xlab = "cycles/month",
     ylab = "log spectrum", main = "differenced airline: data vs fitted model")
lines(sp$freq, log(theo * 2 * pi), col = "firebrick", lwd = 2)
mark_seasonal_freq("grey80")
legend("bottomleft", c("smoothed periodogram", "theoretical, fitted model"),
       col = c("grey55", "firebrick"), lwd = 2, bty = "n", cex = 0.8)
cat("The fitted model reproduces the broad shape -- that is what 'the model fits'\n")
cat("means in the frequency domain.\n")
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/30-03-spectrum-of-an-arma.R")
```

Back to [[30-03-spectrum-of-an-arma]] · index: [[code-index]]
