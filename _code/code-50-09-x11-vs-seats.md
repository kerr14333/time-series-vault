---
aliases: [50-09-x11-vs-seats.R]
tags: [code, generated]
---

# `R/50-09-x11-vs-seats.R`

Which method do you publish?

> [!info] Generated file
> Mirror of `R/50-09-x11-vs-seats.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[50-09-x11-vs-seats]]

```r
# 50-09 -- Which method do you publish?
source("R/_setup.R"); source("R/_series.R"); source("R/_x11.R")
suppressMessages(library(seasonal))
S <- vault_series()

# EXERCISE 1: how different are the two adjustments? -------------------
cat("=== X-11 (d11) vs SEATS (s11), every catalogue series ===\n")
cat(sprintf("%-12s %7s %10s %9s %9s\n", "series", "Theta", "mean abs%", "max%", "corr"))
res <- list()
for (nm in names(S)) {
  r <- tryCatch({
    a <- as.numeric(series(seas(S[[nm]], x11 = ""), "d11"))
    b <- as.numeric(series(seas(S[[nm]]), "s11"))
    f <- airline_fit(S[[nm]])
    pd <- 100 * abs(a - b) / abs(b)
    c(f$Theta, mean(pd), max(pd), cor(a, b))
  }, error = function(e) rep(NA_real_, 4))
  res[[nm]] <- r
  cat(sprintf("%-12s %7.3f %10.3f %9.3f %9.5f\n", nm, r[1], r[2], r[3], r[4]))
}

# EXERCISE 1 continued: is the disagreement predicted by Theta? --------
M <- do.call(rbind, res)
ok <- complete.cases(M)
cat(sprintf("\ncorrelation between Theta and mean disagreement: %.3f\n",
            cor(M[ok,1], M[ok,2])))
plot(M[ok,1], M[ok,2], pch = 19, xlab = expression(Theta),
     ylab = "mean |X-11 - SEATS| %", main = "low Theta => the methods disagree")
text(M[ok,1], M[ok,2], rownames(M)[ok], pos = 4, cex = 0.7)
abline(lm(M[ok,2] ~ M[ok,1]), col = "firebrick", lty = 2)
cat("Low Theta = volatile seasonality. SEATS widens its notches to match;\n")
cat("X-11 can only step to the next filter length. So they part company.\n")
cat("You can predict from ONE coefficient whether the method choice matters.\n\n")

# EXERCISE 3: is the difference visible, or only statistical? ----------
x <- UKgas
a <- series(seas(x, x11 = ""), "d11"); b <- series(seas(x), "s11")
op <- par(mfrow = c(2, 1), mar = c(3, 4, 2, 1))
plot(a, ylab = "adjusted", main = "UKgas: X-11 (black) vs SEATS (red)")
lines(b, col = "firebrick", lty = 2, lwd = 2)
plot(100*(as.numeric(a) - as.numeric(b))/as.numeric(b), type = "h",
     ylab = "% diff", xlab = "", main = "difference"); abline(h = 0)
par(op)

# EXERCISE 4: which revises less at the end? --------------------------
cat("=== which method revises less? (unemp, every 6 months) ===\n")
z <- seasonal::unemp
fin_x <- as.numeric(series(seas(z, x11 = ""), "d11"))
fin_s <- as.numeric(series(seas(z), "s11"))
idx <- seq(120, length(z) - 12, by = 6)
rev_of <- function(mode) {
  fin <- if (mode == "x11") fin_x else fin_s
  v <- sapply(idx, function(i) {
    y <- ts(as.numeric(z)[1:i], start = start(z), frequency = 12)
    tryCatch(as.numeric(series(if (mode == "x11") seas(y, x11 = "") else seas(y),
                               if (mode == "x11") "d11" else "s11"))[i],
             error = function(e) NA_real_)
  })
  mean(abs(100 * (fin[idx] - v) / fin[idx]), na.rm = TRUE)
}
cat(sprintf("  X-11  mean |revision| : %.3f%%\n", rev_of("x11")))
cat(sprintf("  SEATS mean |revision| : %.3f%%\n", rev_of("seats")))

cat("\n=== keeping it in proportion ===\n")
cat("From 40-08, on AirPassengers:\n")
cat("  SEATS vs X-11   (METHOD)         0.760%\n")
cat("  ours vs X-13    (IMPLEMENTATION) 0.001%\n")
cat("  ratio ~660x\n")
cat("\nThe method choice dominates implementation precision by three orders of\n")
cat("magnitude. Spend your scepticism on the modelling decisions.\n")
cat("\nAnd whichever you choose: DO NOT SWITCH between vintages. A series\n")
cat("adjusted by SEATS this month and X-11 next month has revisions that mean\n")
cat("nothing at all.\n")
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/50-09-x11-vs-seats.R")
```

Back to [[50-09-x11-vs-seats]] · index: [[code-index]]
