# 30-06 -- Wiener-Kolmogorov: keep the share of the power that is yours.
source("R/_setup.R"); source("R/_spectral.R")
set.seed(303)

# The canonical toy problem: signal = random walk, noise = white ----------
#   s_t : (1-B) s_t = a_st,  var sigma_s^2
#   n_t : white noise,       var sigma_n^2
#   z_t = s_t + n_t
f <- seq(1e-4, 0.5, length.out = 2000)

wk_demo <- function(sig_s = 1, sig_n = 2) {
  f_s <- arma_spectrum(ar_poly = c(1, -1), sigma2 = sig_s^2, freq = f)   # pole at 0
  f_n <- rep(sig_n^2 / (2 * pi), length(f))                              # flat
  f_z <- f_s + f_n
  list(f_s = f_s, f_n = f_n, f_z = f_z, nu = wk_gain(f_s, f_z))
}
d <- wk_demo()

op <- par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))
plot(f, d$f_s, type = "l", lwd = 2, log = "y", ylim = c(1e-2, 1e4),
     xlab = "cycles/period", ylab = "spectrum", main = "components add: f_z = f_s + f_n")
lines(f, d$f_n, col = "firebrick", lwd = 2)
lines(f, d$f_z, col = "steelblue", lwd = 2, lty = 2)
legend("topright", c("signal (random walk)", "noise (white)", "observed"),
       col = c("black", "firebrick", "steelblue"), lwd = 2, lty = c(1,1,2), bty = "n", cex = 0.75)

# EXERCISE 1 & 4: the gain, and that the gains sum to 1 -------------------
plot(f, d$nu, type = "l", lwd = 2, ylim = c(0, 1), xlab = "cycles/period",
     ylab = "gain", main = "WK gain = f_s / f_z")
lines(f, wk_gain(d$f_n, d$f_z), col = "firebrick", lwd = 2)
lines(f, d$nu + wk_gain(d$f_n, d$f_z), col = "grey50", lwd = 2, lty = 3)
legend("right", c("signal filter", "noise filter", "sum"),
       col = c("black", "firebrick", "grey50"), lwd = 2, lty = c(1,1,3), bty = "n", cex = 0.75)
par(op)
cat("gain at the lowest frequency :", round(d$nu[1], 4), " (signal owns the power)\n")
cat("gain at the Nyquist frequency:", round(tail(d$nu, 1), 4), " (noise owns it)\n")
cat("max |nu_s + nu_n - 1|        :",
    signif(max(abs(d$nu + wk_gain(d$f_n, d$f_z) - 1)), 3), "\n")
cat("The component estimates add back to the observed series EXACTLY.\n\n")

# EXERCISE 2: the noise-to-signal ratio moves the cutoff ------------------
plot(NA, xlim = c(0, 0.5), ylim = c(0, 1), xlab = "cycles/period", ylab = "gain",
     main = "more noise => keep less => smoother signal estimate")
cols <- c("steelblue", "darkgreen", "firebrick", "purple")
for (i in seq_along(c(0.5, 1, 2, 4))) {
  lines(f, wk_demo(1, c(0.5, 1, 2, 4)[i])$nu, col = cols[i], lwd = 2)
}
legend("topright", paste("noise sd =", c(0.5, 1, 2, 4)), col = cols, lwd = 2, bty = "n", cex = 0.8)
cat("Compare R/10-04-ma-processes.R: there, more noise pushed the fitted MA\n")
cat("coefficient toward 1. Same fact -- a smoother implied signal -- in the\n")
cat("time domain.\n\n")

# EXERCISE 3: the filter WEIGHTS, by numerical inversion ------------------
wts <- wk_weights(wk_demo(1, 2)$nu, f, max_lag = 40)
cat("WK filter weights (lags 0..10):\n"); print(round(wts[1:11], 5))
cat("sum over all lags (2-sided):", round(wts[1] + 2*sum(wts[-1]), 4), " (want 1)\n")
plot(0:40, wts, type = "h", lwd = 3, col = "steelblue", xlab = "lag |j|",
     ylab = "weight", main = "WK filter weights: symmetric, geometrically decaying")
abline(h = 0, col = "grey70")
cat("Weights decay geometrically. The filter is two-sided and infinite --\n")
cat("which is 30-07's problem.\n\n")

# EXERCISE 5: the identification problem, made concrete ------------------
cat("THE CATCH: infinitely many component pairs give the SAME observed spectrum.\n")
c0 <- 0.4 / (2 * pi)                       # move this much white noise s -> n
alt_s <- d$f_s - c0
alt_n <- d$f_n + c0
cat("  original: min f_s =", signif(min(d$f_s), 4), " min f_n =", signif(min(d$f_n), 4), "\n")
cat("  shifted : min f_s =", signif(min(alt_s), 4), " min f_n =", signif(min(alt_n), 4), "\n")
cat("  max |f_z difference| :", signif(max(abs((alt_s + alt_n) - d$f_z)), 3), "\n")
cat("  but max |gain difference|:", signif(max(abs(wk_gain(alt_s, d$f_z) - d$nu)), 3), "\n")
cat("\nIdentical observed spectrum, DIFFERENT decomposition and different filter.\n")
cat("The data cannot choose. You need a convention -- and the canonical one\n")
cat("pushes as much variance as possible into the irregular, i.e. shifts until\n")
cat("min f_s touches zero. That is 40-03.\n")
