# 00 -- The test series, and what each one breaks.
source("R/_setup.R"); source("R/_series.R")

S <- vault_series()

cat("=== the catalogue ===\n")
for (nm in names(S)) {
  x <- S[[nm]]
  cat(sprintf("%-12s n=%4d freq=%2d  %s\n", nm, length(x), frequency(x),
              vault_series_notes[[nm]]))
}

# Plot them all -------------------------------------------------------------
op <- par(mfrow = c(4, 3), mar = c(2, 3, 2, 1))
for (nm in names(S)) plot(S[[nm]], ylab = "", main = nm)
par(op)

# What does the airline model say about each? ------------------------------
cat("\n=== forcing the airline model on every series (Census signs) ===\n")
cat(sprintf("%-12s %8s %8s   %s\n", "series", "theta", "Theta", "reading"))
for (nm in names(S)) {
  f <- tryCatch(airline_fit(S[[nm]]), error = function(e) NULL)
  if (is.null(f)) { cat(sprintf("%-12s  did not converge\n", nm)); next }
  flag <- if (f$theta > 0.98 || f$Theta > 0.98) "PINNED -- over-differenced?"
          else if (f$Theta > 0.85) "very stable seasonal"
          else if (f$Theta < 0.4)  "volatile seasonal, expect big revisions"
          else ""
  cat(sprintf("%-12s %8.3f %8.3f   %s\n", nm, f$theta, f$Theta, flag))
}

# ldeaths: the over-differencing case, worked -----------------------------
cat("\n=== ldeaths: the airline model is WRONG for this series ===\n")
f_forced <- airline_fit(ldeaths)
cat(sprintf("forced airline (0,1,1)(0,1,1): theta = %.4f, Theta = %.4f\n",
            f_forced$theta, f_forced$Theta))
cat("Both pinned at the non-invertible boundary -- see 10-05.\n")
f_auto <- arima(log(ldeaths), c(0, 0, 1), list(order = c(0, 1, 1), period = 12))
cat(sprintf("X-13's choice   (0,0,1)(0,1,1): theta = %.4f, Theta = %.4f\n",
            -coef(f_auto)["ma1"], -coef(f_auto)["sma1"]))
cat(sprintf("AICC-ish: forced %.2f  vs  auto %.2f\n", AIC(f_forced$fit), AIC(f_auto)))
cat("d = 0. There was never a regular unit root to remove. The pinned\n")
cat("coefficient was the model telling you so.\n")

# Variance check, the cheap version of the same diagnostic ----------------
v <- c(log = var(log(ldeaths)),
       seasonal_diff = var(diff(log(ldeaths), 12)),
       both = var(diff(diff(log(ldeaths)), 12)))
cat("\nvariance after each differencing of log(ldeaths):\n"); print(round(v, 5))
cat("The regular difference INCREASES the variance -- stop before it.\n")

# Quarterly series: does everything generalise? --------------------------
cat("\n=== quarterly (s=4): the seasonal frequencies move ===\n")
cat("monthly  : k/12 for k=1..6 ->", round((1:6)/12, 4), "\n")
cat("quarterly: k/4  for k=1..2 ->", round((1:2)/4, 4), "\n")
cat("So a quarterly series has TWO seasonal frequencies, not six, and X-11\n")
cat("uses a 2x4 MA and a 5- or 7-term Henderson. Nothing conceptual changes.\n")

if (requireNamespace("seasonal", quietly = TRUE)) {
  cat("\n=== cpi: SEATS rejects the fitted model ===\n")
  m <- seasonal::seas(seasonal::cpi)
  cat("regARIMA fitted :", paste(m$model$arima$model, collapse = ""), "\n")
  u <- seasonal::udg(m)
  if ("seatsmdl" %in% names(u)) cat("SEATS actually used:", u[["seatsmdl"]], "\n")
  cat("\nThe components you get did NOT come from the model that was fitted.\n")
  cat("SEATS could not split the fitted model into non-negative component\n")
  cat("spectra, so it substituted a nearby one it could. See 40-02.\n")
}
