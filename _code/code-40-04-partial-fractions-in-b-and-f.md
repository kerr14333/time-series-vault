---
aliases: [40-04-partial-fractions-in-b-and-f.R]
tags: [code, generated]
---

# `R/40-04-partial-fractions-in-b-and-f.R`

The partial fractions, with numbers.

> [!info] Generated file
> Mirror of `R/40-04-partial-fractions-in-b-and-f.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[40-04-partial-fractions-in-b-and-f]]

```r
# 40-04 -- The partial fractions, with numbers.
source("R/_setup.R"); source("R/_spectral.R"); source("R/_seats.R")

# EXERCISE 1: cosine polynomials, by hand ---------------------------------
cat("=== representing |P(e^{-iw})|^2 as a cosine polynomial ===\n")
p <- c(1, -0.4)                                  # P(B) = 1 - 0.4B
cc <- cospoly_from_poly(p)
cat("P(B) = 1 - 0.4B  ->  cosine coefficients", round(cc, 4), "\n")
cat("meaning  |P|^2 = ", cc[1], " + 2*(", cc[2], ")*cos(w)\n", sep = "")
cat("check by hand: |1 - 0.4 e^{-iw}|^2 = 1 + 0.16 - 0.8 cos w = 1.16 - 0.8 cos w\n")
w <- c(0, 1, 2, 3)
cat("numeric check, max diff:",
    signif(max(abs(cospoly_eval(cc, w) - Mod(1 - 0.4*exp(-1i*w))^2)), 3), "\n")
cat("The coefficients are just the AUTOCOVARIANCES of the coefficient sequence.\n\n")

# EXERCISE 2: the degree bookkeeping -------------------------------------
degrees <- function(s) {
  ma <- poly_mult(c(1, -0.4), c(1, rep(0, s - 1), -0.6))
  sp <- seats_ar_split(1, 1, s)
  N  <- cospoly_from_poly(ma); DT <- cospoly_from_poly(sp$trend); DS <- cospoly_from_poly(sp$seasonal)
  nA <- length(DT) - 1; nC <- length(DS) - 1; nD <- 1
  cat(sprintf("s = %2d :  deg N = %2d   deg DT = %d   deg DS = %2d   deg(DT*DS) = %2d\n",
              s, length(N)-1, length(DT)-1, length(DS)-1, length(cospoly_mult(DT,DS))-1))
  cat(sprintf("          unknowns: A %d + C %2d + D %d = %2d    equations: %2d  -> %s\n\n",
              nA, nC, nD, nA+nC+nD, length(N),
              if (nA+nC+nD == length(N)) "SQUARE" else "MISMATCH"))
}
cat("=== the system is square for any seasonal period ===\n")
degrees(12); degrees(4)

# EXERCISE 3: solve it for AirPassengers ---------------------------------
x   <- AirPassengers
fit <- arima(log(x), c(0,1,1), list(order = c(0,1,1), period = 12))
th  <- unname(-coef(fit)["ma1"]); Th <- unname(-coef(fit)["sma1"])
ma  <- poly_mult(c(1, -th), c(1, rep(0, 11), -Th))
sp  <- seats_ar_split(1, 1, 12)
pf  <- seats_partial_fractions(ma, sp$trend, sp$seasonal)

cat(sprintf("=== AirPassengers: theta = %.4f, Theta = %.4f ===\n", th, Th))
cat("residual of  N = A*DS + C*DT + D*DT*DS :", signif(pf$residual, 3), "\n")
cat("  (machine precision. If yours is not, recount the degrees.)\n\n")
cat("A (trend numerator, cosine coefs)   :", round(pf$A, 5), "\n")
cat("D (irregular, a constant)           :", round(pf$Dc, 5), "\n")
cat("C (seasonal numerator), first 4     :", round(pf$C[1:4], 5), "...\n\n")

# the pieces add back to the whole (away from the poles) -----------------
ww <- seq(0.05, pi - 0.05, length.out = 3000)
gz <- cospoly_eval(pf$N, ww) / (cospoly_eval(pf$DT, ww) * cospoly_eval(pf$DS, ww))
gT <- cospoly_eval(pf$A, ww) / cospoly_eval(pf$DT, ww)
gS <- cospoly_eval(pf$C, ww) / cospoly_eval(pf$DS, ww)
gI <- cospoly_eval(pf$Dc, ww)
cat("max |gT + gS + gI - gz| (away from the poles):",
    signif(max(abs(gT + gS + gI - gz)), 3), "\n\n")

op <- par(mfrow = c(1, 1), mar = c(4, 4, 3, 1))
plot(ww, gz, type = "l", lwd = 2, log = "y", ylim = c(1e-3, 1e3),
     xlab = "omega", ylab = "pseudo-spectrum", main = "f_z split into three pieces")
lines(ww, gT, col = "firebrick", lwd = 2)
lines(ww, gS, col = "steelblue", lwd = 2)
lines(ww, gI, col = "darkgreen", lwd = 2)
abline(v = 2*pi*(1:6)/12, lty = 3, col = "grey60")
legend("topright", c("f_z (total)", "trend", "seasonal", "irregular"),
       col = c("black","firebrick","steelblue","darkgreen"), lwd = 2, bty = "n", cex = 0.8)
par(op)
cat("The trend owns the peak at 0; the seasonal owns the six seasonal peaks;\n")
cat("the irregular is the flat floor. Read the plot and the algebra is obvious.\n\n")

# EXERCISE 4: break the degree bookkeeping on purpose --------------------
cat("=== what if the degrees are wrong? ===\n")
bad <- tryCatch({
  N <- pf$N; DT <- pf$DT; DS <- pf$DS; DTDS <- cospoly_mult(DT, DS)
  nA <- 2; nC <- 12                      # WRONG: deg C should be <= 10, i.e. nC = 11
  g <- seq(0, pi, length.out = 3000)
  X <- cbind(
    sapply(0:(nA-1), function(k) cospoly_eval(replace(numeric(nA), k+1, 1), g) * cospoly_eval(DS, g)),
    sapply(0:(nC-1), function(k) cospoly_eval(replace(numeric(nC), k+1, 1), g) * cospoly_eval(DT, g)),
    cospoly_eval(DTDS, g))
  s <- qr.solve(X, cospoly_eval(N, g))
  max(abs(X %*% s - cospoly_eval(N, g)))
}, error = function(e) conditionMessage(e))
cat("with deg C = 11 instead of 10:", if (is.character(bad)) bad else signif(bad, 3), "\n")
cat("Over-parameterising makes the system singular or the answer non-unique --\n")
cat("the decomposition stops being well defined.\n\n")

# EXERCISE 5: the filters are pole-free and sum to 1 ---------------------
cn <- seats_canonical(pf)
wf <- seq(1e-8, pi - 1e-8, length.out = 4000)
nu <- seats_filters(cn, wf)
cat("=== the WK filters ===\n")
cat("max |nuT + nuS + nuI - 1| :", signif(max(abs(nu$trend + nu$seasonal + nu$irregular - 1)), 3), "\n")
cat("all finite at omega = 0?  ", all(is.finite(c(nu$trend[1], nu$seasonal[1], nu$irregular[1]))), "\n")
cat("  nuT(0) =", round(nu$trend[1], 6), "  even though f_z(0) is INFINITE.\n")
cat("DT cancels between numerator and denominator: nu_T = A*DS/N has no poles.\n")
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/40-04-partial-fractions-in-b-and-f.R")
```

Back to [[40-04-partial-fractions-in-b-and-f]] · index: [[code-index]]
