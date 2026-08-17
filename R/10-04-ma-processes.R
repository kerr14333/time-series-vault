# 10-04 -- MA processes: finite memory, and the non-uniqueness of theta.
source("R/_setup.R")
set.seed(21)

# NOTE ON SIGNS: R's arima.sim/ARMAacf use  z_t = a_t + th*a_{t-1}.
# Census convention is  z_t = a_t - theta*a_{t-1}.  So theta = -th.

# EXERCISE 1: rho1 as a function of theta -----------------------------------
theta <- seq(-3, 3, by = 0.01)
rho1  <- -theta / (1 + theta^2)
plot(theta, rho1, type = "l", lwd = 2,
     main = "MA(1): rho1 = -theta/(1+theta^2)   [Census sign]",
     xlab = expression(theta), ylab = expression(rho[1]))
abline(h = c(-0.5, 0, 0.5), v = c(0.5, 2), lty = 2, col = "grey60")
points(c(0.5, 2), -c(0.5, 2) / (1 + c(0.5, 2)^2), pch = 19, col = "red")
# The two red points sit at the SAME height: theta = 0.5 and theta = 2 have
# identical ACFs. Only theta = 0.5 is invertible. See note 10-05.
cat("rho1 at theta=0.5:", round(-0.5 / 1.25, 4),
    "   at theta=2:", round(-2 / 5, 4), "\n")
cat("|rho1| can never exceed 0.5 for an MA(1).\n")

# EXERCISE 2: ACF truncates at q, PACF does not -----------------------------
x <- arima.sim(list(ma = c(0.6, -0.3)), 500)     # R signs
op <- par(mfrow = c(2, 1), mar = c(3, 4, 2, 1))
acf(x, lag.max = 20, main = "MA(2): ACF cuts off after lag 2")
pacf(x, lag.max = 20, main = "MA(2): PACF decays, no cutoff")
par(op)

# EXERCISE 3: random walk + noise, differenced, IS an MA(1) ------------------
# This is the bridge to SEATS: a signal-plus-noise structure has an ARIMA
# reduced form, and differencing exposes it as MA.
n <- 1000
signal <- cumsum(rnorm(n, sd = 1))
obs    <- signal + rnorm(n, sd = 2)
d1     <- diff(obs)
acf(d1, lag.max = 12, main = "diff(random walk + noise): MA(1), rho1 < 0")
cat("\nsample rho1 of the differenced series:", round(acf(d1, plot = FALSE)$acf[2], 3), "\n")
fit <- arima(d1, order = c(0, 0, 1), include.mean = FALSE)
cat("fitted MA(1), R sign:", round(coef(fit), 3),
    " -> Census theta:", round(ma_r_to_census(coef(fit)), 3), "\n")
# rho1 MUST be negative: differencing an over-smooth series induces negative
# first-order autocorrelation. Positive theta (Census) <=> negative rho1.

# Change the noise-to-signal ratio and watch theta move ---------------------
cat("\nnoise sd -> fitted Census theta:\n")
for (sd_noise in c(0.25, 0.5, 1, 2, 4)) {
  y <- diff(signal + rnorm(n, sd = sd_noise))
  th <- ma_r_to_census(coef(arima(y, order = c(0, 0, 1), include.mean = FALSE)))
  cat(sprintf("  %5.2f  ->  %6.3f\n", sd_noise, th))
}
# More noise -> theta closer to 1 -> smoother implied signal. That mapping
# from an MA coefficient to a signal-to-noise ratio IS the seed of SEATS.
