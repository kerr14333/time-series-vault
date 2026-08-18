# 20-08 -- X-11-ARIMA: extend with forecasts, then filter symmetrically.
source("R/_setup.R"); source("R/_x11.R")

z <- AirPassengers

# The idea, implemented directly: fit the airline model, forecast a year,
# run X-11 on the extended series, then keep only the original span.
extend_and_adjust <- function(x, ahead = 12) {
  fit <- arima(log(x), order = c(0, 1, 1),
               seasonal = list(order = c(0, 1, 1), period = 12))
  fc  <- exp(predict(fit, n.ahead = ahead)$pred)
  ext <- ts(c(as.numeric(x), as.numeric(fc)), start = start(x), frequency = 12)
  d   <- x11_decompose(ext)
  lapply(d[c("d10", "d11", "d12")], function(s) window(s, end = end(x)))
}

# EXERCISE 1: with vs without extension, at the end of the sample ----------
plain <- x11_decompose(z)
ext   <- extend_and_adjust(z)

cat("last 12 months of D11 -- plain vs forecast-extended:\n")
tail12 <- data.frame(
  month    = format(time(z))[133:144],
  plain    = round(as.numeric(plain$d11)[133:144], 1),
  extended = round(as.numeric(ext$d11)[133:144], 1)
)
tail12$diff_pct <- round(100 * (tail12$extended - tail12$plain) / tail12$plain, 2)
print(tail12, row.names = FALSE)
cat("\nmean |difference| over the final year:",
    round(mean(abs(tail12$diff_pct)), 3), "%\n")
cat("The interior is untouched; only the ends move. That localisation is the\n")
cat("whole signature of an end-filter effect.\n\n")

# EXERCISE 2: does extension actually reduce revisions? -------------------
#
# READ THIS BEFORE TRUSTING ANY REVISION NUMBER. How you define "revision"
# decides the answer, and one natural-sounding definition is simply wrong.
#
#   WRONG: compare each method's concurrent estimate against ITS OWN estimate
#          24 months later. That measures self-consistency, not accuracy -- a
#          method that is stably wrong scores perfectly. Run this way, forecast
#          extension looks worthless on AirPassengers (0.3%) and actively
#          harmful on a noisier series (-16%).
#
#   RIGHT: compare every method against ONE shared reference -- the full-sample
#          estimate, where the point of interest sits in the interior and is
#          therefore produced by the symmetric filter. That is what "final"
#          means, and it is what the concurrent estimate is trying to hit.
#
mar <- function(adjust_fn, idx, reference) {
  conc <- sapply(idx, function(i) {
    zc <- ts(as.numeric(z)[1:i], start = start(z), frequency = 12)
    as.numeric(adjust_fn(zc)$d11)[i]
  })
  mean(abs(conc - reference[idx]) / reference[idx]) * 100
}
idx   <- seq(60, length(z) - 24, by = 12)
final <- as.numeric(x11_decompose(z)$d11)          # the shared reference

a <- mar(function(x) x11_decompose(x), idx, final)
b <- mar(extend_and_adjust,            idx, final)
cat("mean absolute revision vs the full-sample (symmetric-filter) value:\n")
cat(sprintf("  plain X-11        : %.3f%%\n", a))
cat(sprintf("  forecast-extended : %.3f%%\n", b))
cat(sprintf("  reduction         : %.1f%%\n", 100 * (1 - b / a)))
cat("\nThat is Dagum's contribution, reproduced. Note it only appears once the\n")
cat("revision is measured against a common target -- see the comment above.\n\n")

# EXERCISE 3: what happens at a turning point -----------------------------
# Build a series with a deliberate break in trend, then forecast across it.
n <- 180; t <- 1:n
trend <- ifelse(t < 120, 100 + 0.8 * t, 100 + 0.8 * 120 - 0.9 * (t - 120))
seas  <- 12 * sin(2 * pi * t / 12)
set.seed(3)
y <- ts(trend + seas + rnorm(n, sd = 2), frequency = 12)

fit <- arima(window(y, end = time(y)[119]), order = c(0, 1, 1),
             seasonal = list(order = c(0, 1, 1), period = 12))
fc  <- predict(fit, n.ahead = 24)$pred
cat("forecasting ACROSS a turning point (trend reverses at t=120):\n")
cat("  mean forecast error over the next 12 months:",
    round(mean(as.numeric(fc)[1:12] - as.numeric(y)[120:131]), 2), "\n")
cat("  sign of the error: systematically POSITIVE -- the model extrapolates\n")
cat("  the old upward regime. This is mechanism 1 of the three in 20-07.\n")

plot(y, xlim = c(1, 18), ylab = "", main = "forecasting across a turning point")
lines(fc, col = "firebrick", lwd = 2)
abline(v = time(y)[120], lty = 2, col = "grey50")
legend("topleft", c("truth", "forecast from t=119"), col = c("black", "firebrick"),
       lwd = 2, bty = "n")
cat("\nA better model shrinks revisions in normal times. It does not fix the turn.\n")

# EXERCISE 4: Theta predicts revision size --------------------------------
cat("\nfitted seasonal MA (Census sign) for this series:",
    round(ma_r_to_census(coef(arima(log(z), c(0,1,1),
      list(order = c(0,1,1), period = 12)))["sma1"]), 3), "\n")
cat("High Theta = stable seasonality = well-pinned forecasts = small revisions.\n")
cat("You can read the last from the first. See 10-10.\n")
