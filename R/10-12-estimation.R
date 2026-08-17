# 10-12 -- ML vs CSS, and why outliers wreck an ARIMA fit.
source("R/_setup.R")

# EXERCISE 1: ML vs CSS on the seasonal MA ----------------------------------
f_ml  <- arima(lap, c(0,1,1), list(order = c(0,1,1), period = 12), method = "ML")
f_css <- arima(lap, c(0,1,1), list(order = c(0,1,1), period = 12), method = "CSS")
cmp <- rbind(ML  = ma_r_to_census(coef(f_ml)),
             CSS = ma_r_to_census(coef(f_css)))
cat("Census-convention estimates:\n"); print(round(cmp, 4))
cat("\nSeasonal MA sits near the unit circle, which is exactly where CSS degrades.\n")
cat("X-13 and arima(method='ML') both use EXACT ML via the Kalman filter.\n")

# EXERCISE 2: a level shift wrecks the fit, xreg rescues it -----------------
y <- lap
shift_at <- 100
y[shift_at:length(y)] <- y[shift_at:length(y)] + 0.25     # artificial LS

f_clean  <- arima(lap, c(0,1,1), list(order = c(0,1,1), period = 12))
f_broken <- arima(y,   c(0,1,1), list(order = c(0,1,1), period = 12))

ls_reg <- as.numeric(seq_along(y) >= shift_at)            # level-shift regressor
f_fixed <- arima(y, c(0,1,1), list(order = c(0,1,1), period = 12), xreg = ls_reg)

res <- rbind(clean            = ma_r_to_census(coef(f_clean)),
             `with LS, no reg`= ma_r_to_census(coef(f_broken))[1:2],
             `with LS + xreg` = ma_r_to_census(coef(f_fixed))[1:2])
cat("\ntheta and Theta (Census):\n"); print(round(res, 4))
cat("\nestimated shift size:", round(coef(f_fixed)["ls_reg"], 4), " (truth 0.25)\n")
cat("\nUndetected level shifts distort the ARIMA parameters, and through them the\n")
cat("seasonal factors. That is the main reason regARIMA exists.\n")

# EXERCISE 3: over-parameterisation blows up the standard errors -----------
f_big <- arima(lap, c(3,1,3), list(order = c(1,1,1), period = 12), method = "ML")
se <- sqrt(diag(f_big$var.coef))
tab <- data.frame(coef = round(coef(f_big), 3), se = round(se, 3),
                  t = round(coef(f_big) / se, 2))
cat("\nover-parameterised (3,1,3)(1,1,1):\n"); print(tab)
cat("\nCompare AIC:  airline =", round(AIC(f_clean), 2),
    "   big =", round(AIC(f_big), 2), "\n")

# What X-13 actually hands to SEATS: the LINEARIZED series ------------------
if (requireNamespace("seasonal", quietly = TRUE)) {
  m <- seasonal::seas(AirPassengers)
  cat("\nX-13 regression effects it found:\n")
  print(coef(m))
  lin <- seasonal::series(m, "a19")     # may not exist for this series
  cat("\n(the linearized series is what gets decomposed -- see 40-00)\n")
}
