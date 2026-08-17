# 10-13 -- AICC, Ljung-Box done right, residual spectrum.
source("R/_setup.R")

aicc <- function(fit) {
  k <- length(coef(fit)) + 1L                 # + sigma^2
  n <- fit$nobs
  AIC(fit) + 2 * k * (k + 1) / (n - k - 1)
}

# EXERCISE 1: compare candidates on the SAME differencing -------------------
cands <- list(
  "(0,1,1)(0,1,1)" = arima(lap, c(0,1,1), list(order = c(0,1,1), period = 12)),
  "(0,1,2)(0,1,1)" = arima(lap, c(0,1,2), list(order = c(0,1,1), period = 12)),
  "(1,1,1)(0,1,1)" = arima(lap, c(1,1,1), list(order = c(0,1,1), period = 12)),
  "(0,1,1)(0,1,2)" = arima(lap, c(0,1,1), list(order = c(0,1,2), period = 12))
)
tab <- data.frame(
  aic  = round(sapply(cands, AIC), 2),
  aicc = round(sapply(cands, aicc), 2),
  bic  = round(sapply(cands, BIC), 2),
  npar = sapply(cands, function(f) length(coef(f)))
)
print(tab[order(tab$aicc), ])
cat("\nDifferences under ~2 AICC are not real. Prefer the simpler model.\n")
cat("NOTE: all four have the same d and D, so the comparison is legitimate.\n")

# EXERCISE 2: Box.test with and without fitdf ------------------------------
fit <- cands[["(0,1,1)(0,1,1)"]]
r <- residuals(fit)
cat("\nLjung-Box, lag 24:\n")
cat("  without fitdf (WRONG): p =", round(Box.test(r, 24, "Ljung-Box")$p.value, 4), "\n")
cat("  with fitdf = 2 (right): p =", round(Box.test(r, 24, "Ljung-Box", fitdf = 2)$p.value, 4), "\n")

cat("\nseasonal lags specifically:\n")
for (h in c(12, 24, 36))
  cat(sprintf("  lag %2d: p = %.4f\n", h, Box.test(r, h, "Ljung-Box", fitdf = 2)$p.value))

# EXERCISE 3: residual spectrum of an under-specified model ----------------
bad <- arima(lap, c(0,1,1), list(order = c(0,1,0), period = 12))   # no seasonal MA
op <- par(mfrow = c(2, 1), mar = c(4, 4, 3, 1))
sfreq <- (1:6) / 12
sp1 <- spec.pgram(residuals(bad), spans = c(3,3), plot = FALSE, taper = 0)
plot(sp1$freq, log(sp1$spec), type = "l", lwd = 2, xlab = "cycles per month",
     ylab = "log spectrum", main = "residuals WITHOUT seasonal MA -- peaks at seasonal freqs")
abline(v = sfreq, col = "red", lty = 2)
sp2 <- spec.pgram(residuals(fit), spans = c(3,3), plot = FALSE, taper = 0)
plot(sp2$freq, log(sp2$spec), type = "l", lwd = 2, xlab = "cycles per month",
     ylab = "log spectrum", main = "airline model residuals -- flat at seasonal freqs")
abline(v = sfreq, col = "red", lty = 2)
par(op)
cat("\nA seasonal peak in the RESIDUALS is the most damning diagnostic there is.\n")
cat("X-13 prints this automatically and flags it.\n")
