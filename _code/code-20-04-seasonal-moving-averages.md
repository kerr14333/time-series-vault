---
aliases: [20-04-seasonal-moving-averages.R]
tags: [code, generated]
---

# `R/20-04-seasonal-moving-averages.R`

Seasonal MAs: smoothing ACROSS YEARS within a calendar month.

> [!info] Generated file
> Mirror of `R/20-04-seasonal-moving-averages.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[20-04-seasonal-moving-averages]]

```r
# 20-04 -- Seasonal MAs: smoothing ACROSS YEARS within a calendar month.
source("R/_setup.R"); source("R/_x11.R")

# EXERCISE 1: derive 3x5 by convolution ------------------------------------
w35 <- poly_mult(rep(1, 3) / 3, rep(1, 5) / 5)
cat("3x5 = (1/3)(1,1,1) * (1/5)(1,1,1,1,1):\n")
print(round(w35 * 15, 6))
cat("i.e. (1,2,3,3,3,2,1)/15. Matches seasonal_ma('3x5'):",
    isTRUE(all.equal(w35, seasonal_ma("3x5"))), "\n\n")
for (t in c("3x3", "3x5", "3x9")) {
  w <- seasonal_ma(t)
  cat(sprintf("%-4s: %2d terms (%2d years), sums to %.6f\n",
              t, length(w), length(w), sum(w)))
}

# EXERCISE 2: smooth the January SI ratios ---------------------------------
z  <- AirPassengers
T1 <- na_fill_ends(symfilter(z, ma_2x12()))
SI <- z / T1
yrs <- 1949:1960
jan <- as.numeric(SI)[seq(1, length(SI), by = 12)]

plot(yrs, jan, type = "b", pch = 19, col = "grey40", lwd = 2,
     xlab = "year", ylab = "SI ratio", main = "January SI ratios and two smoothers")
cols <- c("steelblue", "firebrick")
for (i in 1:2) {
  sm <- as.numeric(stats::filter(jan, seasonal_ma(c("3x3", "3x5")[i]), sides = 2))
  lines(yrs, sm, col = cols[i], lwd = 3)
}
legend("bottomleft", c("raw SI", "3x3 (adapts)", "3x5 (steadier)"),
       col = c("grey40", cols), lwd = 2, bty = "n")

sd_of <- function(w) sd(as.numeric(stats::filter(jan, w, sides = 2)), na.rm = TRUE)
cat("\nvariability of the smoothed January factor:\n")
cat("  raw SI :", round(sd(jan), 5), "\n")
for (t in c("3x3", "3x5", "3x9")) cat(sprintf("  %-4s   : %.5f\n", t, sd_of(seasonal_ma(t))))
cat("Longer filter -> steadier pattern -> slower to adapt. Same trade-off that\n")
cat("Theta controls in the airline model (see 10-10).\n\n")

# EXERCISE 3: what the centring step is for --------------------------------
S_uncentred <- seasonal_smooth(SI, seasonal_ma("3x5"))
S_centred   <- S_uncentred / na_fill_ends(symfilter(S_uncentred, ma_2x12()))

annual_mean <- function(s) tapply(as.numeric(s), rep(1:12, length.out = length(s)) * 0 +
                                   rep(1:(length(s) %/% 12), each = 12)[1:length(s)], mean)
cat("mean of the seasonal factors within each year (should be 1):\n")
cat("  uncentred: range", round(range(annual_mean(S_uncentred)), 5), "\n")
cat("  centred  : range", round(range(annual_mean(S_centred)), 5), "\n")

d_un <- z / S_uncentred
d_ce <- z / S_centred
cat("\nresulting adjusted series differ by up to",
    round(100 * max(abs(d_un - d_ce) / d_ce), 3), "%\n")
cat("Small, but it is a DRIFT -- it accumulates and leaks trend into the seasonal.\n")
cat("Cheap to include, hard to diagnose if omitted. Put it in from the start.\n")

op <- par(mfrow = c(1, 1))
plot(annual_mean(S_uncentred), type = "b", pch = 19, ylab = "within-year mean factor",
     xlab = "year index", main = "why centring matters")
lines(annual_mean(S_centred), type = "b", pch = 19, col = "firebrick")
abline(h = 1, lty = 2, col = "grey50")
legend("topright", c("uncentred", "centred"), col = c("black", "firebrick"), lwd = 2, bty = "n")
par(op)
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/20-04-seasonal-moving-averages.R")
```

Back to [[20-04-seasonal-moving-averages]] · index: [[code-index]]
