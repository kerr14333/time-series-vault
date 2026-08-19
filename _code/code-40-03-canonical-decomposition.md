---
aliases: [40-03-canonical-decomposition.R]
tags: [code, generated]
---

# `R/40-03-canonical-decomposition.R`

The canonical rule: give the irregular as much variance as possible.

> [!info] Generated file
> Mirror of `R/40-03-canonical-decomposition.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[40-03-canonical-decomposition]]

```r
# 40-03 -- The canonical rule: give the irregular as much variance as possible.
source("R/_setup.R"); source("R/_spectral.R"); source("R/_seats.R"); source("R/_series.R")

x   <- AirPassengers
fit <- arima(log(x), c(0,1,1), list(order = c(0,1,1), period = 12))
th  <- unname(-coef(fit)["ma1"]); Th <- unname(-coef(fit)["sma1"])

ma <- poly_mult(c(1, -th), c(1, rep(0, 11), -Th))
sp <- seats_ar_split(1, 1, 12)
pf <- seats_partial_fractions(ma, sp$trend, sp$seasonal)
cn <- seats_canonical(pf)

# EXERCISE 1: the two minima ----------------------------------------------
cat(sprintf("fitted: theta = %.4f  Theta = %.4f\n\n", th, Th))
cat("component spectra BEFORE the canonical step:\n")
cat(sprintf("  min trend     = %.4f\n", cn$min_gT))
cat(sprintf("  min seasonal  = %.4f\n", cn$min_gS))
cat(sprintf("  irregular     = %.4f  (a constant)\n", cn$min_gI))
cat("\nAFTER: subtract each minimum, hand it to the irregular\n")
cat(sprintf("  min trend     = 0\n  min seasonal  = 0\n"))
cat(sprintf("  irregular     = %.4f + %.4f + %.4f = %.4f\n",
            cn$min_gI, cn$mT, cn$mS, cn$min_gI + cn$mT + cn$mS))
cat(sprintf("\n%.1f%% of the final irregular variance was taken OUT of the trend\n",
            100 * (cn$mT + cn$mS) / (cn$min_gI + cn$mT + cn$mS)))
cat("and seasonal by this rule. Not a rounding detail.\n\n")

# EXERCISE 2-3: the spectra, before and after -----------------------------
w  <- seq(1e-5, pi - 1e-5, length.out = 4000)
gT <- cospoly_eval(pf$A, w) / cospoly_eval(pf$DT, w)
gS <- cospoly_eval(pf$C, w) / cospoly_eval(pf$DS, w)
gTc <- cospoly_eval(cn$Acan, w) / cospoly_eval(cn$DT, w)
gSc <- cospoly_eval(cn$Ccan, w) / cospoly_eval(cn$DS, w)

op <- par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))
plot(w, gT, type = "l", lwd = 2, log = "y", ylim = c(1e-4, 1e3), xlab = "omega",
     ylab = "spectrum", main = "trend: canonical shift")
lines(w, pmax(gTc, 1e-12), col = "firebrick", lwd = 2)
abline(h = cn$mT, lty = 3)
legend("topright", c("before", "canonical", "the minimum"),
       col = c("black", "firebrick", "black"), lwd = c(2,2,1), lty = c(1,1,3), bty="n", cex=.75)
plot(w, gS, type = "l", lwd = 2, log = "y", ylim = c(1e-4, 1e3), xlab = "omega",
     ylab = "spectrum", main = "seasonal: canonical shift")
lines(w, pmax(gSc, 1e-12), col = "firebrick", lwd = 2)
par(op)

cat("where does each canonical spectrum touch zero?\n")
cat(sprintf("  trend    at omega = %.4f  (pi = %.4f)\n", w[which.min(gTc)], pi))
cat(sprintf("  seasonal at omega = %.4f\n", w[which.min(gSc)]))
cat("A spectrum touching zero IS a unit MA root -- non-invertible BY DESIGN.\n")
cat("Your ARIMA training says that is a bug. Here it is the definition (10-05).\n\n")

# EXERCISE 4: how much smoother is the canonical trend? -------------------
d_can <- seats_decompose(x, th, Th)
d_raw <- local({
  # same pipeline, canonical step disabled: put the minima back
  cn2 <- cn; cn2$Acan <- pf$A; cn2$Ccan <- pf$C; cn2$Dcan <- pf$Dc
  ww  <- seq(1e-8, pi - 1e-8, length.out = 8000)
  nu  <- seats_filters(cn2, ww)
  wt  <- lapply(nu, filter_weights, w = ww, max_lag = 331)
  y   <- log(x)
  f   <- arima(y, c(0,1,1), list(order = c(0,1,1), period = 12))
  fwd <- as.numeric(predict(f, n.ahead = 343)$pred)
  fb  <- arima(ts(rev(as.numeric(y)), frequency = 12), c(0,1,1), list(order=c(0,1,1), period=12))
  bwd <- rev(as.numeric(predict(fb, n.ahead = 343)$pred))
  ext <- c(bwd, as.numeric(y), fwd)
  keep <- 344:(343 + length(y))
  ts(apply_sym_weights(ext, wt$trend)[keep], start = start(x), frequency = 12)
})
cat("roughness of the trend (sd of its first difference, in logs):\n")
cat(sprintf("  canonical      %.6f\n", sd(diff(as.numeric(d_can$trend)))))
cat(sprintf("  non-canonical  %.6f\n", sd(diff(as.numeric(d_raw)))))
cat("The canonical trend is smoother, as advertised: all the variance that\n")
cat("MIGHT be noise has been called noise.\n\n")

plot(log(x), ylab = "log passengers", main = "canonical vs non-canonical trend")
lines(d_can$trend, col = "firebrick", lwd = 2)
lines(d_raw, col = "steelblue", lwd = 2, lty = 2)
legend("topleft", c("log z", "canonical trend", "non-canonical"),
       col = c("black","firebrick","steelblue"), lwd = 2, lty = c(1,1,2), bty="n", cex=.8)

# EXERCISE 6: which series moves most? -----------------------------------
cat("=== how much variance does the canonical rule move? ===\n")
S <- vault_series()
for (nm in names(S)) {
  f <- tryCatch(airline_fit(S[[nm]]), error = function(e) NULL); if (is.null(f)) next
  s <- frequency(S[[nm]])
  r <- tryCatch({
    m2 <- poly_mult(c(1, -f$theta), c(1, rep(0, s - 1), -f$Theta))
    s2 <- seats_ar_split(1, 1, s)
    seats_canonical(seats_partial_fractions(m2, s2$trend, s2$seasonal, ngrid = 1200), 2500)
  }, error = function(e) NULL)
  if (is.null(r)) next
  tot <- r$min_gI + r$mT + r$mS
  cat(sprintf("  %-12s mT+mS = %.4f  -> %4.1f%% of the final irregular\n",
              nm, r$mT + r$mS, 100 * (r$mT + r$mS) / tot))
}
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/40-03-canonical-decomposition.R")
```

Back to [[40-03-canonical-decomposition]] · index: [[code-index]]
