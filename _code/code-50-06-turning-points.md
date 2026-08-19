---
aliases: [50-06-turning-points.R]
tags: [code, generated]
---

# `R/50-06-turning-points.R`

Adjustment is least reliable exactly when it matters most.

> [!info] Generated file
> Mirror of `R/50-06-turning-points.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[50-06-turning-points]]

```r
# 50-06 -- Adjustment is least reliable exactly when it matters most.
source("R/_setup.R"); source("R/_series.R")
suppressMessages(library(seasonal))

x <- seasonal::unemp
cat("US unemployment,", paste(start(x), collapse="."), "->", paste(end(x), collapse="."),
    "  n =", length(x), "\n\n")

# Concurrent vs full-sample estimate, every 2 months to keep the run short.
final <- as.numeric(series(seas(x, x11 = ""), "d11"))
idx <- seq(96, length(x) - 12, by = 2)
conc <- sapply(idx, function(i) {
  z <- ts(as.numeric(x)[1:i], start = start(x), frequency = 12)
  tryCatch(as.numeric(series(seas(z, x11 = ""), "d11"))[i], error = function(e) NA_real_)
})
tt  <- as.numeric(time(x))[idx]
rev <- 100 * (final[idx] - conc) / final[idx]
ok  <- !is.na(rev)

# NBER recessions in this span
recs <- list(c(1990.5, 1991.25), c(2001.17, 2001.92), c(2007.92, 2009.5))
near <- Reduce(`|`, lapply(recs, function(r) tt >= r[1] - 1 & tt <= r[2] + 1))

cat("=== revisions in vs out of recessions ===\n")
cat(sprintf("  within a year of a recession : %.3f%%  (n = %d)\n",
            mean(abs(rev[ok & near])), sum(ok & near)))
cat(sprintf("  everywhere else              : %.3f%%  (n = %d)\n",
            mean(abs(rev[ok & !near])), sum(ok & !near)))
cat(sprintf("  RATIO                        : %.2fx\n",
            mean(abs(rev[ok & near])) / mean(abs(rev[ok & !near]))))

gr <- ok & tt >= 2008 & tt < 2011
cat(sprintf("\n  2008-2010 only               : %.3f%%\n", mean(abs(rev[gr]))))
cat(sprintf("  all other months             : %.3f%%\n", mean(abs(rev[ok & !gr]))))
cat(sprintf("  RATIO                        : %.2fx\n",
            mean(abs(rev[gr])) / mean(abs(rev[ok & !gr]))))

cat("\n=== the tail ===\n")
q <- quantile(abs(rev[ok]), 0.90)
big <- ok & abs(rev) > q
cat(sprintf("  worst 10%% of revisions near a recession : %.0f%%\n", 100*mean(near[big])))
cat(sprintf("  baseline share of months near a recession: %.0f%%\n", 100*mean(near[ok])))
cat(sprintf("  enrichment                               : %.2fx\n",
            mean(near[big]) / mean(near[ok])))

plot(tt, abs(rev), type = "h", lwd = 2, xlab = "", ylab = "|revision| %",
     main = "US unemployment: revisions cluster at turning points")
for (r in recs) rect(r[1], -1, r[2], 10, col = rgb(1,0,0,0.15), border = NA)
lines(tt, abs(rev), type = "h", lwd = 2)

# EXERCISE 2: the SIGN -- is the concurrent estimate biased at a turn? --
cat("\n=== mechanism 1, visible: the SIGN of the revision during 2008-09 ===\n")
w <- ok & tt >= 2008 & tt <= 2010
cat(sprintf("  mean SIGNED revision 2008-2010 : %+.3f%%\n", mean(rev[w])))
cat(sprintf("  mean SIGNED revision elsewhere : %+.3f%%\n", mean(rev[ok & !w])))
cat("A systematic sign means the concurrent estimate is BIASED, not just noisy --\n")
cat("the forecast extrapolated the old regime. That is forecast contamination.\n")

# EXERCISE 4: why a naive proxy fails ----------------------------------
cat("\n=== a methodological warning ===\n")
trend <- as.numeric(series(seas(x, x11 = ""), "d12"))
curv  <- c(NA, NA, abs(diff(diff(trend))))[idx]
good  <- ok & !is.na(curv)
hi    <- good & curv > quantile(curv[good], 0.75)
cat(sprintf("  curvature-based split : %.2fx   correlation %.3f\n",
            mean(abs(rev[hi])) / mean(abs(rev[good & !hi])),
            cor(abs(rev[good]), curv[good])))
cat(sprintf("  recession-date split  : %.2fx\n",
            mean(abs(rev[ok & near])) / mean(abs(rev[ok & !near]))))
cat("\nSame data, different definition of 'turning point', very different answer.\n")
cat("Trend curvature is dominated by small wiggles, so the proxy is swamped.\n")
cat("A weak result can mean the effect is absent -- or that your variable does\n")
cat("not measure what you meant. Check before concluding 'no effect'.\n")
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/50-06-turning-points.R")
```

Back to [[50-06-turning-points]] · index: [[code-index]]
