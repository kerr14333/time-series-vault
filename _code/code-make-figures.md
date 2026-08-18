---
aliases: [make-figures.R]
tags: [code, generated]
---

# `R/make-figures.R`

Regenerate every PNG embedded in the notes.

> [!info] Generated file
> Mirror of `R/make-figures.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> No concept note; this is a shared helper.

```r
# make-figures.R -- regenerate every PNG embedded in the notes.
# Run from the vault root:  source("R/make-figures.R")
source("R/_setup.R"); source("R/_x11.R")

dir.create("figures", showWarnings = FALSE)
png_ <- function(name, w = 1600, h = 950) {
  png(file.path("figures", name), width = w, height = h, res = 150)
  par(mar = c(4.2, 4.2, 3, 1), cex.main = 1.05)
}
mark_seasonal <- function() abline(v = SEAS_FREQ, col = "firebrick", lty = 3)

f <- seq(0, 0.5, length.out = 1001)

# --- 20-01: what a gain function is ----------------------------------------
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

# --- 20-02: the 2x12 MA ----------------------------------------------------
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

# --- 20-03: Henderson ------------------------------------------------------
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

# --- 20-04: seasonal MAs ---------------------------------------------------
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

# --- 20-05: the decomposition and the composite filter ---------------------
d <- x11_decompose(AirPassengers)
png_("20-05-decomposition.png", h = 1400)
par(mfrow = c(4, 1), mar = c(2.5, 4.2, 2, 1))
plot(AirPassengers, ylab = "Z", main = "original series")
plot(d$d11, ylab = "D11", main = "D11 seasonally adjusted"); lines(d$d12, col = "firebrick", lwd = 2)
legend("topleft", c("D11", "D12 trend"), col = c("black", "firebrick"), lwd = 2, bty = "n")
plot(d$d10, ylab = "D10", main = "D10 seasonal factors"); abline(h = 1, col = "grey60")
plot(d$d13, ylab = "D13", main = "D13 irregular"); abline(h = 1, col = "grey60")
dev.off()

# composite filter by the impulse-response trick
imp <- ts(c(rep(1, 120), 2, rep(1, 120)), frequency = 12)   # multiplicative: spike of +1
resp <- x11_decompose(imp, extreme = FALSE)$d11
wts <- as.numeric(resp) - 1
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

# --- 20-06: extreme values -------------------------------------------------
z2 <- AirPassengers; z2[61] <- z2[61] * 1.30          # +30% spike, Jan 1954
a <- x11_decompose(AirPassengers, extreme = TRUE)
b <- x11_decompose(z2, extreme = TRUE)
cc <- x11_decompose(z2, extreme = FALSE)
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

# --- 20-07: end filters ----------------------------------------------------
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

cat("figures written to figures/:\n"); print(list.files("figures"))
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/make-figures.R")
```

Index: [[code-index]]
