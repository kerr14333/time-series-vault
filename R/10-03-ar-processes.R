# 10-03 -- AR processes: infinite echo.
source("R/_setup.R")
set.seed(11)

# EXERCISE 1: phi = 0.9 vs phi = -0.9 ---------------------------------------
x1 <- arima.sim(list(ar =  0.9), 300)
x2 <- arima.sim(list(ar = -0.9), 300)
op <- par(mfrow = c(2, 2), mar = c(3, 4, 2, 1))
plot(x1, ylab = "", main = "AR(1) phi = 0.9  (smooth, wandering)")
acf(x1, main = "")
plot(x2, ylab = "", main = "AR(1) phi = -0.9 (alternating)")
acf(x2, main = "")
par(op)
# rho_k = phi^k: geometric decay, alternating sign when phi < 0.

# psi-weights: how long a shock echoes --------------------------------------
for (phi in c(0.5, 0.8, 0.95)) {
  psi <- ARMAtoMA(ar = phi, ma = 0, 12)
  cat(sprintf("phi=%.2f  shock still worth %5.1f%% after 5 periods, %5.1f%% after 10\n",
              phi, 100 * psi[5], 100 * psi[10]))
}

# EXERCISE 2: AR(2) with complex roots = a pseudo-cycle ----------------------
phi1 <- 1.6; phi2 <- -0.9
print(poly_roots(c(1, -phi1, -phi2)))
period <- 2 * pi / acos(phi1 / (2 * sqrt(-phi2)))
cat(sprintf("\nimplied pseudo-cycle period: %.2f periods\n", period))

x3 <- arima.sim(list(ar = c(phi1, phi2)), 300)
op <- par(mfrow = c(2, 1), mar = c(3, 4, 2, 1))
plot(x3, ylab = "", main = sprintf("AR(2) pseudo-cycle, period ~ %.1f", period))
acf(x3, lag.max = 40, main = "ACF: damped sine, decays but never truncates")
par(op)

# THE POINT FOR SEASONAL ADJUSTMENT -----------------------------------------
# An AR(2) tuned to period 12 gives a seasonal-looking wiggle whose amplitude
# and phase WANDER -- unlike a deterministic sine. Compare:
x_stoch <- arima.sim(list(ar = c(2 * 0.97 * cos(2 * pi / 12), -0.97^2)), 240)
x_det   <- 3 * sin(2 * pi * (1:240) / 12) + rnorm(240, sd = 0.5)
op <- par(mfrow = c(2, 1), mar = c(3, 4, 2, 1))
plot(x_stoch, ylab = "", main = "stochastic 'seasonal' (AR(2), root near unit circle)")
plot(ts(x_det), ylab = "", main = "deterministic seasonal + noise")
par(op)
# Real seasonality looks like the first one. That is why seasonal dummies
# are usually the wrong model, and why (1-B^12) beats a fixed pattern.

# EXERCISE 3: Yule-Walker for AR(2) -----------------------------------------
# rho1 = phi1/(1-phi2);  rho2 = phi1*rho1 + phi2
rho1 <- phi1 / (1 - phi2); rho2 <- phi1 * rho1 + phi2
cat(sprintf("\ntheoretical rho1=%.3f rho2=%.3f\n", rho1, rho2))
print(round(ARMAacf(ar = c(phi1, phi2), lag.max = 4), 3))
