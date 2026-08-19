---
aliases: [50-05-revision-history.R]
tags: [code, generated]
---

# `R/50-05-revision-history.R`

Revision history: concurrent vs final.

> [!info] Generated file
> Mirror of `R/50-05-revision-history.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[50-05-revision-history]]

```r
# 50-05 -- Revision history: concurrent vs final.
source("R/_setup.R"); source("R/_series.R")
suppressMessages(library(seasonal))

# Concurrent estimate: adjust the series truncated at month i, take month i.
# Final estimate: adjust the FULL series, take month i.
# Both from the same method, against ONE shared reference -- see the warning below.
revision_history <- function(x, from = 96, by = 3, mode = c("x11", "seats")) {
  mode <- match.arg(mode)
  fin <- as.numeric(series(if (mode == "x11") seas(x, x11 = "") else seas(x),
                           if (mode == "x11") "d11" else "s11"))
  idx <- seq(from, length(x) - 12, by = by)
  conc <- sapply(idx, function(i) {
    z <- ts(as.numeric(x)[1:i], start = start(x), frequency = 12)
    tryCatch(as.numeric(series(if (mode == "x11") seas(z, x11 = "") else seas(z),
                               if (mode == "x11") "d11" else "s11"))[i],
             error = function(e) NA_real_)
  })
  data.frame(t = as.numeric(time(x))[idx], final = fin[idx], conc = conc,
             rev_pct = 100 * (fin[idx] - conc) / fin[idx])
}

cat("=== revision history: US unemployment ===\n")
h <- revision_history(seasonal::unemp, from = 96, by = 3)
h <- h[!is.na(h$rev_pct), ]
cat(sprintf("  months examined      : %d\n", nrow(h)))
cat(sprintf("  mean revision        : %+.3f%%\n", mean(h$rev_pct)))
cat(sprintf("  mean |revision|      : %.3f%%\n", mean(abs(h$rev_pct))))
cat(sprintf("  5th / 95th pct       : %+.2f%% / %+.2f%%\n",
            quantile(h$rev_pct, .05), quantile(h$rev_pct, .95)))
cat(sprintf("  worst                : %+.2f%%\n", h$rev_pct[which.max(abs(h$rev_pct))]))
cat("\nThe TAIL is what damages credibility, and it is several times the mean.\n")
cat("Publish the distribution, not just the average.\n\n")

op <- par(mfrow = c(2, 1), mar = c(3, 4, 2, 1))
plot(h$t, h$rev_pct, type = "h", lwd = 2, xlab = "", ylab = "revision %",
     main = "US unemployment: concurrent -> final revision")
abline(h = 0)
for (r in list(c(1990.5,1991.25), c(2001.17,2001.92), c(2007.92,2009.5)))
  rect(r[1], -10, r[2], 10, col = rgb(1,0,0,0.12), border = NA)
hist(h$rev_pct, breaks = 25, col = "grey85", main = "distribution of revisions",
     xlab = "revision %")
par(op)
cat("Shaded bands are NBER recessions. The big revisions cluster there -- 50-06.\n\n")

# THE MEASUREMENT WARNING ----------------------------------------------
cat("=== how you define 'revision' decides the answer ===\n")
cat("WRONG: compare each method with ITS OWN later vintage. That scores\n")
cat("       self-consistency -- a stably wrong method looks perfect.\n")
cat("RIGHT: compare every method against ONE shared reference: the full-sample\n")
cat("       estimate, where the month sits in the interior.\n")
cat("On AirPassengers the wrong definition says forecast extension is worthless\n")
cat("(0.3%); the right one says it cuts revisions 41%. See 20-08.\n\n")

# EXERCISE 4: how fast do revisions decay with more data? --------------
cat("=== revision vs how much extra data has arrived ===\n")
x <- seasonal::unemp
target <- 200
fin <- as.numeric(series(seas(x, x11 = ""), "d11"))[target]
for (extra in c(0, 6, 12, 24, 48, 72)) {
  i <- target + extra
  if (i > length(x)) next
  z <- ts(as.numeric(x)[1:i], start = start(x), frequency = 12)
  v <- tryCatch(as.numeric(series(seas(z, x11 = ""), "d11"))[target], error = function(e) NA)
  cat(sprintf("  +%2d months of data : estimate %8.1f   still to revise %+6.3f%%\n",
              extra, v, 100 * (fin - v) / fin))
}
cat("\nMaravall (1996): revision variance falls ~50%% after 1 year, 77%% after 3,\n")
cat("88%% after 5. Revisions decay geometrically; they never stop entirely.\n")
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/50-05-revision-history.R")
```

Back to [[50-05-revision-history]] · index: [[code-index]]
