# 30-01 -- Frequencies, periods, harmonics, aliasing.
source("R/_setup.R"); source("R/_spectral.R")

# The table to learn --------------------------------------------------------
k <- 1:6
tab <- data.frame(k = k, cycles_per_month = round(k/12, 4),
                  omega_radians = round(2*pi*k/12, 4),
                  period_months = round(12/k, 2))
cat("the six seasonal frequencies for monthly data:\n"); print(tab, row.names = FALSE)
cat("plus frequency 0 (period Inf) = THE TREND\n")
cat("k=6 is the Nyquist frequency: period 2, the fastest observable cycle.\n\n")

# EXERCISE 1: harmonics -- why the seasonal is six frequencies, not one -----
t <- 1:96
pure   <- sin(2*pi*t/12)
spiky  <- sin(2*pi*t/12) + 0.4*sin(2*pi*t/6) + 0.3*sin(2*pi*t/4) + 0.2*sin(2*pi*t/3)
op <- par(mfrow = c(2, 2), mar = c(3, 4, 2, 1))
plot(ts(pure, frequency = 12),  ylab = "", main = "pure sine, period 12")
plot(ts(spiky, frequency = 12), ylab = "", main = "period 12 WITH harmonics")
for (x in list(pure, spiky)) {
  sp <- spec.pgram(ts(x, frequency = 1), taper = 0, plot = FALSE, detrend = FALSE)
  plot(sp$freq, sp$spec, type = "h", lwd = 2, log = "y", xlab = "cycles/month",
       ylab = "power", main = "where the power sits")
  mark_seasonal_freq()
}
par(op)
cat("Both repeat every 12 months. The pure sine uses ONE frequency; any other\n")
cat("period-12 shape needs harmonics at periods 6, 4, 3, 2.4, 2.\n")
cat("That is why (1 - B^12) has 12 roots and why seasonal filters have 6 notches.\n\n")

# EXERCISE 2: aliasing ------------------------------------------------------
fine  <- seq(1, 40, by = 0.05)
fast  <- sin(2*pi*fine/1.5)            # period 1.5 months
month <- 1:40
samp  <- sin(2*pi*month/1.5)
plot(fine, fast, type = "l", col = "grey70", xlab = "month", ylab = "",
     main = "period 1.5 sampled monthly LOOKS like period 3 (aliasing)")
points(month, samp, pch = 19, col = "firebrick")
lines(fine, sin(2*pi*fine/3 + pi), col = "steelblue", lwd = 2, lty = 2)
legend("topright", c("true period 1.5", "monthly samples", "apparent period 3"),
       col = c("grey70", "firebrick", "steelblue"), lwd = 2, bty = "n", cex = 0.8)
cat("A period-1.5 cycle is indistinguishable from a slower one once sampled\n")
cat("monthly. Nothing above the Nyquist frequency is observable -- which is why\n")
cat("every spectral plot stops at 0.5 cycles/month.\n\n")

# EXERCISE 3: the squared-modulus identity ---------------------------------
w <- seq(0, pi, length.out = 7)
lhs <- Mod(1 - 0.8*exp(-1i*w))^2
rhs <- Re((1 - 0.8*exp(-1i*w)) * (1 - 0.8*exp(1i*w)))
cat("|1 - 0.8 e^{-iw}|^2 vs (1-0.8B)(1-0.8F):\n")
print(round(rbind(lhs = lhs, rhs = rhs), 6))
cat("max difference:", signif(max(abs(lhs - rhs)), 3), "-- and the result is REAL.\n")
cat("This identity, |w|^2 = w * conj(w), is where SEATS's B-and-F pairing\n")
cat("comes from. theta(B)theta(F) is just a squared modulus.\n")
