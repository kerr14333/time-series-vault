# 20-06 -- Extreme values: the one nonlinear step.
source("R/_setup.R"); source("R/_x11.R")

z <- AirPassengers
spike_at <- 61                                  # January 1954
z2 <- z; z2[spike_at] <- z2[spike_at] * 1.30    # +30%
cat("spike inserted at", format(time(z)[spike_at]), "(index", spike_at, ")\n\n")

clean   <- x11_decompose(z,  extreme = TRUE)
handled <- x11_decompose(z2, extreme = TRUE)
naive   <- x11_decompose(z2, extreme = FALSE)

# EXERCISE 1: contamination of OTHER Januaries -----------------------------
jan <- seq(1, length(z), by = 12)
tab <- data.frame(
  year    = 1949:1960,
  clean   = round(as.numeric(clean$d10)[jan], 4),
  handled = round(as.numeric(handled$d10)[jan], 4),
  naive   = round(as.numeric(naive$d10)[jan], 4)
)
tab$naive_err   <- round(100 * (tab$naive   - tab$clean) / tab$clean, 2)
tab$handled_err <- round(100 * (tab$handled - tab$clean) / tab$clean, 2)
print(tab)

others <- setdiff(seq_len(nrow(tab)), which(tab$year == 1954))
cat(sprintf("\nmean |error| on the OTHER eleven Januaries: naive %.2f%%, handled %.2f%%\n",
            mean(abs(tab$naive_err[others])), mean(abs(tab$handled_err[others]))))
cat("One bad month corrupts the seasonal factor for years around it, because the\n")
cat("seasonal filter smooths ACROSS YEARS within a calendar month (see 20-04).\n")

plot(tab$year, tab$clean, type = "b", pch = 19, ylim = range(tab[, 2:4]),
     xlab = "year", ylab = "January seasonal factor",
     main = "one +30% spike in Jan 1954")
lines(tab$year, tab$handled, type = "b", pch = 19, col = "steelblue")
lines(tab$year, tab$naive,   type = "b", pch = 19, col = "firebrick")
legend("topleft", c("clean data", "spiked, extremes handled", "spiked, NOT handled"),
       col = c("black", "steelblue", "firebrick"), lwd = 2, bty = "n", cex = 0.85)

# EXERCISE 2: the spike SURVIVES in D11 ------------------------------------
cat("\nD11 around the spike (extremes handled):\n")
print(round(window(handled$d11, start = c(1953, 11), end = c(1954, 3)), 1))
cat("original data at the spike:", round(z2[spike_at], 1),
    " vs clean-data D11 there:", round(clean$d11[spike_at], 1), "\n")
cat("The event is still visible. Downweighting affects how the FACTORS are\n")
cat("estimated, never what gets published as the adjusted series.\n")

# EXERCISE 3: sensitivity to the sigma limits ------------------------------
cat("\nsigma limits: effect on D11\n")
irr <- clean$d13
for (lims in list(c(1.5, 2.5), c(2.0, 3.0), c(2.5, 4.0))) {
  w <- extreme_weights(irr, lims)
  cat(sprintf("  (%.1f, %.1f): %2d obs downweighted, %2d fully replaced\n",
              lims[1], lims[2], sum(w < 1), sum(w == 0)))
}
cat("\nDefaults are (1.5, 2.5). Wider limits = fewer interventions = more\n")
cat("faith in the data. X-13 exposes this as x11.sigmalim.\n")

# EXERCISE 4: the modern alternative -- an AO regressor --------------------
if (requireNamespace("seasonal", quietly = TRUE)) {
  ao <- sprintf("AO%d.%d", 1954, 1)
  m <- seasonal::seas(z2, x11 = "", transform.function = "log",
                      regression.variables = ao, regression.aictest = NULL,
                      outlier = NULL, arima.model = "(0 1 1)(0 1 1)")
  cat("\nsame spike handled as a regARIMA additive outlier:\n")
  print(round(coef(m), 4))
  cat("estimated AO effect:", round(100 * (exp(coef(m)[[ao]]) - 1), 1),
      "%  (truth +30%)\n")
  cat("This is strictly better where it applies: a coefficient, a standard error,\n")
  cat("and a distinction between AO / LS / TC that sigma limits cannot make.\n")
}
