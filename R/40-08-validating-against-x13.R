# 40-08 -- Prove it against the Census Bureau binary.
source("R/_setup.R"); source("R/_spectral.R"); source("R/_seats.R"); source("R/_series.R")
if (!requireNamespace("seasonal", quietly = TRUE)) stop("needs the 'seasonal' package")
suppressMessages(library(seasonal))

x   <- AirPassengers
fit <- arima(log(x), c(0,1,1), list(order = c(0,1,1), period = 12))
th  <- unname(-coef(fit)["ma1"]); Th <- unname(-coef(fit)["sma1"])
ours <- seats_decompose(x, th, Th)

# Pin EVERY option, or you are comparing two different computations.
m <- seas(x,
          transform.function = "log",           # multiplicative; "none" runs additive
          arima.model        = "(0 1 1)(0 1 1)", # no automatic model selection
          regression.aictest = NULL,             # no trading-day / Easter testing
          outlier            = NULL)             # no outlier detection

tab <- list(s10 = series(m, "s10"), s11 = series(m, "s11"),
            s12 = series(m, "s12"), s13 = series(m, "s13"))
mine <- list(s10 = exp(ours$seasonal), s11 = exp(ours$sa),
             s12 = exp(ours$trend),    s13 = exp(ours$irregular))

cmp <- function(a, b, lab) {
  a <- as.numeric(a); b <- as.numeric(b); n <- length(a); int <- 25:(n - 24)
  pd <- 100 * abs(a - b) / abs(b)
  cat(sprintf("  %-4s interior mean %.6f%%  max %.6f%%  |  ends max %.6f%%\n",
              lab, mean(pd[int]), max(pd[int]), max(pd[-int])))
}
cat("=== ours vs the real X-13 SEATS ===\n")
for (k in names(tab)) cmp(mine[[k]], tab[[k]], k)

cat("\nNote the error is NOT concentrated at the ends -- unlike the X-11 build in\n")
cat("20-05. Both implementations forecast-extend, so both effectively apply the\n")
cat("symmetric filter throughout. The end-of-sample REVISION problem is about\n")
cat("not yet having data, not about the filter failing once you supply forecasts.\n\n")

# The identity that reveals what was actually decomposed ------------------
id <- max(abs(log(as.numeric(x)) - log(as.numeric(tab$s11)) - log(as.numeric(tab$s10))))
cat("=== X-13's own identity: log z = log(s11) + log(s10) ===\n")
cat("  max deviation:", signif(id, 3), "\n")
cat("It holds against the RAW series here, which tells you no regARIMA\n")
cat("preadjustment happened. With trading-day or outliers active it would hold\n")
cat("against the LINEARIZED series instead -- that is how you find out what a\n")
cat("black box actually did.\n\n")

op <- par(mfrow = c(2, 1), mar = c(3, 4, 2, 1))
plot(tab$s12, ylab = "trend", main = "trend: X-13 (black) vs ours (red dashed)")
lines(mine$s12, col = "firebrick", lty = 2, lwd = 2)
plot(100 * (as.numeric(mine$s10) - as.numeric(tab$s10)) / as.numeric(tab$s10),
     type = "h", ylab = "% diff", xlab = "", main = "seasonal factors: difference")
abline(h = 0)
par(op)

# EXERCISE 2: the harness error that costs an hour ----------------------
cat("=== EXERCISE 2: what if transform.function is wrong? ===\n")
m_add <- seas(x, transform.function = "none", arima.model = "(0 1 1)(0 1 1)",
              regression.aictest = NULL, outlier = NULL)
a10 <- series(m_add, "s10")
cat("  additive s10 ranges", round(range(a10), 3),
    "  vs multiplicative", round(range(tab$s10), 3), "\n")
cat("  Additive factors sit around 0, multiplicative around 1. Comparing them\n")
cat("  gives a ~100% 'error' that has nothing to do with the algorithm.\n")
cat("  WHEN A COMPARISON FAILS BY A LOT, SUSPECT THE HARNESS FIRST.\n\n")

# EXERCISE 3: turning outlier detection back on -------------------------
cat("=== EXERCISE 3: with outlier detection on ===\n")
m_out <- seas(x, transform.function = "log", arima.model = "(0 1 1)(0 1 1)",
              regression.aictest = NULL)
# coef() returns the ARIMA coefficients too -- keep only the outlier regressors,
# which are named AOyyyy.mm / LSyyyy.mm / TCyyyy.mm.
outs <- grep("^(AO|LS|TC)", names(coef(m_out)), value = TRUE)
cat("  outliers found:", if (length(outs)) paste(outs, collapse = ", ") else "none", "\n")
o10 <- series(m_out, "s10")
cat("  max change in s10 vs the clean run:",
    round(100*max(abs(as.numeric(o10) - as.numeric(tab$s10))/as.numeric(tab$s10)), 4), "%\n\n")

# EXERCISE 5: method difference vs implementation error -----------------
source("R/_x11.R")
d11 <- x11_decompose(x)$d11
cat("=== EXERCISE 5: which is bigger, method or implementation? ===\n")
seats_vs_x11 <- 100*mean(abs(as.numeric(tab$s11) - as.numeric(d11))/as.numeric(d11))
impl_err     <- 100*mean(abs(as.numeric(mine$s11) - as.numeric(tab$s11))/as.numeric(tab$s11))
cat(sprintf("  SEATS vs X-11 (method difference)      : %.3f%%\n", seats_vs_x11))
cat(sprintf("  ours vs X-13 SEATS (implementation)    : %.6f%%\n", impl_err))
cat("  The implementation difference is now at the level of the forecast\n")
cat("  extension and the printed precision of X-13's own tables, so the ratio\n")
cat("  of the two is no longer a meaningful number. It says only that the two\n")
cat("  implementations agree and the two METHODS do not.\n")
cat("\nThe choice of METHOD matters far more than implementation precision.\n")
cat("Which of the two adjustments you publish is a real decision; whether your\n")
cat("code agrees with Census to 4 or 6 decimals is not.\n")
