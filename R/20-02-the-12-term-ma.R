# 20-02 -- The centred 12-term MA: X-11's first move.
source("R/_setup.R"); source("R/_x11.R")

# EXERCISE 1: derive the weights by polynomial multiplication ---------------
half <- c(1, 1) / 2                       # (1/2)(1 + B)
twelve <- rep(1, 12) / 12                 # (1/12)(1 + B + ... + B^11)
w <- poly_mult(half, twelve)
cat("(1/2)(1+B) * (1/12)(1+...+B^11) gives", length(w), "weights:\n")
print(round(w * 24, 6))
cat("i.e. (1,2,2,...,2,1)/24. Matches ma_2x12():",
    isTRUE(all.equal(w, ma_2x12())), "\n")
cat("sum of weights:", sum(w), "\n\n")

# EXERCISE 2: the gain ------------------------------------------------------
f <- seq(0, 0.5, length.out = 2001)
g <- gain(ma_2x12(), f)
plot(f, g, type = "l", lwd = 2, xlab = "cycles per month", ylab = "gain",
     main = "2x12 MA: zeros exactly at the seasonal frequencies")
abline(h = 0, col = "grey85"); abline(v = SEAS_FREQ, col = "firebrick", lty = 3)
cat("gain at the six seasonal frequencies:\n"); print(signif(gain(ma_2x12(), SEAS_FREQ), 3))
cat("gain at frequency 0:", gain(ma_2x12(), 0), "\n")

# side lobes: where does the filter LEAK, and with what sign?
tf <- Re(transfer(ma_2x12(), f))
neg <- f[tf < -1e-10]
cat("\nfrequencies where the transfer function is NEGATIVE (phase flip of pi):\n")
cat("  from", round(min(neg), 3), "to", round(max(neg), 3), "cycles/month\n")
cat("  worst leakage:", round(min(tf), 4), "\n\n")

# EXERCISE 3: it kills period 12, but not period 11 -------------------------
n <- 240; t <- 1:n
line   <- 100 + 0.5 * t
s12    <- 10 * sin(2 * pi * t / 12)
s11    <- 10 * sin(2 * pi * t / 11)

for (lab in c("period 12", "period 11")) {
  x  <- line + if (lab == "period 12") s12 else s11
  sm <- symfilter(x, ma_2x12())
  resid <- (sm - line)[13:(n - 12)]
  cat(sprintf("%-10s : max |smoothed - true line| = %7.4f\n", lab, max(abs(resid))))
}
cat("\nPeriod 12 vanishes to machine precision. Period 11 does NOT --\n")
cat("a near-seasonal cycle leaks straight into the 'trend'. Real series with\n")
cat("moving or non-exact seasonality are exactly this case, which is one reason\n")
cat("X-11 iterates rather than trusting this first estimate.\n")

op <- par(mfrow = c(2, 1), mar = c(3, 4, 2, 1))
plot(ts(line + s12), ylab = "", main = "period 12 + line"); lines(symfilter(line + s12, ma_2x12()), col = "firebrick", lwd = 2)
plot(ts(line + s11), ylab = "", main = "period 11 + line (leaks through)"); lines(symfilter(line + s11, ma_2x12()), col = "firebrick", lwd = 2)
par(op)

# ---- the same filter, quarterly ------------------------------------------
cat("\n=== 2xs MA: nothing is special about 12 ===\n")
for (s in c(12, 4)) {
  w <- ma_2xs(s)
  cat(sprintf("  s = %2d : %2d terms, weights x %2d = %s, sum = %g\n",
              s, length(w), 2*s, paste(round(w * 2 * s), collapse = " "), sum(w)))
  cat(sprintf("           seasonal frequencies: %s\n",
              paste(round(seas_freq(s), 4), collapse = " ")))
  cat(sprintf("           gain there           : %s\n",
              paste(signif(gain(w, seas_freq(s)), 3), collapse = " ")))
}
cat("\nQuarterly has TWO seasonal frequencies, not six. The gain is exactly zero\n")
cat("at both, for the same reason: an s-term average of a period-s pattern\n")
cat("averages one whole cycle.\n")

op <- par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))
for (s in c(12, 4)) {
  ff <- seq(0, 0.5, length.out = 1001)
  plot(ff, gain(ma_2xs(s), ff), type = "l", lwd = 2, xlab = "cycles per period",
       ylab = "gain", main = sprintf("2x%d MA", s))
  abline(h = 0, col = "grey85"); abline(v = seas_freq(s), col = "firebrick", lty = 3)
}
par(op)
