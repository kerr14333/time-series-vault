---
aliases: [20-07-end-filters.R]
tags: [code, generated]
---

# `R/20-07-end-filters.R`

End filters: where revisions come from.

> [!info] Generated file
> Mirror of `R/20-07-end-filters.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[20-07-end-filters]]

```r
# 20-07 -- End filters: where revisions come from.
source("R/_setup.R"); source("R/_x11.R")

h13 <- henderson(13); m <- 6

# EXERCISE 1: symmetric vs end weights -------------------------------------
# Simplest surrogate: truncate and renormalise. X-11 actually uses Musgrave's
# minimum-revision weights, which differ in the details but share the shape.
end_filter <- function(w, future_kept) {
  mm <- (length(w) - 1) / 2
  keep <- ((-mm):mm) <= future_kept
  v <- w[keep]; v / sum(v)
}

cat("13-term Henderson, weight on the CURRENT observation:\n")
for (fk in c(6, 3, 1, 0)) {
  v <- end_filter(h13, fk)
  cat(sprintf("  %d future obs available: w(0) = %.3f   (uses %2d obs)\n",
              fk, v[length(v) - fk], length(v)))
}
cat("\nWith no future at all the current month carries", round(end_filter(h13, 0)[7], 3),
    "of the weight,\nversus", round(h13[7], 3), "in the interior. Not a small perturbation.\n\n")

cols <- c("firebrick", "steelblue", "darkgreen")
plot(NA, xlim = c(-6, 6), ylim = c(-0.1, 0.55), xlab = "lag j (negative = past)",
     ylab = "weight", main = "13-term Henderson: symmetric vs end filters")
abline(h = 0, col = "grey70"); abline(v = 0, col = "grey85", lty = 2)
lines(-6:6, h13, type = "b", pch = 19, lwd = 2)
for (i in seq_along(c(0, 2, 4))) {
  fk <- c(0, 2, 4)[i]; v <- end_filter(h13, fk)
  lines(-6:fk, v, type = "b", pch = 17, col = cols[i], lwd = 2)
}
legend("topleft", c("symmetric (interior)", "last point (0 future)",
                    "2 from the end", "4 from the end"),
       col = c("black", cols), lwd = 2, bty = "n", cex = 0.85)

# EXERCISE 4: phase ---------------------------------------------------------
f <- seq(0.001, 0.5, length.out = 500)
asym_phase <- function(w, future_kept, f) {
  mm <- (length(w) - 1) / 2
  j <- (-mm):future_kept
  Arg(sapply(f, function(x) sum(w[((-mm):mm) <= future_kept] / sum(w[((-mm):mm) <= future_kept]) *
                                  exp(-2i * pi * x * j))))
}
cat("max |phase| over frequencies:\n")
cat("  symmetric interior filter:", signif(max(abs(phase(h13, f))), 3), " <- zero\n")
cat("  end filter (0 future)    :", round(max(abs(asym_phase(h13, 0, f))), 3),
    " <- NONZERO: it shifts timing\n\n")

# EXERCISES 2-3: the revision path, measured -------------------------------
z <- AirPassengers
target_i <- 100
target_t <- time(z)[target_i]
cat("tracking the D11 value for", format(target_t), "as data accumulates:\n")
vintages <- seq(target_i, length(z), by = 6)
vals <- sapply(vintages, function(e) {
  zz <- ts(as.numeric(z)[1:e], start = start(z), frequency = 12)
  as.numeric(x11_decompose(zz)$d11)[target_i]
})
names(vals) <- sprintf("+%dm", vintages - target_i)
print(round(vals, 1))
final <- tail(vals, 1)
cat("\nconcurrent estimate:", round(vals[1], 1), "   final:", round(final, 1),
    "   revision:", round(100 * (final - vals[1]) / final, 2), "%\n")

plot(vintages - target_i, vals, type = "b", pch = 19, lwd = 2,
     xlab = "months of data beyond the target", ylab = "D11 estimate",
     main = sprintf("revision path for %s", format(target_t)))
abline(h = final, col = "firebrick", lty = 2)

# Average over many months. Here the SAME method is used for both vintages, so
# this is a legitimate "how much does the estimate move as data arrives" measure.
# It is NOT valid for comparing two different methods -- see the warning in
# R/20-08-x11-arima.R, where that mistake reverses the conclusion.
cat("\nmean |concurrent - final| across the series:\n")
idx <- seq(40, length(z) - 24, by = 6)
revs <- sapply(idx, function(i) {
  zc <- ts(as.numeric(z)[1:i], start = start(z), frequency = 12)
  zf <- ts(as.numeric(z)[1:(i + 24)], start = start(z), frequency = 12)
  c(x11_decompose(zc)$d11[i], x11_decompose(zf)$d11[i])
})
cat("  ", round(mean(abs(revs[1, ] - revs[2, ]) / revs[2, ]) * 100, 3), "%\n")
cat("\nThat is the cost of not having the future. It is irreducible -- the\n")
cat("information genuinely does not exist yet. Forecast extension (20-08)\n")
cat("improves the terms; it does not repeal the problem.\n")
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/20-07-end-filters.R")
```

Back to [[20-07-end-filters]] · index: [[code-index]]
