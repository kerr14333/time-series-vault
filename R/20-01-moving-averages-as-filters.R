# 20-01 -- A moving average is a filter. Gain and phase.
source("R/_setup.R"); source("R/_x11.R")

f <- seq(0, 0.5, length.out = 1001)

# EXERCISE 1: the 3-term MA -------------------------------------------------
w3 <- rep(1, 3) / 3
op <- par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))
plot(f, gain(w3, f), type = "l", lwd = 2, xlab = "cycles per period", ylab = "gain",
     main = "3-term MA: gain")
abline(v = 1/3, col = "firebrick", lty = 2); abline(h = 0, col = "grey85")
plot(f, phase(w3, f), type = "l", lwd = 2, xlab = "cycles per period",
     ylab = "phase", main = "phase is identically 0")
par(op)
cat("gain at 1/3:", signif(gain(w3, 1/3), 3), "  <- exactly zero\n")
cat("why: a 3-term average of a period-3 cycle averages one whole cycle = its mean.\n")
cat("max |phase| over all frequencies:", signif(max(abs(phase(w3, f))), 3), "\n\n")

# EXERCISE 2: uncentred 12-term MA has nonzero phase ------------------------
# An even-length MA cannot be centred on an observation, so it shifts time.
w12_odd  <- rep(1, 12) / 12          # treated as centred -> half-period off
w12_cent <- ma_2x12()
cat("12-term (even, uncentred) -- max |phase|:",
    round(max(abs(Arg(sapply(f, function(x) sum(w12_odd * exp(-2i * pi * x * (0:11))))))), 3), "\n")
cat("2x12 (centred)            -- max |phase|:",
    round(max(abs(phase(w12_cent, f))), 3), "  <- zero, because symmetric\n\n")

# EXERCISE 3: composition multiplies the gains ------------------------------
a <- rep(1, 3) / 3
b <- rep(1, 5) / 5
ab <- poly_mult(a, b)                       # convolution = applying one then the other
lhs <- gain(ab, f)
rhs <- gain(a, f) * gain(b, f)
cat("max |gain(a*b) - gain(a)*gain(b)| =", signif(max(abs(lhs - rhs)), 3), "\n")
cat("So an iteration of moving averages is ONE filter. That is how X-11 gets analysed.\n")

plot(f, rhs, type = "l", lwd = 4, col = "grey70", xlab = "cycles per period", ylab = "gain",
     main = "3-term x 5-term: composed gain = product of gains")
lines(f, lhs, col = "firebrick", lwd = 2, lty = 2)
legend("topright", c("gain(a) x gain(b)", "gain(a*b)"),
       col = c("grey70", "firebrick"), lwd = c(4, 2), lty = c(1, 2), bty = "n")

# What a trend filter vs an SA filter should look like ----------------------
cat("\nTargets to keep in mind:\n")
cat("  trend filter: gain 1 at freq 0, 0 at seasonal freqs, 0 at high freqs\n")
cat("  SA filter   : gain 1 at freq 0, 0 at seasonal freqs, ~1 at high freqs\n")
cat("The difference is the irregular: an SA series keeps it, a trend does not.\n")
