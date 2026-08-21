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

# ===== MODULE 1: ARIMA foundations =========================================
colsM1 <- c("steelblue", "firebrick", "darkgreen")

# --- 10-02: roots and the unit circle --------------------------------------
png_("10-02-unit-circle.png")
par(mfrow = c(1, 2))
unit_circle <- function(main) {
  th <- seq(0, 2 * pi, length.out = 400)
  plot(cos(th), sin(th), type = "l", asp = 1, col = "grey55", lwd = 2,
       xlim = c(-2.3, 2.3), ylim = c(-2.3, 2.3), xlab = "Re", ylab = "Im", main = main)
  abline(h = 0, v = 0, col = "grey88")
}
unit_circle("AR(1): the root is 1/phi")
phis <- c(0.5, 0.95, 1.01)
for (i in seq_along(phis)) {
  points(1 / phis[i], 0, pch = 19, col = colsM1[i], cex = 1.6)
  text(1 / phis[i], 0.3, sprintf("phi=%.2f", phis[i]), col = colsM1[i], cex = 0.8)
}
legend("bottomleft", "inside the circle = NOT stationary", bty = "n", cex = 0.75)
unit_circle("AR(2): a complex pair")
rr <- polyroot(c(1, -1.6, 0.9))
points(Re(rr), Im(rr), pch = 19, col = "firebrick", cex = 1.6)
segments(0, 0, Re(rr[1]), Im(rr[1]), col = "firebrick", lty = 2)
text(0, -1.9, "modulus 1.054, just outside: stationary but nearly not", cex = 0.75)
dev.off()

# --- 10-03: persistence you can see ----------------------------------------
png_("10-03-ar-paths.png", h = 1250)
par(mfrow = c(3, 1), mar = c(2.6, 4, 2.4, 1))
set.seed(7)
for (i in seq_along(c(0.5, 0.9, 0.99))) {
  phi <- c(0.5, 0.9, 0.99)[i]
  plot(arima.sim(list(ar = phi), n = 300), type = "l", col = colsM1[i], lwd = 1.5,
       ylab = "", main = sprintf("AR(1), phi = %.2f", phi))
  abline(h = 0, col = "grey70")
}
dev.off()

# --- 10-05: two models, one ACF --------------------------------------------
png_("10-05-invertibility.png")
par(mfrow = c(1, 2))
rho1 <- function(th) -th / (1 + th^2)
th <- seq(-3, 3, length.out = 400)
plot(th, rho1(th), type = "l", lwd = 2, xlab = "theta", ylab = "rho(1)",
     main = "theta and 1/theta give the SAME rho(1)")
abline(h = 0, v = c(-1, 1), col = "grey80", lty = c(1, 2, 2))
points(c(0.5, 2), rho1(c(0.5, 2)), pch = 19, col = "firebrick", cex = 1.4)
text(0.5, rho1(0.5) + 0.06, "0.5", col = "firebrick", cex = 0.8)
text(2, rho1(2) - 0.06, "2", col = "firebrick", cex = 0.8)
j <- 1:10
plot(j, 0.5^j, type = "b", pch = 19, lwd = 2, col = "steelblue", log = "y",
     ylim = c(1e-3, 1e3), xlab = "lag j", ylab = "|pi weight|",
     main = "pi weights: only one choice dies out")
lines(j, 2^j, type = "b", pch = 19, lwd = 2, col = "firebrick")
legend("left", c("theta = 0.5 (invertible)", "theta = 2 (not)"),
       col = c("steelblue", "firebrick"), lwd = 2, bty = "n", cex = 0.8)
dev.off()

# --- 10-06: the differencing ladder ----------------------------------------
png_("10-06-differencing-ladder.png", h = 1500)
par(mfrow = c(4, 1), mar = c(2.6, 4.2, 2.4, 1))
plot(lap, lwd = 1.6, ylab = "log", main = "log AirPassengers: trend AND seasonal")
plot(diff(lap), col = "steelblue", lwd = 1.4, ylab = "",
     main = "(1-B): trend gone, seasonal still there")
abline(h = 0, col = "grey70")
plot(diff(lap, 12), col = "darkgreen", lwd = 1.4, ylab = "",
     main = "(1-B^12): seasonal gone, trend still there")
abline(h = 0, col = "grey70")
plot(diff(diff(lap, 12)), col = "firebrick", lwd = 1.4, ylab = "",
     main = "(1-B)(1-B^12): both gone -- this is what gets modelled")
abline(h = 0, col = "grey70")
dev.off()

# --- 10-07: the identification grid ----------------------------------------
png_("10-07-acf-pacf-grid.png", h = 1250)
par(mfrow = c(2, 2), mar = c(4, 4.2, 3, 1))
set.seed(3)
ar1 <- as.numeric(arima.sim(list(ar = 0.8), n = 3000))
ma1 <- as.numeric(arima.sim(list(ma = -0.8), n = 3000))
acf(ar1,  lag.max = 20, main = "AR(1): ACF DECAYS")
pacf(ar1, lag.max = 20, main = "AR(1): PACF CUTS OFF at lag 1")
acf(ma1,  lag.max = 20, main = "MA(1): ACF CUTS OFF at lag 1")
pacf(ma1, lag.max = 20, main = "MA(1): PACF DECAYS")
dev.off()

