# 40-06 -- The three WK filters: gains, weights, and X-11 side by side.
source("R/_setup.R"); source("R/_spectral.R"); source("R/_seats.R"); source("R/_x11.R")

x   <- AirPassengers
fit <- arima(log(x), c(0,1,1), list(order = c(0,1,1), period = 12))
th  <- unname(-coef(fit)["ma1"]); Th <- unname(-coef(fit)["sma1"])

build <- function(theta, Theta, s = 12) {
  ma <- poly_mult(c(1, -theta), c(1, rep(0, s - 1), -Theta))
  sp <- seats_ar_split(1, 1, s)
  seats_canonical(seats_partial_fractions(ma, sp$trend, sp$seasonal))
}
cn <- build(th, Th)
w  <- seq(1e-8, pi - 1e-8, length.out = 4000)
nu <- seats_filters(cn, w)

# EXERCISES 1-2: the gains, and the ownership table ----------------------
plot(w, nu$trend, type = "l", lwd = 2, col = "firebrick", ylim = c(0, 1.05),
     xlab = "omega (radians)", ylab = "gain", main = "SEATS component filters")
lines(w, nu$seasonal, col = "steelblue", lwd = 2)
lines(w, nu$irregular, col = "darkgreen", lwd = 2)
abline(v = 2*pi*(1:6)/12, lty = 3, col = "grey60"); abline(h = c(0,1), col = "grey88")
legend("right", c("trend", "seasonal", "irregular"),
       col = c("firebrick","steelblue","darkgreen"), lwd = 2, bty = "n")

at <- function(target) which.min(abs(w - target))
cat("=== who owns which frequency? ===\n")
cat(sprintf("%-22s %9s %9s %9s\n", "frequency", "trend", "seasonal", "irregular"))
for (nm in c("0 (trend)", "2pi/12 (annual)", "2pi/6", "pi (Nyquist)")) {
  i <- at(switch(nm, "0 (trend)" = 0, "2pi/12 (annual)" = 2*pi/12,
                 "2pi/6" = 2*pi/6, "pi (Nyquist)" = pi))
  cat(sprintf("%-22s %9.5f %9.5f %9.5f\n", nm,
              nu$trend[i], nu$seasonal[i], nu$irregular[i]))
}
cat("\nmax |sum - 1| :", signif(max(abs(nu$trend + nu$seasonal + nu$irregular - 1)), 3), "\n")
cat("\nNote nu_S(pi) = 1. omega = pi IS a seasonal frequency (k = 6, the two-month\n")
cat("cycle), so the seasonal legitimately owns all the power there. Not a bug.\n\n")

# EXERCISE 3: Theta narrows the notches ---------------------------------
plot(NA, xlim = c(0, pi), ylim = c(0, 1.05), xlab = "omega", ylab = "gain",
     main = "seasonal filter: Theta controls the notch WIDTH")
cols <- c("steelblue", "darkgreen", "firebrick")
for (i in seq_along(c(0.3, 0.6, 0.9))) {
  lines(w, seats_filters(build(0.4, c(0.3, 0.6, 0.9)[i]), w)$seasonal, col = cols[i], lwd = 2)
}
abline(v = 2*pi*(1:6)/12, lty = 3, col = "grey70")
legend("right", paste("Theta =", c(0.3, 0.6, 0.9)), col = cols, lwd = 2, bty = "n")
cat("Higher Theta = stabler seasonality = NARROWER notches = less collateral\n")
cat("damage to nearby non-seasonal power. X-11 cannot do this: its notch shape\n")
cat("is fixed by the chosen filter lengths, not by the series.\n\n")

# X-11's composite SA filter, for comparison ----------------------------
imp <- ts(rep(1, 241), frequency = 12); imp[121] <- 2
wx  <- as.numeric(x11_decompose(imp, extreme = FALSE)$d11) - 1
ww  <- wx[(121-72):(121+72)]
fcy <- w / (2*pi)                       # cycles per month, for gain()
plot(w, 1 - nu$seasonal, type = "l", lwd = 2, col = "firebrick", ylim = c(0, 1.15),
     xlab = "omega", ylab = "gain", main = "seasonal ADJUSTMENT filter: SEATS vs X-11")
lines(w, gain(ww, fcy), col = "steelblue", lwd = 2)
abline(v = 2*pi*(1:6)/12, lty = 3, col = "grey60")
legend("bottomright", c("SEATS (1 - nu_S)", "X-11 composite"),
       col = c("firebrick","steelblue"), lwd = 2, bty = "n", cex = 0.85)
cat("=== gain of the SA filter at the seasonal frequencies ===\n")
cat("SEATS:", round(1 - nu$seasonal[sapply(2*pi*(1:6)/12, at)], 5), "\n")
cat("X-11 :", round(gain(ww, (1:6)/12), 5), "\n")
cat("Both notch hard. The difference is that SEATS's width ADAPTS to Theta.\n\n")

# EXERCISES 4-5: the weights and how far they reach ---------------------
wt <- lapply(nu, filter_weights, w = w, max_lag = 60)
op <- par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))
plot(0:60, wt$trend, type = "h", lwd = 2, col = "firebrick", xlab = "lag",
     ylab = "weight", main = "trend filter weights"); abline(h = 0, col = "grey70")
plot(0:60, wt$seasonal, type = "h", lwd = 2, col = "steelblue", xlab = "lag",
     ylab = "weight", main = "seasonal filter weights (spikes every 12)")
abline(h = 0, col = "grey70"); abline(v = seq(0, 60, 12), lty = 3, col = "grey80")
par(op)

cat("=== seasonal weight envelope: does it decay at Theta per YEAR? ===\n")
sp12 <- wt$seasonal[seq(13, 61, by = 12)]
cat("weights at lags 12, 24, 36, 48, 60:", signif(sp12, 4), "\n")
cat("successive ratios:", round(sp12[-1] / head(sp12, -1), 4), "  (Theta =", round(Th, 3), ")\n\n")

cat("=== lags needed before the weights are negligible ===\n")
for (Tt in c(0.3, 0.6, 0.9))
  cat(sprintf("  Theta = %.1f -> %3d lags (%.1f years)\n", Tt,
              seats_max_lag(0.4, Tt), seats_max_lag(0.4, Tt)/12))
cat("Narrow notches require long filters. That is the uncertainty principle,\n")
cat("and it is why a 144-point series needs a 331-lag filter (30-06).\n")
