# 30-02 -- The spectral density: variance distributed over frequency.
source("R/_setup.R"); source("R/_spectral.R")
set.seed(101)

# EXERCISE 1: the periodogram is NOT consistent ----------------------------
w <- rnorm(512)
op <- par(mfrow = c(2, 2), mar = c(4, 4, 2, 1))
for (sp in list(NULL, c(3,3), c(7,7), c(15,15))) {
  s <- spec.pgram(w, spans = sp, taper = 0, plot = FALSE, detrend = FALSE)
  plot(s$freq, s$spec, type = "l", xlab = "cycles/period", ylab = "power",
       ylim = c(0, 4), main = if (is.null(sp)) "raw periodogram" else paste("spans =", paste(sp, collapse = ",")))
  abline(h = 1, col = "firebrick", lwd = 2)
}
par(op)
cat("True spectrum of white noise is FLAT (red line). The raw periodogram is\n")
cat("grass: its variance does not shrink with n. Smoothing is not optional.\n\n")

sd_of <- function(sp) sd(spec.pgram(w, spans = sp, taper = 0, plot = FALSE, detrend = FALSE)$spec)
cat("sd of the estimate:  raw", round(sd_of(NULL), 3),
    " spans(3,3)", round(sd_of(c(3,3)), 3),
    " spans(15,15)", round(sd_of(c(15,15)), 3), "\n\n")

# EXERCISE 2: area under the spectrum = variance ---------------------------
x <- arima.sim(list(ar = 0.7), 4000)
g <- as.numeric(acf(x, lag.max = 200, plot = FALSE, type = "covariance")$acf)
f <- spectrum_from_acov(g, FREQ)
area <- 2 * sum((head(f, -1) + tail(f, -1)) / 2 * diff(FREQ)) * 2 * pi
cat("integral of f over [-pi,pi]:", round(area, 4), "\n")
cat("sample variance             :", round(var(x), 4), "\n")
cat("(the spectrum distributes the variance across frequency)\n\n")

# EXERCISE 3: airline data, ACF and spectrum say the same thing ------------
d <- diff(diff(lap), 12)
op <- par(mfrow = c(2, 1), mar = c(4, 4, 2, 1))
acf(d, lag.max = 40, main = "(1-B)(1-B^12) log(AirPassengers): ACF")
s <- spec.pgram(d, spans = c(3,3), taper = 0.1, plot = FALSE)
plot(s$freq, log(s$spec), type = "l", lwd = 2, xlab = "cycles/month",
     ylab = "log power", main = "the same series: spectrum")
mark_seasonal_freq()
par(op)
cat("Same information, two coordinate systems. The ACF spikes at 1, 11, 12, 13;\n")
cat("the spectrum shows what is left near the seasonal frequencies.\n\n")

# EXERCISE 4: did seasonal adjustment actually remove the peaks? -----------
source("R/_x11.R")
d11 <- x11_decompose(AirPassengers)$d11
op <- par(mfrow = c(2, 1), mar = c(4, 4, 2, 1))
for (nm in c("raw", "seasonally adjusted")) {
  y <- diff(log(if (nm == "raw") AirPassengers else d11))
  s <- spec.pgram(y, spans = c(3,3), taper = 0.1, plot = FALSE)
  plot(s$freq, log(s$spec), type = "l", lwd = 2, xlab = "cycles/month",
       ylab = "log power", main = paste("differenced log", nm))
  mark_seasonal_freq()
}
par(op)
cat("Peaks at the seasonal frequencies in the top panel; gone in the bottom.\n")
cat("A peak SURVIVING in the bottom panel is residual seasonality -- the most\n")
cat("damning diagnostic there is. See 50-02.\n")