# --- 10-09: seasonality in the ACF -----------------------------------------
png_("10-09-seasonal-acf.png")
par(mfrow = c(1, 2), mar = c(4, 4.2, 3, 1))
a1 <- acf(as.numeric(diff(lap)), lag.max = 40, plot = FALSE)
plot(a1, main = "after (1-B): spikes at 12, 24, 36")
abline(v = c(12, 24, 36), col = "firebrick", lty = 3)
a2 <- acf(as.numeric(diff(diff(lap, 12))), lag.max = 40, plot = FALSE)
plot(a2, main = "after (1-B)(1-B^12): only 1 and 12 survive")
abline(v = c(1, 12), col = "firebrick", lty = 3)
dev.off()

# --- 10-14: the forecast fan -----------------------------------------------
png_("10-14-forecast-fan.png")
fitM1 <- arima(lap, order = c(0, 1, 1),
               seasonal = list(order = c(0, 1, 1), period = 12))
pM1 <- predict(fitM1, n.ahead = 24)
hi <- exp(pM1$pred + 1.96 * pM1$se); lo <- exp(pM1$pred - 1.96 * pM1$se)
ts.plot(exp(lap), lo, hi, exp(pM1$pred),
        col = c("black", "grey65", "grey65", "firebrick"),
        lty = c(1, 2, 2, 1), lwd = c(1.6, 1.2, 1.2, 2),
        ylab = "passengers", main = "airline model, 24 months ahead (95% interval)")
legend("topleft", c("observed", "forecast", "95% interval"),
       col = c("black", "firebrick", "grey65"), lty = c(1, 1, 2), lwd = 2,
       bty = "n", cex = 0.8)
dev.off()

# --- 10-12: the likelihood surface the optimiser climbs --------------------
png_("10-12-likelihood-surface.png")
par(mfrow = c(1, 2))
ll_at <- function(ma1, sma1) {
  f <- try(arima(lap, order = c(0, 1, 1),
                 seasonal = list(order = c(0, 1, 1), period = 12),
                 fixed = c(ma1, sma1), transform.pars = FALSE,
                 method = "ML"), silent = TRUE)
  if (inherits(f, "try-error")) NA_real_ else f$loglik
}
g1 <- seq(-0.85, 0.05, length.out = 30)     # R sign for theta
g2 <- seq(-0.95, -0.05, length.out = 30)    # R sign for Theta
Z  <- outer(g1, g2, Vectorize(ll_at))
mle <- arima(lap, order = c(0, 1, 1),
             seasonal = list(order = c(0, 1, 1), period = 12), method = "ML")
contour(g1, g2, Z, nlevels = 28, xlab = "theta (R sign)", ylab = "Theta (R sign)",
        main = "log-likelihood surface")
points(coef(mle)[1], coef(mle)[2], pch = 19, col = "firebrick", cex = 1.6)
text(coef(mle)[1], coef(mle)[2] + 0.06, "MLE", col = "firebrick", cex = 0.85)
prof <- vapply(g2, function(s) ll_at(coef(mle)[1], s), numeric(1))
plot(-g2, prof, type = "l", lwd = 2, col = "steelblue",
     xlab = "Theta (Census sign)", ylab = "log-likelihood",
     main = "profile through the MLE")
abline(v = -coef(mle)[2], col = "firebrick", lty = 2)
text(-coef(mle)[2], min(prof, na.rm = TRUE),
     sprintf(" Theta = %.3f", -coef(mle)[2]), col = "firebrick", cex = 0.8, adj = 0)
dev.off()

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

# ============================ MODULE 4 =====================================
source("R/_seats.R")
fit4 <- arima(log(AirPassengers), c(0,1,1), list(order = c(0,1,1), period = 12))
th4  <- unname(-coef(fit4)["ma1"]); Th4 <- unname(-coef(fit4)["sma1"])
build4 <- function(theta, Theta, s = 12) {
  mm <- poly_mult(c(1, -theta), c(1, rep(0, s - 1), -Theta))
  ss <- seats_ar_split(1, 1, s)
  seats_canonical(seats_partial_fractions(mm, ss$trend, ss$seasonal))
}
cn4 <- build4(th4, Th4)
pf4 <- seats_partial_fractions(poly_mult(c(1,-th4), c(1, rep(0,11), -Th4)),
                               seats_ar_split(1,1,12)$trend, seats_ar_split(1,1,12)$seasonal)

# --- 40-04: the spectrum split into three ---------------------------------
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

# --- 40-06: the three component filters -----------------------------------
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

# --- 40-07: the finished decomposition ------------------------------------
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

# ============================ MODULE 5 =====================================
# Revisions cluster at turning points. This recomputes ~75 X-13 runs, so it is
# the slow part of this script; step `by` up if you want it faster.
if (requireNamespace("seasonal", quietly = TRUE)) {
  suppressMessages(library(seasonal))
  z5 <- seasonal::unemp
  fin5 <- as.numeric(series(seas(z5, x11 = ""), "d11"))
  idx5 <- seq(96, length(z5) - 12, by = 3)
  conc5 <- sapply(idx5, function(i) {
    y <- ts(as.numeric(z5)[1:i], start = start(z5), frequency = 12)
    tryCatch(as.numeric(series(seas(y, x11 = ""), "d11"))[i], error = function(e) NA_real_)
  })
  tt5  <- as.numeric(time(z5))[idx5]
  rev5 <- 100 * (fin5[idx5] - conc5) / fin5[idx5]
  recs <- list(c(1990.5, 1991.25), c(2001.17, 2001.92), c(2007.92, 2009.5))
  near5 <- Reduce(`|`, lapply(recs, function(r) tt5 >= r[1] - 1 & tt5 <= r[2] + 1))
  ok5 <- !is.na(rev5)

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
}

cat("figures written to figures/:\n"); print(list.files("figures"))
