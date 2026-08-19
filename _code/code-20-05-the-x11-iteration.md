---
aliases: [20-05-the-x11-iteration.R]
tags: [code, generated]
---

# `R/20-05-the-x11-iteration.R`

Build X-11, check it against the real thing, then recover its filter.

> [!info] Generated file
> Mirror of `R/20-05-the-x11-iteration.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[20-05-the-x11-iteration]]

```r
# 20-05 -- Build X-11, check it against the real thing, then recover its filter.
source("R/_setup.R"); source("R/_x11.R")

z <- AirPassengers

# EXERCISE 1: our loop vs the actual X-13 binary ---------------------------
ours <- x11_decompose(z, verbose = TRUE)

if (requireNamespace("seasonal", quietly = TRUE)) {
  # transform.function MUST be "log" -- that is what makes X-13 multiplicative,
  # matching our loop. With "none" it runs ADDITIVE and nothing lines up.
  m <- seasonal::seas(z, x11 = "", transform.function = "log",
                      regression.aictest = NULL, outlier = NULL,
                      arima.model = "(0 1 1)(0 1 1)")
  x13 <- list(d10 = seasonal::series(m, "d10"),
              d11 = seasonal::series(m, "d11"),
              d12 = seasonal::series(m, "d12"))

  cmp <- function(a, b, lab) {
    a <- as.numeric(a); b <- as.numeric(b); n <- length(a); int <- 13:(n - 12)
    pd <- 100 * abs(a - b) / abs(b)
    cat(sprintf("  %-4s interior: mean %5.2f%%  max %5.2f%%   |  ends: max %5.2f%%\n",
                lab, mean(pd[int]), max(pd[int]), max(pd[-int])))
  }
  cat("\nhand-coded X-11 vs X-13:\n")
  cmp(ours$d10, x13$d10, "d10"); cmp(ours$d11, x13$d11, "d11"); cmp(ours$d12, x13$d12, "d12")
  cat("  d11 correlation:", round(cor(as.numeric(ours$d11), as.numeric(x13$d11)), 6), "\n")
  cat("\nErrors are larger at the ENDS. That is not a coding bug -- it is the\n")
  cat("end-filter problem. We fill ends crudely; X-13 uses Musgrave weights and\n")
  cat("forecast extension. See 20-07 and 20-08.\n")

  op <- par(mfrow = c(2, 1), mar = c(3, 4, 2, 1))
  plot(ours$d11, ylab = "D11", main = "seasonally adjusted: ours (black) vs X-13 (red)")
  lines(x13$d11, col = "firebrick", lty = 2, lwd = 2)
  plot(100 * (as.numeric(ours$d11) - as.numeric(x13$d11)) / as.numeric(x13$d11),
       type = "h", ylab = "% diff", xlab = "", main = "difference, by month")
  abline(h = 0)
  par(op)
} else cat("\n[install 'seasonal' + 'x13binary' to compare against real X-13]\n")

# EXERCISE 2-3: recover the composite filter by impulse response -----------
# Multiplicative X-11 on a series that is 1 everywhere except one spike.
n <- 241; mid <- 121
imp <- ts(rep(1, n), frequency = 12); imp[mid] <- 2      # a +1 impulse
resp <- x11_decompose(imp, extreme = FALSE)$d11
wts  <- as.numeric(resp) - 1

cat("\ncomposite SA filter, weights near the centre:\n")
print(round(wts[(mid - 14):(mid + 14)], 4))
cat("sum of weights:", round(sum(wts), 6), " (want 1)\n")
sym_err <- max(abs(wts[mid + 1:60] - wts[mid - 1:60]))
cat("symmetry check, max |w[+j] - w[-j]|:", signif(sym_err, 3), "\n")
cat("note the NEGATIVE weights at +/-12: to strip this January's seasonality,\n")
cat("X-11 leans on neighbouring Januaries with a negative sign.\n")

half <- 72
ww <- wts[(mid - half):(mid + half)]
f <- seq(0, 0.5, length.out = 1001)
op <- par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))
plot((mid - 30):(mid + 30) - mid, wts[(mid - 30):(mid + 30)], type = "h", lwd = 3,
     col = "steelblue", xlab = "lag", ylab = "weight", main = "X-11 composite SA filter")
abline(h = 0, col = "grey70")
plot(f, gain(ww, f), type = "l", lwd = 2, xlab = "cycles per month", ylab = "gain",
     main = "composite gain: six notches")
abline(h = c(0, 1), col = "grey85"); abline(v = SEAS_FREQ, col = "firebrick", lty = 3)
par(op)
cat("\ngain at the seasonal frequencies:", round(gain(ww, SEAS_FREQ), 4), "\n")
cat("gain at frequency 0:", round(gain(ww, 0), 4), "\n")

# EXERCISE 4: how much does a further pass move things? --------------------
cat("\nDoes a further refinement pass matter?\n")
one <- x11_decompose(z, sfilter2 = "3x3")$d11        # cruder final seasonal filter
cat("  3x5 vs 3x3 final seasonal filter: max diff",
    round(100 * max(abs(ours$d11 - one) / one), 3), "%\n")
cat("The answer is stable to the details. That robustness is why a 1965 recipe\n")
cat("is still in production use.\n")

# ---- the whole loop, on quarterly data -----------------------------------
cat("\n=== the same loop runs on quarterly series ===\n")
if (requireNamespace("seasonal", quietly = TRUE)) {
  for (nm in c("UKgas", "JohnsonJohnson")) {
    x <- get(nm)
    ours <- x11_decompose(x, verbose = TRUE)
    m <- seasonal::seas(x, x11 = "", transform.function = "log",
                        regression.aictest = NULL, outlier = NULL)
    cmp2 <- function(a, b, lab) {
      a <- as.numeric(a); b <- as.numeric(b); n <- length(a); int <- 9:(n - 8)
      pd <- 100 * abs(a - b) / abs(b)
      cat(sprintf("    %-4s interior mean %5.2f%%  max %5.2f%%\n", lab, mean(pd[int]), max(pd[int])))
    }
    cat(" ", nm, "(s =", frequency(x), ")\n")
    cmp2(ours$d10, seasonal::series(m, "d10"), "d10")
    cmp2(ours$d11, seasonal::series(m, "d11"), "d11")
    cmp2(ours$d12, seasonal::series(m, "d12"), "d12")
  }
  cat("\nAgreement is as good as the monthly case. x11_decompose() reads the\n")
  cat("period off the series -- nothing about the method is special to 12.\n")
}
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/20-05-the-x11-iteration.R")
```

Back to [[20-05-the-x11-iteration]] · index: [[code-index]]
