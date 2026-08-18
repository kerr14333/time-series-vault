# 40-02 -- Which models can be decomposed at all?
source("R/_setup.R"); source("R/_spectral.R"); source("R/_seats.R"); source("R/_series.R")

admiss <- function(theta, Theta, s = 12, ngrid = 1200) {
  ma <- poly_mult(c(1, -theta), c(1, rep(0, s - 1), -Theta))
  sp <- seats_ar_split(1, 1, s)
  cn <- seats_canonical(seats_partial_fractions(ma, sp$trend, sp$seasonal, ngrid = ngrid), 2500)
  c(gT = cn$min_gT, gS = cn$min_gS, gI = cn$min_gI, ok = as.numeric(cn$admissible))
}

# EXERCISE 2: walk along Theta = 0.5 and find the boundary ----------------
cat("=== along Theta = 0.5, varying theta ===\n")
cat(sprintf("%7s %10s %10s %10s  %s\n", "theta", "min gT", "min gS", "min gI", "verdict"))
for (th in seq(-0.6, 0.6, by = 0.1)) {
  r <- admiss(th, 0.5)
  cat(sprintf("%7.2f %10.4f %10.4f %10.4f  %s\n", th, r[1], r[2], r[3],
              if (r[4] == 1) "admissible" else "INADMISSIBLE"))
}
cat("\nThe IRREGULAR is what goes negative first as theta falls below 0.\n")
cat("Intuition: the irregular's spectrum is the flat constant left over. A\n")
cat("negative theta puts a PEAK rather than a trough at high frequency, so the\n")
cat("trend and seasonal jointly demand more than the model supplies, and the\n")
cat("leftover comes out negative.\n\n")

# EXERCISE 1: the region map ---------------------------------------------
grid <- seq(-0.9, 0.9, by = 0.1)
ok <- outer(grid, grid, Vectorize(function(a, b) admiss(a, b, ngrid = 500)[4]))
cat("admissible fraction of the grid:", round(mean(ok), 3), "\n\n")
cat("by quadrant:\n")
for (st in c(-1, 1)) for (ss in c(-1, 1)) {
  ii <- grid * st > 0; jj <- grid * ss > 0
  cat(sprintf("  theta %s 0, Theta %s 0 : %5.1f%%\n",
              ifelse(st < 0, "<", ">"), ifelse(ss < 0, "<", ">"),
              100 * mean(ok[ii, jj])))
}
cat("\nRULE OF THUMB: for the airline model, admissible ~ BOTH MA parameters\n")
cat("positive in Census signs. And 10-11 noted that well-behaved economic\n")
cat("series give positive Census MA parameters -- which is why you can adjust\n")
cat("hundreds of series and never meet this.\n")

image(grid, grid, ok, col = c("grey85", "steelblue"),
      xlab = expression(theta), ylab = expression(Theta),
      main = "airline model: admissible region (blue)")
points(0.4018, 0.5569, pch = 19, col = "firebrick", cex = 1.5)
text(0.4018, 0.5569, " AirPassengers", pos = 4, col = "firebrick", cex = 0.8)
abline(h = 0, v = 0, lty = 3, col = "grey40")

# EXERCISE 3: the whole catalogue ----------------------------------------
cat("\n=== every catalogue series, forced airline model ===\n")
cat(sprintf("%-12s %7s %7s %10s %10s %10s  %s\n",
            "series", "theta", "Theta", "min gT", "min gS", "min gI", "verdict"))
S <- vault_series()
for (nm in names(S)) {
  f <- tryCatch(airline_fit(S[[nm]]), error = function(e) NULL); if (is.null(f)) next
  r <- tryCatch(admiss(f$theta, f$Theta, frequency(S[[nm]])), error = function(e) NULL)
  if (is.null(r)) next
  cat(sprintf("%-12s %7.3f %7.3f %10.4f %10.4f %10.4f  %s\n", nm, f$theta, f$Theta,
              r[1], r[2], r[3], if (r[4] == 1) "admissible" else "INADMISSIBLE"))
}
cat("\ncpi is the ONLY failure, the ONLY series with negative theta, and --\n")
cat("independently -- the ONLY one where the real X-13 refuses the model.\n")

# EXERCISES 4-5: what X-13 does about it ---------------------------------
if (requireNamespace("seasonal", quietly = TRUE)) {
  cat("\n=== X-13 on cpi ===\n")
  m <- seasonal::seas(seasonal::cpi)
  cat("regARIMA fitted   :", paste(m$model$arima$model, collapse = ""), "\n")
  cat("SEATS actually used:", seasonal::udg(m, "seatsmdl"), "\n")
  cat("\nThe components did NOT come from the model that was fitted. Check for\n")
  cat("this with udg(m, 'seatsmdl') whenever you use SEATS.\n")

  cat("\nwith seats.noadmiss = 'no' (refuse rather than substitute):\n")
  r <- tryCatch(seasonal::seas(seasonal::cpi, seats.noadmiss = "no"),
                error = function(e) conditionMessage(e))
  cat(if (is.character(r)) paste(" error:", substr(r, 1, 120)) else " (it succeeded)", "\n")
}
