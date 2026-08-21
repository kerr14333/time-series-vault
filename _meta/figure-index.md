---
aliases: [Figure index, Figures, Appendix]
tags: [meta, generated, appendix]
---

# Appendix: every figure, and the code that made it

**Generated** by `R/make-figure-index.R` — do not edit by hand. Every PNG in the vault comes from exactly one block of [[code-make-figures|`R/make-figures.R`]], between a `png_()` call and its `dev.off()`. Regenerate the images with `Rscript R/make-figures.R`, then this page with `Rscript R/make-figure-index.R`.

17 figures, all produced by one script.

| Figure | Appears in | Lines in `make-figures.R` |
|---|---|---|
| [[#20-01-gain-basics.png]] | [[20-01-moving-averages-as-filters]] | 15–26 |
| [[#20-02-2x12-gain.png]] | [[20-02-the-12-term-ma]] | 29–39 |
| [[#20-03-henderson.png]] | [[20-03-henderson-filters]] | 42–61 |
| [[#20-04-seasonal-ma.png]] | [[20-04-seasonal-moving-averages]] | 64–84 |
| [[#20-05-decomposition.png]] | [[20-05-the-x11-iteration]] | 88–95 |
| [[#20-05-composite-gain.png]] | [[20-05-the-x11-iteration]] | 101–112 |
| [[#20-06-extreme-values.png]] | [[20-06-extreme-values]] | 119–132 |
| [[#20-07-end-filters.png]] | [[20-07-end-filters]] | 135–157 |
| [[#30-01-harmonics.png]] | [[30-01-frequency-domain-basics]] | 164–176 |
| [[#30-03-arma-spectra.png]] | [[30-03-spectrum-of-an-arma]] | 179–195 |
| [[#30-04-pseudo-spectrum.png]] | [[30-04-pseudo-spectrum]] | 198–211 |
| [[#30-05-differencing-gain.png]] | [[30-05-filters-in-the-frequency-domain]] | 214–222 |
| [[#30-06-wk-gain.png]] | [[30-06-wiener-kolmogorov]] | 225–242 |
| [[#40-04-spectrum-split.png]] | [[40-04-partial-fractions-in-b-and-f]] | 258–269 |
| [[#40-06-seats-filters.png]] | [[40-06-wk-filters-for-the-airline-model]] | 272–290 |
| [[#40-07-decomposition.png]] | [[40-07-implementing-seats-in-r]] | 293–303 |
| [[#50-06-turning-points.png]] | [[50-06-turning-points]] | 323–335 |

---

## 20-01-gain-basics.png

*20-01: what a gain function is*

![[20-01-gain-basics.png]]

Embedded in: [[20-01-moving-averages-as-filters]]

Drawn by `R/make-figures.R`, lines 15–26:

```r
png_("20-01-gain-basics.png")
par(mfrow = c(1, 2))
w3 <- rep(1, 3) / 3
plot(f, gain(w3, f), type = "l", lwd = 2, ylim = c(0, 1.05),
     xlab = "frequency (cycles/month)", ylab = "gain",
     main = "3-term MA: gain")
abline(h = c(0, 1), col = "grey85"); abline(v = 1/3, col = "firebrick", lty = 2)
text(1/3, 0.5, "zero at 1/3", pos = 4, col = "firebrick", cex = 0.8)
plot(f, phase(w3, f), type = "l", lwd = 2, xlab = "frequency (cycles/month)",
     ylab = "phase (radians)", main = "3-term MA: phase is 0 (symmetric)")
abline(h = 0, col = "grey85")
dev.off()
```

---

## 20-02-2x12-gain.png

*20-02: the 2x12 MA*

![[20-02-2x12-gain.png]]

Embedded in: [[20-02-the-12-term-ma]]

Drawn by `R/make-figures.R`, lines 29–39:

```r
png_("20-02-2x12-gain.png")
par(mfrow = c(1, 2))
w12 <- ma_2x12()
plot(-6:6, w12, type = "h", lwd = 6, col = "steelblue", xlab = "lag j", ylab = "weight",
     main = "2x12 MA weights: (1,2,...,2,1)/24")
abline(h = 0, col = "grey70")
plot(f, gain(w12, f), type = "l", lwd = 2, ylim = c(-0.05, 1.05),
     xlab = "frequency (cycles/month)", ylab = "gain",
     main = "gain: EXACTLY zero at every seasonal frequency")
abline(h = 0, col = "grey85"); mark_seasonal()
dev.off()
```

---

## 20-03-henderson.png

*20-03: Henderson*

![[20-03-henderson.png]]

Embedded in: [[20-03-henderson-filters]]

Drawn by `R/make-figures.R`, lines 42–61:

```r
png_("20-03-henderson.png")
par(mfrow = c(1, 2))
cols <- c("steelblue", "firebrick", "darkgreen")
plot(NA, xlim = c(-11, 11), ylim = c(-0.06, 0.35), xlab = "lag j", ylab = "weight",
     main = "Henderson weights: 9, 13, 23 terms")
abline(h = 0, col = "grey70")
for (i in seq_along(c(9, 13, 23))) {
  L <- c(9, 13, 23)[i]; m <- (L - 1) / 2
  lines(-m:m, henderson(L), type = "b", pch = 19, col = cols[i], lwd = 2)
}
legend("topright", paste(c(9, 13, 23), "term"), col = cols, lwd = 2, bty = "n")
plot(NA, xlim = c(0, 0.5), ylim = c(-0.1, 1.05), xlab = "frequency (cycles/month)",
     ylab = "gain", main = "Henderson gain: 0.85 at the ANNUAL frequency")
abline(h = c(0, 1), col = "grey85"); mark_seasonal()
for (i in seq_along(c(9, 13, 23)))
  lines(f, gain(henderson(c(9, 13, 23)[i]), f), col = cols[i], lwd = 2)
points(1/12, gain(henderson(13), 1/12), pch = 19, cex = 1.4)
text(1/12, gain(henderson(13), 1/12), " 0.85 -- barely touched", pos = 4, cex = 0.8)
legend("topright", paste(c(9, 13, 23), "term"), col = cols, lwd = 2, bty = "n")
dev.off()
```

---

## 20-04-seasonal-ma.png

*20-04: seasonal MAs*

![[20-04-seasonal-ma.png]]

Embedded in: [[20-04-seasonal-moving-averages]]

Drawn by `R/make-figures.R`, lines 64–84:

```r
png_("20-04-seasonal-ma.png")
par(mfrow = c(1, 2))
plot(NA, xlim = c(-5, 5), ylim = c(0, 0.25), xlab = "lag (YEARS, same calendar month)",
     ylab = "weight", main = "seasonal MA weights")
abline(h = 0, col = "grey70")
for (i in seq_along(c("3x3", "3x5", "3x9"))) {
  w <- seasonal_ma(c("3x3", "3x5", "3x9")[i]); m <- (length(w) - 1) / 2
  lines(-m:m, w, type = "b", pch = 19, col = cols[i], lwd = 2)
}
legend("topright", c("3x3", "3x5", "3x9"), col = cols, lwd = 2, bty = "n")
si <- AirPassengers / na_fill_ends(symfilter(AirPassengers, ma_2x12()))
jan <- as.numeric(si)[seq(1, length(si), by = 12)]
plot(1949:1960, jan, type = "b", pch = 19, col = "grey40",
     xlab = "year", ylab = "SI ratio", main = "January SI ratios, smoothed")
for (i in 1:2) {
  w <- seasonal_ma(c("3x3", "3x5")[i])
  sm <- as.numeric(stats::filter(jan, w, sides = 2))
  lines(1949:1960, sm, col = cols[i], lwd = 3)
}
legend("topright", c("raw SI", "3x3", "3x5"), col = c("grey40", cols[1:2]), lwd = 2, bty = "n")
dev.off()
```

---

## 20-05-decomposition.png

*20-05: the decomposition and the composite filter*

![[20-05-decomposition.png]]

Embedded in: [[20-05-the-x11-iteration]]

Drawn by `R/make-figures.R`, lines 88–95:

```r
png_("20-05-decomposition.png", h = 1400)
par(mfrow = c(4, 1), mar = c(2.5, 4.2, 2, 1))
plot(AirPassengers, ylab = "Z", main = "original series")
plot(d$d11, ylab = "D11", main = "D11 seasonally adjusted"); lines(d$d12, col = "firebrick", lwd = 2)
legend("topleft", c("D11", "D12 trend"), col = c("black", "firebrick"), lwd = 2, bty = "n")
plot(d$d10, ylab = "D10", main = "D10 seasonal factors"); abline(h = 1, col = "grey60")
plot(d$d13, ylab = "D13", main = "D13 irregular"); abline(h = 1, col = "grey60")
dev.off()
```

---

## 20-05-composite-gain.png

*20-05: the decomposition and the composite filter*

![[20-05-composite-gain.png]]

Embedded in: [[20-05-the-x11-iteration]]

Drawn by `R/make-figures.R`, lines 101–112:

```r
png_("20-05-composite-gain.png")
par(mfrow = c(1, 2))
k <- 100:142
plot(k - 121, wts[k], type = "h", lwd = 3, col = "steelblue", xlab = "lag",
     ylab = "weight", main = "X-11 composite SA filter (impulse response)")
abline(h = 0, col = "grey70")
half <- 60
ww <- wts[(121 - half):(121 + half)]
plot(f, gain(ww, f), type = "l", lwd = 2, xlab = "frequency (cycles/month)",
     ylab = "gain", main = "composite gain: notches at seasonal frequencies")
abline(h = c(0, 1), col = "grey85"); mark_seasonal()
dev.off()
```

---

## 20-06-extreme-values.png

*20-06: extreme values*

![[20-06-extreme-values.png]]

Embedded in: [[20-06-extreme-values]]

Drawn by `R/make-figures.R`, lines 119–132:

```r
png_("20-06-extreme-values.png")
par(mfrow = c(1, 2))
jn <- seq(1, 144, by = 12)
plot(1949:1960, as.numeric(a$d10)[jn], type = "b", pch = 19, ylim = range(
  c(as.numeric(a$d10)[jn], as.numeric(cc$d10)[jn])),
  xlab = "year", ylab = "January seasonal factor",
  main = "one +30% spike in Jan 1954")
lines(1949:1960, as.numeric(b$d10)[jn], type = "b", pch = 19, col = "steelblue")
lines(1949:1960, as.numeric(cc$d10)[jn], type = "b", pch = 19, col = "firebrick")
legend("topleft", c("clean", "spiked, extremes handled", "spiked, NOT handled"),
       col = c("black", "steelblue", "firebrick"), lwd = 2, bty = "n", cex = 0.8)
plot(window(b$d11, start = c(1953, 1), end = c(1955, 12)), ylab = "D11",
     main = "the spike SURVIVES in D11 (as it should)", lwd = 2)
dev.off()
```

---

## 20-07-end-filters.png

*20-07: end filters*

![[20-07-end-filters.png]]

Embedded in: [[20-07-end-filters]]

Drawn by `R/make-figures.R`, lines 135–157:

```r
png_("20-07-end-filters.png")
h13 <- henderson(13)
trunc_renorm <- function(w, future_kept) {
  m <- (length(w) - 1) / 2
  keep <- (-m):future_kept
  v <- w[seq_along(w)[(-m):m %in% keep]]
  v / sum(v)
}
plot(NA, xlim = c(-6, 6), ylim = c(-0.1, 0.55), xlab = "lag j (negative = past)",
     ylab = "weight", main = "13-term Henderson: symmetric vs end filters")
abline(h = 0, col = "grey70"); abline(v = 0, col = "grey85", lty = 2)
lines(-6:6, h13, type = "b", pch = 19, lwd = 2)
for (i in 1:2) {
  fk <- c(0, 2)[i]
  v <- trunc_renorm(h13, fk)
  lines(-6:fk, v, type = "b", pch = 17, col = cols[i], lwd = 2)
}
legend("topleft", c("symmetric (interior)", "last point: no future at all",
                    "2 months from the end"),
       col = c("black", cols[1:2]), lwd = 2, bty = "n", cex = 0.85)
mtext("simple truncate-and-renormalise surrogate; X-11 uses Musgrave's minimum-revision weights",
      side = 1, line = 2.8, cex = 0.7)
dev.off()
```

---

## 30-01-harmonics.png

*30-01: harmonics*

![[30-01-harmonics.png]]

Embedded in: [[30-01-frequency-domain-basics]]

Drawn by `R/make-figures.R`, lines 164–176:

```r
png_("30-01-harmonics.png")
par(mfrow = c(1, 2))
tt <- 1:96
pure  <- sin(2 * pi * tt / 12)
spiky <- pure + 0.4 * sin(2 * pi * tt / 6) + 0.3 * sin(2 * pi * tt / 4) + 0.2 * sin(2 * pi * tt / 3)
plot(ts(pure, frequency = 12), ylab = "", main = "pure sine (one frequency)")
lines(ts(spiky, frequency = 12), col = "firebrick", lwd = 2)
legend("topright", c("pure", "with harmonics"), col = c("black", "firebrick"), lwd = 2, bty = "n", cex = 0.8)
s <- spec.pgram(ts(spiky, frequency = 1), taper = 0, plot = FALSE, detrend = FALSE)
plot(s$freq, s$spec, type = "h", lwd = 3, col = "steelblue", log = "y",
     xlab = "cycles/month", ylab = "power", main = "power at 1/12, 1/6, 1/4, 1/3")
mark_seasonal_freq()
dev.off()
```

---

## 30-03-arma-spectra.png

*30-03: AR peaks, MA troughs*

![[30-03-arma-spectra.png]]

Embedded in: [[30-03-spectrum-of-an-arma]]

Drawn by `R/make-figures.R`, lines 179–195:

```r
png_("30-03-arma-spectra.png")
par(mfrow = c(1, 2))
cols3 <- c("steelblue", "firebrick", "darkgreen")
plot(NA, xlim = c(0, 0.5), ylim = c(0.01, 50), log = "y", xlab = "cycles/period",
     ylab = "spectrum", main = "AR roots near the circle => PEAKS")
for (i in seq_along(c(0.80, 0.92, 0.98))) {
  r <- c(0.80, 0.92, 0.98)[i]
  lines(FREQ, arma_spectrum(ar_poly = c(1, -2 * r * cos(2 * pi / 12), r^2)), col = cols3[i], lwd = 2)
}
abline(v = 1/12, lty = 2)
legend("topright", paste("modulus", c(0.80, 0.92, 0.98)), col = cols3, lwd = 2, bty = "n", cex = 0.8)
plot(NA, xlim = c(0, 0.5), ylim = c(0, 0.8), xlab = "cycles/period", ylab = "spectrum",
     main = "MA root ON the circle => exact ZERO")
for (i in seq_along(c(0.5, 0.9, 1.0)))
  lines(FREQ, arma_spectrum(ma_poly = c(1, -c(0.5, 0.9, 1.0)[i])), col = cols3[i], lwd = 2)
legend("topleft", paste("theta =", c(0.5, 0.9, 1.0)), col = cols3, lwd = 2, bty = "n", cex = 0.8)
dev.off()
```

---

## 30-04-pseudo-spectrum.png

*30-04: the airline pseudo-spectrum*

![[30-04-pseudo-spectrum.png]]

Embedded in: [[30-04-pseudo-spectrum]]

Drawn by `R/make-figures.R`, lines 198–211:

```r
png_("30-04-pseudo-spectrum.png")
par(mfrow = c(1, 2))
plot(ff, arma_spectrum(ma_poly = airline_ma(0.4, 0.6), ar_poly = airline_ar(), freq = ff),
     type = "l", lwd = 2, log = "y", xlab = "cycles/month", ylab = "pseudo-spectrum",
     main = "airline model: seven infinite peaks")
mark_seasonal_freq(); abline(v = 0, col = "firebrick", lty = 3)
plot(NA, xlim = c(0.05, 0.12), ylim = c(1e-3, 1e3), log = "y", xlab = "cycles/month",
     ylab = "pseudo-spectrum", main = "Theta sets the peak WIDTH")
for (i in seq_along(c(0.2, 0.6, 0.95)))
  lines(ff, arma_spectrum(ma_poly = airline_ma(0.4, c(0.2, 0.6, 0.95)[i]),
                          ar_poly = airline_ar(), freq = ff), col = cols3[i], lwd = 2)
abline(v = 1/12, lty = 2)
legend("topright", paste("Theta =", c(0.2, 0.6, 0.95)), col = cols3, lwd = 2, bty = "n", cex = 0.8)
dev.off()
```

---

## 30-05-differencing-gain.png

*30-05: differencing as a filter*

![[30-05-differencing-gain.png]]

Embedded in: [[30-05-filters-in-the-frequency-domain]]

Drawn by `R/make-figures.R`, lines 214–222:

```r
png_("30-05-differencing-gain.png")
par(mfrow = c(1, 2))
plot(FREQ, sqrt(sq_gain_poly(c(1, -1), FREQ)), type = "l", lwd = 2, xlab = "cycles/period",
     ylab = "gain", main = "(1-B): kills the trend, AMPLIFIES the high end")
abline(h = c(0, 1, 2), col = "grey85")
plot(FREQ, sqrt(sq_gain_poly(c(1, rep(0, 11), -1), FREQ)), type = "l", lwd = 2,
     xlab = "cycles/month", ylab = "gain", main = "(1-B^12): seven zeros")
mark_seasonal_freq(); abline(v = 0, col = "firebrick", lty = 3)
dev.off()
```

---

## 30-06-wk-gain.png

*30-06: the WK gain*

![[30-06-wk-gain.png]]

Embedded in: [[30-06-wiener-kolmogorov]]

Drawn by `R/make-figures.R`, lines 225–242:

```r
png_("30-06-wk-gain.png")
par(mfrow = c(1, 2))
fw <- seq(1e-4, 0.5, length.out = 2000)
mk <- function(sn) {
  fs <- arma_spectrum(ar_poly = c(1, -1), sigma2 = 1, freq = fw)
  wk_gain(fs, fs + sn^2 / (2 * pi))
}
plot(NA, xlim = c(0, 0.5), ylim = c(0, 1), xlab = "cycles/period", ylab = "gain",
     main = "WK gain = share of power that is yours")
for (i in seq_along(c(0.5, 1, 2, 4)))
  lines(fw, mk(c(0.5, 1, 2, 4)[i]), col = c(cols3, "purple")[i], lwd = 2)
legend("topright", paste("noise sd =", c(0.5, 1, 2, 4)),
       col = c(cols3, "purple"), lwd = 2, bty = "n", cex = 0.8)
wq <- wk_weights(mk(2), fw, max_lag = 40)
plot(0:40, wq, type = "h", lwd = 3, col = "steelblue", xlab = "lag |j|", ylab = "weight",
     main = "its weights: symmetric, decaying, INFINITE")
abline(h = 0, col = "grey70")
dev.off()
```

---

## 40-04-spectrum-split.png

*40-04: the spectrum split into three*

![[40-04-spectrum-split.png]]

Embedded in: [[40-04-partial-fractions-in-b-and-f]]

Drawn by `R/make-figures.R`, lines 258–269:

```r
png_("40-04-spectrum-split.png")
wq <- seq(0.04, pi - 0.04, length.out = 3000)
gz <- cospoly_eval(pf4$N, wq) / (cospoly_eval(pf4$DT, wq) * cospoly_eval(pf4$DS, wq))
plot(wq, gz, type = "l", lwd = 3, log = "y", ylim = c(1e-3, 5e2), xlab = "omega (radians)",
     ylab = "pseudo-spectrum", main = "the airline pseudo-spectrum, split by partial fractions")
lines(wq, cospoly_eval(pf4$A, wq) / cospoly_eval(pf4$DT, wq), col = "firebrick", lwd = 2)
lines(wq, cospoly_eval(pf4$C, wq) / cospoly_eval(pf4$DS, wq), col = "steelblue", lwd = 2)
abline(h = pf4$Dc[1], col = "darkgreen", lwd = 2)
abline(v = 2 * pi * (1:6) / 12, lty = 3, col = "grey65")
legend("topright", c("f_z total", "trend", "seasonal", "irregular"),
       col = c("black", "firebrick", "steelblue", "darkgreen"), lwd = 2, bty = "n", cex = 0.8)
dev.off()
```

---

## 40-06-seats-filters.png

*40-06: the three component filters*

![[40-06-seats-filters.png]]

Embedded in: [[40-06-wk-filters-for-the-airline-model]]

Drawn by `R/make-figures.R`, lines 272–290:

```r
png_("40-06-seats-filters.png")
par(mfrow = c(1, 2))
w4 <- seq(1e-8, pi - 1e-8, length.out = 3000)
nu4 <- seats_filters(cn4, w4)
plot(w4, nu4$trend, type = "l", lwd = 2, col = "firebrick", ylim = c(0, 1.05),
     xlab = "omega", ylab = "gain", main = "SEATS component filters (sum to 1)")
lines(w4, nu4$seasonal, col = "steelblue", lwd = 2)
lines(w4, nu4$irregular, col = "darkgreen", lwd = 2)
abline(v = 2 * pi * (1:6) / 12, lty = 3, col = "grey65")
legend("right", c("trend", "seasonal", "irregular"),
       col = c("firebrick", "steelblue", "darkgreen"), lwd = 2, bty = "n", cex = 0.8)
plot(NA, xlim = c(0, pi), ylim = c(0, 1.05), xlab = "omega", ylab = "gain",
     main = "Theta sets the notch WIDTH")
cl <- c("steelblue", "darkgreen", "firebrick")
for (i in seq_along(c(0.3, 0.6, 0.9)))
  lines(w4, seats_filters(build4(0.4, c(0.3, 0.6, 0.9)[i]), w4)$seasonal, col = cl[i], lwd = 2)
abline(v = 2 * pi * (1:6) / 12, lty = 3, col = "grey70")
legend("right", paste("Theta =", c(0.3, 0.6, 0.9)), col = cl, lwd = 2, bty = "n", cex = 0.8)
dev.off()
```

---

## 40-07-decomposition.png

*40-07: the finished decomposition*

![[40-07-decomposition.png]]

Embedded in: [[40-07-implementing-seats-in-r]]

Drawn by `R/make-figures.R`, lines 293–303:

```r
png_("40-07-decomposition.png", h = 1400)
d4 <- seats_decompose(AirPassengers, th4, Th4)
par(mfrow = c(4, 1), mar = c(2.5, 4.2, 2, 1))
plot(log(AirPassengers), ylab = "log z", main = "SEATS decomposition of log(AirPassengers)")
lines(d4$trend, col = "firebrick", lwd = 2)
legend("topleft", c("log z", "trend"), col = c("black", "firebrick"), lwd = 2, bty = "n")
plot(d4$sa, ylab = "SA", main = "seasonally adjusted = trend + irregular")
plot(d4$seasonal, ylab = "S", main = "seasonal"); abline(h = 0, col = "grey60")
plot(d4$irregular, ylab = "I", main = "irregular (white by construction)")
abline(h = 0, col = "grey60")
dev.off()
```

---

## 50-06-turning-points.png

*40-07: the finished decomposition*

![[50-06-turning-points.png]]

Embedded in: [[50-06-turning-points]]

Drawn by `R/make-figures.R`, lines 323–335:

```r
  png_("50-06-turning-points.png")
  par(mfrow = c(1, 2))
  plot(tt5, abs(rev5), type = "n", xlab = "", ylab = "|revision| %",
       main = "US unemployment: revisions cluster at recessions")
  for (r in recs) rect(r[1], -1, r[2], 100, col = rgb(1, 0, 0, 0.15), border = NA)
  lines(tt5, abs(rev5), type = "h", lwd = 2, col = "steelblue")
  legend("topleft", c("NBER recession"), fill = rgb(1, 0, 0, 0.15), border = NA, bty = "n", cex = 0.8)
  boxplot(list(`near a\nrecession` = abs(rev5[ok5 & near5]),
               `everywhere\nelse`  = abs(rev5[ok5 & !near5])),
          col = c("firebrick", "grey80"), ylab = "|revision| %",
          main = sprintf("ratio %.2fx",
                         mean(abs(rev5[ok5 & near5])) / mean(abs(rev5[ok5 & !near5]))))
  dev.off()
```

