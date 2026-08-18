---
aliases: [30-05-filters-in-the-frequency-domain.R]
tags: [code, generated]
---

# `R/30-05-filters-in-the-frequency-domain.R`

Filtering multiplies the spectrum by the squared gain.

> [!info] Generated file
> Mirror of `R/30-05-filters-in-the-frequency-domain.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[30-05-filters-in-the-frequency-domain]]

```r
# 30-05 -- Filtering multiplies the spectrum by the squared gain.
source("R/_setup.R"); source("R/_spectral.R"); source("R/_x11.R")
set.seed(202)

# EXERCISE 1: the gain of (1-B) ------------------------------------------
g_num <- sqrt(sq_gain_poly(c(1, -1), FREQ))
g_thy <- 2 * abs(sin(pi * FREQ))              # 2|sin(w/2)|, w = 2*pi*f
cat("gain of (1-B): numerical vs 2|sin(w/2)|, max diff:",
    signif(max(abs(g_num - g_thy)), 3), "\n")
cat("  at freq 0   :", round(g_num[1], 6), " (annihilates the trend)\n")
cat("  at freq 0.5 :", round(tail(g_num, 1), 6), " (AMPLIFIES by 2)\n\n")

op <- par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))
plot(FREQ, g_num, type = "l", lwd = 2, xlab = "cycles/period", ylab = "gain",
     main = "(1-B): zero at 0, gain 2 at Nyquist")
abline(h = c(0, 1, 2), col = "grey85")

# EXERCISE 2: the gain of (1-B^12) ---------------------------------------
g12 <- sqrt(sq_gain_poly(c(1, rep(0, 11), -1), FREQ))
plot(FREQ, g12, type = "l", lwd = 2, xlab = "cycles/month", ylab = "gain",
     main = "(1-B^12): seven zeros")
mark_seasonal_freq(); abline(v = 0, col = "firebrick", lty = 3)
par(op)
cat("zeros of the (1-B^12) gain at the seasonal frequencies:",
    signif(sqrt(sq_gain_poly(c(1, rep(0,11), -1), SEAS_F)), 3), "\n")
cat("and at frequency 0:", signif(sqrt(sq_gain_poly(c(1, rep(0,11), -1), 0)), 3), "\n\n")

# EXERCISE 3: differencing whitens by BOOSTING the high end --------------
w  <- rnorm(4000)
dw <- diff(w)
s1 <- spec.pgram(w,  spans = c(15,15), taper = 0, plot = FALSE, detrend = FALSE)
s2 <- spec.pgram(dw, spans = c(15,15), taper = 0, plot = FALSE, detrend = FALSE)
plot(s1$freq, s1$spec, type = "l", lwd = 2, ylim = c(0, 5), xlab = "cycles/period",
     ylab = "power", main = "white noise, before and after differencing")
lines(s2$freq, s2$spec, col = "firebrick", lwd = 2)
lines(FREQ, sq_gain_poly(c(1, -1), FREQ) * 1, col = "steelblue", lwd = 2, lty = 2)
legend("topleft", c("white noise", "differenced", "predicted: |1-B|^2"),
       col = c("black", "firebrick", "steelblue"), lwd = 2, lty = c(1,1,2), bty = "n", cex = 0.8)
cat("Differenced white noise is NOT white: power rises to 4x at the Nyquist\n")
cat("frequency, exactly |1 - e^{-iw}|^2. Over-differencing looks noisier for\n")
cat("a concrete reason.\n\n")

# EXERCISE 4: X-11's composite gain vs the ideal notch filter ------------
n <- 241; mid <- 121
imp <- ts(rep(1, n), frequency = 12); imp[mid] <- 2
wts <- as.numeric(x11_decompose(imp, extreme = FALSE)$d11) - 1
half <- 72; ww <- wts[(mid - half):(mid + half)]
g_x11 <- gain(ww, FREQ)

plot(FREQ, g_x11, type = "l", lwd = 2, xlab = "cycles/month", ylab = "gain",
     main = "X-11 composite SA filter vs the ideal notch")
segments(0, 1, 0.5, 1, col = "grey60", lwd = 2, lty = 2)
for (v in SEAS_F) segments(v, 0, v, 1, col = "firebrick", lty = 3)
points(SEAS_F, rep(0, 6), pch = 19, col = "firebrick")
legend("bottomleft", c("X-11 (real)", "ideal (unattainable)"),
       col = c("black", "grey60"), lwd = 2, lty = c(1,2), bty = "n", cex = 0.8)
cat("gain at the seasonal frequencies:", round(gain(ww, SEAS_F), 4), "\n")
cat("gain midway between the first two:", round(gain(ww, 0.125), 4), "\n")
cat("The real filter has notches of finite WIDTH -- it necessarily destroys some\n")
cat("non-seasonal power near each seasonal frequency. No filter avoids this.\n\n")

# EXERCISE 5: phase, symmetric vs one-sided ------------------------------
sym <- henderson(13)
one <- c(rep(0, 6), sym[7:13]); one <- one / sum(one)   # past-only, renormalised
cat("max |phase| over frequencies:\n")
cat("  symmetric 13-term Henderson:", signif(max(abs(phase(sym, FREQ))), 3), "\n")
cat("  one-sided version          :", round(max(abs(phase(one, FREQ))), 3), "\n")
cat("Nonzero phase = cycles shifted in time = turning points moved.\n")
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/30-05-filters-in-the-frequency-domain.R")
```

Back to [[30-05-filters-in-the-frequency-domain]] · index: [[code-index]]
