# 30-04 -- The pseudo-spectrum: unit roots as infinite peaks.
source("R/_setup.R"); source("R/_spectral.R")

# Avoid evaluating exactly ON a pole so the plots stay drawable.
f <- seq(1e-4, 0.5 - 1e-4, length.out = 4000)

# EXERCISE 4: where are the peaks? ----------------------------------------
op <- par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))
plot(f, arma_spectrum(ar_poly = c(1, -1), freq = f), type = "l", lwd = 2, log = "y",
     xlab = "cycles/month", ylab = "pseudo-spectrum", main = "(1-B): one peak, at frequency 0")
plot(f, arma_spectrum(ar_poly = c(1, rep(0, 11), -1), freq = f), type = "l", lwd = 2,
     log = "y", xlab = "cycles/month", ylab = "pseudo-spectrum",
     main = "(1-B^12): SEVEN peaks")
mark_seasonal_freq()
par(op)
cat("(1-B)    -> pole at frequency 0 only.\n")
cat("(1-B^12) -> poles at 0 AND the six seasonal frequencies.\n")
cat("Because 1-B^12 = (1-B)(1+B+...+B^11): the first factor gives the trend\n")
cat("pole, the second gives the six seasonal ones. Same factorisation as 10-06.\n\n")

# EXERCISE 1: the airline model's pseudo-spectrum -------------------------
theta <- 0.4; Theta <- 0.6
ps <- arma_spectrum(ma_poly = airline_ma(theta, Theta), ar_poly = airline_ar(), freq = f)
plot(f, ps, type = "l", lwd = 2, log = "y", xlab = "cycles/month",
     ylab = "pseudo-spectrum (log)",
     main = sprintf("airline model, theta=%.1f Theta=%.1f", theta, Theta))
mark_seasonal_freq(); abline(v = 0, col = "firebrick", lty = 3)
cat("Seven infinite peaks: a DOUBLE one at 0 (trend, from (1-B)^2) and six\n")
cat("seasonal ones. Between them, a finite floor -- the irregular.\n\n")

# EXERCISE 2: Theta controls the WIDTH of the seasonal peaks -------------
peak_width <- function(Theta, k = 1, drop = 10) {
  # width of the band around seasonal frequency k where the pseudo-spectrum
  # is within a factor `drop` of its value close to the pole
  ps <- arma_spectrum(ma_poly = airline_ma(0.4, Theta), ar_poly = airline_ar(), freq = f)
  near <- which.min(abs(f - SEAS_F[k]))
  ref <- ps[near]
  idx <- which(ps > ref / drop)
  idx <- idx[abs(f[idx] - SEAS_F[k]) < 0.03]
  diff(range(f[idx]))
}
cat("width of the annual peak as Theta varies:\n")
for (Th in c(0.2, 0.4, 0.6, 0.8, 0.95))
  cat(sprintf("  Theta = %.2f  ->  width %.5f cycles/month\n", Th, peak_width(Th)))
cat("\nHigher Theta = NARROWER peak = more sharply defined, more stable seasonal\n")
cat("= smaller revisions. This is 10-10's 'how much the seasonal evolves',\n")
cat("seen as peak width.\n\n")

plot(NA, xlim = c(0.05, 0.12), ylim = c(1e-3, 1e3), log = "y",
     xlab = "cycles/month", ylab = "pseudo-spectrum",
     main = "the annual peak, as Theta varies")
cols <- c("steelblue", "darkgreen", "firebrick")
for (i in seq_along(c(0.2, 0.6, 0.95))) {
  Th <- c(0.2, 0.6, 0.95)[i]
  lines(f, arma_spectrum(ma_poly = airline_ma(0.4, Th), ar_poly = airline_ar(), freq = f),
        col = cols[i], lwd = 2)
}
abline(v = 1/12, lty = 2)
legend("topright", paste("Theta =", c(0.2, 0.6, 0.95)), col = cols, lwd = 2, bty = "n")

# EXERCISE 3: theta shapes the trend peak --------------------------------
plot(NA, xlim = c(1e-4, 0.08), ylim = c(1e-2, 1e6), log = "y",
     xlab = "cycles/month", ylab = "pseudo-spectrum", main = "the trend peak, as theta varies")
for (i in seq_along(c(0.2, 0.6, 0.95))) {
  th <- c(0.2, 0.6, 0.95)[i]
  lines(f, arma_spectrum(ma_poly = airline_ma(th, 0.6), ar_poly = airline_ar(), freq = f),
        col = cols[i], lwd = 2)
}
legend("topright", paste("theta =", c(0.2, 0.6, 0.95)), col = cols, lwd = 2, bty = "n")

# EXERCISE 5: does the data agree about WHERE the peaks are? -------------
sp <- spec.pgram(lap, spans = c(3,3), taper = 0.1, plot = FALSE, detrend = FALSE)
plot(sp$freq, log(sp$spec), type = "l", lwd = 2, xlab = "cycles/month",
     ylab = "log power", main = "log(AirPassengers), undifferenced: real data")
mark_seasonal_freq()
cat("\nA periodogram cannot show infinities -- finite data, finite estimate --\n")
cat("but the peaks line up with the model's poles. The pseudo-spectrum is the\n")
cat("idealisation the model asserts; the periodogram is what 144 observations\n")
cat("can show of it.\n")
