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

# ============================ MODULE 3 =====================================
source("R/_spectral.R")
ff <- seq(1e-4, 0.5 - 1e-4, length.out = 4000)

# --- 30-01: harmonics ------------------------------------------------------
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

# --- 30-03: AR peaks, MA troughs ------------------------------------------
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

# --- 30-04: the airline pseudo-spectrum -----------------------------------
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

# --- 30-05: differencing as a filter --------------------------------------
png_("30-05-differencing-gain.png")
par(mfrow = c(1, 2))
plot(FREQ, sqrt(sq_gain_poly(c(1, -1), FREQ)), type = "l", lwd = 2, xlab = "cycles/period",
     ylab = "gain", main = "(1-B): kills the trend, AMPLIFIES the high end")
abline(h = c(0, 1, 2), col = "grey85")
plot(FREQ, sqrt(sq_gain_poly(c(1, rep(0, 11), -1), FREQ)), type = "l", lwd = 2,
     xlab = "cycles/month", ylab = "gain", main = "(1-B^12): seven zeros")
mark_seasonal_freq(); abline(v = 0, col = "firebrick", lty = 3)
dev.off()

# --- 30-06: the WK gain ----------------------------------------------------
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

cat("figures written to figures/:\n"); print(list.files("figures"))
