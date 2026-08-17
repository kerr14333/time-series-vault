# 10-05 -- Invertibility, pi-weights, and the unit MA root.
source("R/_setup.R")
set.seed(31)

# EXERCISE 1: pi-weights decay at rate theta --------------------------------
# For MA(1) in Census sign, 1/theta(B) = 1 + theta B + theta^2 B^2 + ...
op <- par(mfrow = c(1, 1))
matplot(0:12, cbind(0.5^(0:12), 0.95^(0:12)), type = "b", pch = 19, lty = 1,
        col = c("steelblue", "firebrick"), xlab = "lag j", ylab = "|pi_j|",
        main = "AR(inf) weights of an MA(1): theta = 0.5 vs 0.95")
legend("topright", c("theta = 0.50", "theta = 0.95"), col = c("steelblue", "firebrick"), lwd = 2)
# theta near 1 -> the model remembers almost everything.

# theta and 1/theta give the same ACF ---------------------------------------
cat("ACF for Census theta = 0.5 :", round(ARMAacf(ma = -0.5, lag.max = 3), 4), "\n")
cat("ACF for Census theta = 2.0 :", round(ARMAacf(ma = -2.0, lag.max = 3), 4), "\n")
# identical. Only |theta| < 1 is invertible, so that is the one we report.

# EXERCISE 2: over-differencing induces a unit MA root ----------------------
th <- replicate(200, {
  w <- rnorm(150)                       # ALREADY stationary (white noise)
  suppressWarnings(ma_r_to_census(coef(arima(w, order = c(0, 1, 1), include.mean = FALSE))))
})
hist(th, breaks = 30, col = "grey85",
     main = "fit ARIMA(0,1,1) to WHITE NOISE (i.e. over-difference)",
     xlab = "Census theta")
abline(v = 1, col = "red", lwd = 2)
cat(sprintf("\nmedian theta = %.3f; %.0f%% of fits land above 0.95\n",
            median(th), 100 * mean(th > 0.95)))
# The MA is trying to cancel the difference you should not have taken.
# THETA PINNED NEAR 1 = OVER-DIFFERENCED. Remember this signature.

# Variance check: differencing too far INCREASES variance -------------------
v <- sapply(0:3, function(d) var(if (d == 0) lap else diff(lap, differences = d)))
cat("\nvariance of log(AirPassengers) after d = 0,1,2,3 regular differences:\n")
print(round(v, 5))
# Also try the seasonal direction:
cat("after (1-B)(1-B^12):", round(var(diff(diff(lap, 12))), 5), "\n")
cat("after (1-B)^2(1-B^12):", round(var(diff(diff(diff(lap, 12)))), 5), "  <- worse\n")

# The boundary case: z_t = (1-B) a_t ----------------------------------------
# Its spectrum is ZERO at frequency 0. Preview of Module 3:
w <- rnorm(2000); z <- diff(w)
sp <- spec.pgram(z, spans = c(15, 15), plot = FALSE)
plot(sp$freq, sp$spec, type = "l", lwd = 2, xlab = "frequency (cycles/period)",
     ylab = "spectrum", main = "spectrum of (1-B)a_t : a ZERO at frequency 0")
abline(v = 0, col = "red", lty = 2)
# A non-invertible unit MA root <=> a spectral zero.
# SEATS creates these ON PURPOSE (canonical decomposition). See 40-00.
