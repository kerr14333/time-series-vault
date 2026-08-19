---
aliases: [20-03-henderson-filters.R]
tags: [code, generated]
---

# `R/20-03-henderson-filters.R`

Henderson filters: derive, verify, and see what they do NOT do.

> [!info] Generated file
> Mirror of `R/20-03-henderson-filters.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[20-03-henderson-filters]]

```r
# 20-03 -- Henderson filters: derive, verify, and see what they do NOT do.
source("R/_setup.R"); source("R/_x11.R")

# EXERCISE 1: closed form vs the published table ---------------------------
published13 <- c(-0.019, -0.028, 0.000, 0.066, 0.147, 0.214, 0.240,
                  0.214, 0.147, 0.066, 0.000, -0.028, -0.019)
h13 <- henderson(13)
cat("closed form (13-term):\n"); print(round(h13, 3))
cat("published            :\n"); print(published13)
cat("max abs difference   :", signif(max(abs(round(h13, 3) - published13)), 3), "\n")
cat("(the 0.066 vs 0.065 entries are rounding in the published table:",
    "exact value", signif(h13[4], 6), ")\n")
cat("weights sum to 1     :", isTRUE(all.equal(sum(h13), 1)), "\n\n")

for (L in c(9, 13, 23)) cat(sprintf("%2d-term sums to 1: %s\n", L,
                                    isTRUE(all.equal(sum(henderson(L)), 1))))

# EXERCISE 2: it reproduces a cubic exactly --------------------------------
cat("\nCubic-reproduction check (the defining constraint):\n")
tt <- 1:80
for (p in 0:4) {
  y  <- (tt - 40)^p
  sm <- symfilter(y, h13)
  err <- max(abs(sm - y), na.rm = TRUE)
  cat(sprintf("  t^%d : max error %10.3e %s\n", p, err,
              if (err < 1e-8) "<- reproduced exactly" else "<- NOT reproduced"))
}
cat("Degree 0-3 exact, degree 4 not. That is precisely the design constraint.\n")

# EXERCISE 3: gains --------------------------------------------------------
f <- seq(0, 0.5, length.out = 1001)
cols <- c("steelblue", "firebrick", "darkgreen")
plot(NA, xlim = c(0, 0.5), ylim = c(-0.1, 1.05), xlab = "cycles per month",
     ylab = "gain", main = "Henderson gains: longer = smoother = more aggressive")
abline(h = c(0, 1), col = "grey85"); abline(v = SEAS_FREQ, col = "firebrick", lty = 3)
for (i in seq_along(c(9, 13, 23))) lines(f, gain(henderson(c(9, 13, 23)[i]), f), col = cols[i], lwd = 2)
legend("topright", paste(c(9, 13, 23), "term"), col = cols, lwd = 2, bty = "n")

# EXERCISE 4: Henderson does NOT remove seasonality ------------------------
cat("\nGain at the six seasonal frequencies:\n")
tab <- sapply(c(9, 13, 23), function(L) round(gain(henderson(L), SEAS_FREQ), 4))
dimnames(tab) <- list(sprintf("period %4.1f mo (%.4f)", c(12, 6, 4, 3, 2.4, 2), SEAS_FREQ),
                      paste0("H", c(9, 13, 23)))
print(tab)
cat("\nAt the ANNUAL frequency the 13-term gain is", round(gain(henderson(13), 1/12), 3), "--\n")
cat("an annual cycle passes almost untouched. Henderson is a LOW-PASS filter;\n")
cat("removing seasonality is not its job.\n\n")

# what happens if you ignore that and Henderson the raw series
raw_trend <- symfilter(AirPassengers, henderson(13))
proper    <- x11_decompose(AirPassengers)$d12
op <- par(mfrow = c(2, 1), mar = c(3, 4, 2, 1))
plot(AirPassengers, ylab = "", main = "Henderson applied DIRECTLY to raw data")
lines(raw_trend, col = "firebrick", lwd = 2)
plot(AirPassengers, ylab = "", main = "X-11 trend (seasonal removed first)")
lines(proper, col = "darkgreen", lwd = 2)
par(op)
cat("Top panel: the 'trend' still visibly wiggles with the seasons.\n")
cat("This is why the 2x12 MA runs FIRST. Order of operations is structural.\n")

# Filter length selection from the I/C ratio -------------------------------
d <- x11_decompose(AirPassengers, verbose = TRUE)
cat("chosen Henderson length:", d$henderson, "\n")

# ---- quarterly Henderson: a different menu -------------------------------
cat("\n=== quarterly uses 5 or 7 terms, not 9/13/23 ===\n")
for (L in c(5, 7)) {
  w <- henderson(L)
  cat(sprintf("  %d-term: %s   sums to 1: %s\n", L,
              paste(sprintf("%+.4f", w), collapse = " "),
              isTRUE(all.equal(sum(w), 1))))
}
cat("\nselection by I/C ratio:\n")
for (ic in c(0.5, 2.0)) cat(sprintf("  I/C = %.1f  ->  monthly %2d-term, quarterly %d-term\n",
                                    ic, henderson_length(ic, 12), henderson_length(ic, 4)))
cat("\nUsing the MONTHLY table on quarterly data is a silent error: a 13-term\n")
cat("filter spans over three years of quarterly data and simply oversmooths.\n")

# what that mistake costs
d_right <- x11_decompose(UKgas)
d_wrong <- x11_decompose(UKgas, hlen = 13)
cat(sprintf("\nUKgas trend, correct (%d-term) vs forced 13-term:\n", d_right$henderson))
cat(sprintf("  max difference: %.2f%%\n",
            100 * max(abs(d_right$d12 - d_wrong$d12) / d_wrong$d12)))
cat(sprintf("  roughness (sd of first difference): %.5f vs %.5f\n",
            sd(diff(as.numeric(d_right$d12))), sd(diff(as.numeric(d_wrong$d12)))))
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/20-03-henderson-filters.R")
```

Back to [[20-03-henderson-filters]] · index: [[code-index]]
