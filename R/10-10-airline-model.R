# 10-10 -- The airline model on real data.
source("R/_setup.R")
set.seed(71)

# EXERCISE 1: fit it --------------------------------------------------------
fit <- arima(lap, order = c(0, 1, 1), seasonal = list(order = c(0, 1, 1), period = 12))
print(fit)
th_r <- coef(fit)
theta <- ma_r_to_census(th_r["ma1"]); Theta <- ma_r_to_census(th_r["sma1"])
cat(sprintf("\nCENSUS convention:  theta = %.4f   Theta = %.4f\n", theta, Theta))
cat("Both positive, as expected for a well-behaved economic series.\n\n")
cat("Reading them:\n")
cat(sprintf("  theta = %.2f -> trend is %s\n", theta,
            if (theta > 0.6) "fairly smooth" else "close to a random walk"))
cat(sprintf("  Theta = %.2f -> seasonality is %s, so seasonal factors will revise %s\n",
            Theta, if (Theta > 0.6) "quite stable" else "volatile",
            if (Theta > 0.6) "modestly" else "a lot"))

# EXERCISE 2: two very different parameter settings -------------------------
sim_airline <- function(theta, Theta, n = 240, sd = 0.03) {
  ma <- poly_mult(c(1, -theta), c(1, rep(0, 11), -Theta))
  a  <- rnorm(n + 600, sd = sd)
  w  <- as.numeric(na.omit(stats::filter(a, ma_census_to_r(ma[-1]), "convolution", sides = 1)))
  z  <- cumsum(w)                                     # (1-B)^-1
  out <- numeric(length(z))                           # (1-B^12)^-1
  for (t in seq_along(z)) out[t] <- z[t] + if (t > 12) out[t - 12] else 0
  ts(tail(out, n), frequency = 12)
}
op <- par(mfrow = c(2, 1), mar = c(3, 4, 2, 1))
plot(sim_airline(0.4, 0.6), ylab = "", main = "theta=0.4, Theta=0.6  (typical economic series)")
plot(sim_airline(0.9, 0.95), ylab = "", main = "theta=0.9, Theta=0.95 (near-deterministic)")
par(op)

# EXERCISE 3: Theta = 1 exactly kills the seasonal unit roots ---------------
# (1 - B^12) on the AR side vs (1 - 1*B^12) on the MA side: they cancel.
cat("\nAR-side seasonal operator: ", poly_show(c(1, rep(0, 11), -1)), "\n")
cat("MA-side with Theta = 1:     ", poly_show(c(1, rep(0, 11), -1)), "\n")
cat("They cancel -> the stochastic seasonal collapses to a FIXED pattern.\n")
op <- par(mfrow = c(2, 1), mar = c(3, 4, 2, 1))
plot(sim_airline(0.4, 0.999), ylab = "", main = "Theta -> 1: seasonal pattern stops evolving")
plot(sim_airline(0.4, 0.2),   ylab = "", main = "Theta = 0.2: seasonal pattern re-rolls constantly")
par(op)
cat("\nThat is the whole meaning of Theta: how much the seasonality is allowed to move.\n")

# Residual check ------------------------------------------------------------
tsdiag(fit)
cat("\nLjung-Box at lag 24, df corrected:\n")
print(Box.test(residuals(fit), lag = 24, type = "Ljung-Box", fitdf = 2))

# ---- nottem: where the DEFAULTS are wrong -------------------------------
source("R/_series.R")
suppressMessages(if (requireNamespace("seasonal", quietly = TRUE)) library(seasonal))
cat("\n=== nottem: logs are not automatic, seasonality is not always stochastic ===\n")
if (requireNamespace("seasonal", quietly = TRUE)) {
  m <- seas(nottem)
  cat("X-13's automatic choice :", paste(m$model$arima$model, collapse = ""), "\n")
  cat("transform chosen        :", transformfunction(m), "\n")
  cat("  -> NO log, and no regular difference. Two habits broken at once.\n")
}
f <- airline_fit(nottem)
cat(sprintf("\nforced airline: theta = %.3f  Theta = %.3f\n", f$theta, f$Theta))
cat("Theta near 1 = the seasonal pattern does not evolve. For temperature that\n")
cat("is literally true: the Earth's orbit does not drift. This is the ONE case\n")
cat("where deterministic seasonal dummies would be the right model.\n\n")

cat("=== the full range of Theta across real series ===\n")
S <- vault_series()
th <- sapply(names(S), function(n) tryCatch(airline_fit(S[[n]])$Theta, error = function(e) NA))
print(round(sort(th), 3))
cat("\nUKgas 0.235 (re-rolls yearly) ... nottem 0.922 (fixed by physics).\n")
cat("AirPassengers sits unremarkably in the middle, which is why one series\n")
cat("teaches you nothing about either extreme.\n")
