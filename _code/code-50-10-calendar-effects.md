---
aliases: [50-10-calendar-effects.R]
tags: [code, generated]
---

# `R/50-10-calendar-effects.R`

Trading day, Easter, and moving holidays that are NOT built in.

> [!info] Generated file
> Mirror of `R/50-10-calendar-effects.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[50-10-calendar-effects]]

```r
# 50-10 -- Trading day, Easter, and moving holidays that are NOT built in.
source("R/_setup.R"); source("R/_series.R")
suppressMessages(library(seasonal))

g <- function(u, k) if (k %in% names(u)) suppressWarnings(as.numeric(u[[k]])[1]) else NA_real_
coefs <- function(m, pat) {
  s <- summary(m)$coefficients
  s[grep(pat, rownames(s), ignore.case = TRUE), , drop = FALSE]
}

# EXERCISE 1: a real Easter effect, and a series with none ----------------
cat("=== built-in regressors: td and easter[w] ===\n")
for (nm in c("AirPassengers", "unemp")) {
  x <- if (nm == "AirPassengers") AirPassengers else seasonal::unemp
  m <- tryCatch(seas(x, regression.variables = c("td", "easter[1]"),
                     regression.aictest = NULL, outlier = NULL), error = function(e) NULL)
  if (is.null(m)) next
  r <- coefs(m, "Easter")
  cat(sprintf("  %-14s Easter[1] = %9.4f  t = %6.2f  p = %.4f  %s\n", nm,
              r[1,1], r[1,3], r[1,4], if (r[1,4] < 0.05) "<- REAL" else "(nothing)"))
}
cat("\nAir travel really does move with Easter; unemployment does not.\n\n")

cat("=== what does X-13 KEEP when told to decide for itself? ===\n")
for (nm in c("AirPassengers", "imp", "iip")) {
  x <- switch(nm, AirPassengers = AirPassengers, imp = seasonal::imp, iip = seasonal::iip)
  m <- tryCatch(seas(x), error = function(e) NULL); if (is.null(m)) next
  cal <- grep("Easter|Weekday|Leap|Trading", names(coef(m)), ignore.case = TRUE, value = TRUE)
  cat(sprintf("  %-14s %s\n", nm, if (length(cal)) paste(cal, collapse = ", ") else "none"))
}

# EXERCISE: trading day is usually the bigger prize ----------------------
cat("\n=== trading day alone, on Chinese imports ===\n")
for (v in list(NULL, "td")) {
  m <- tryCatch(seas(seasonal::imp, regression.variables = v,
                     regression.aictest = NULL, outlier = NULL, x11 = ""),
                error = function(e) NULL)
  if (is.null(m)) next
  u <- udg(m)
  cat(sprintf("  %-8s AICC = %9.2f   QS(rsd) = %5.2f\n",
              if (is.null(v)) "none" else v, g(u, "aicc"), g(u, "qsrsd")))
}
cat("Analysts reach for holidays and forget trading day. Usually backwards.\n\n")

# THE TRAP: cny and diwali are NOT X-13 regressors -----------------------
cat("=== the trap: cny[7] is not a thing ===\n")
r <- tryCatch({ seas(seasonal::imp, regression.variables = c("td", "cny[7]")); "worked" },
              error = function(e) conditionMessage(e))
cat("  ", substr(gsub("\n", " | ", r), 1, 110), "\n")
cat("  In the 'seasonal' package cny/diwali/easter are DATASETS OF DATES:\n")
cat("    cny   :", class(cny), length(cny), "dates, first", format(head(cny, 1)), "\n")
cat("    diwali:", class(diwali), length(diwali), "dates, first", format(head(diwali, 1)), "\n")
cat("  You build the regressor yourself with genhol().\n\n")

# EXERCISE 2: build it and fit it ----------------------------------------
cat("=== genhol: Chinese New Year on Chinese imports ===\n")
cny_reg <- genhol(cny, start = -7, end = 0, center = "calendar")
cat(sprintf("  regressor: ts, freq %d, range %.3f to %.3f, mean %.2e\n",
            frequency(cny_reg), min(cny_reg), max(cny_reg), mean(cny_reg)))
cat("  mean is ZERO because center='calendar' removed the monthly means --\n")
cat("  that is what keeps it from fighting the seasonal component.\n\n")

m <- seas(seasonal::imp, xreg = cny_reg, regression.usertype = "holiday",
          regression.variables = "td", regression.aictest = NULL, outlier = NULL)
r <- coefs(m, "^xreg")
cat(sprintf("  CNY effect: %.4f  t = %.2f  p = %.5f\n", r[1,1], r[1,3], r[1,4]))
cat(sprintf("  i.e. imports fall about %.0f%% in the run-up to the holiday\n",
            100 * (1 - exp(r[1,1]))))
td <- coefs(m, "^(Mon|Tue|Wed|Thu|Fri|Sat)")
cat(sprintf("  meanwhile trading day here: max |t| = %.2f (not significant)\n",
            max(abs(td[, 3]))))

cat("\n=== does the holiday term earn its place? ===\n")
for (spec in list(list("td only", NULL), list("td + CNY(-7..0)", cny_reg))) {
  m2 <- tryCatch(
    if (is.null(spec[[2]]))
      seas(seasonal::imp, regression.variables = "td", regression.aictest = NULL,
           outlier = NULL, x11 = "")
    else
      seas(seasonal::imp, xreg = spec[[2]], regression.usertype = "holiday",
           regression.variables = "td", regression.aictest = NULL, outlier = NULL, x11 = ""),
    error = function(e) NULL)
  if (is.null(m2)) next
  u <- udg(m2)
  cat(sprintf("  %-16s AICC = %9.2f\n", spec[[1]], g(u, "aicc")))
}

# EXERCISE 3: the window is a modelling choice ---------------------------
cat("\n=== choosing the window by AICC ===\n")
for (w in c(3, 7, 14, 21, 28)) {
  reg <- genhol(cny, start = -w, end = 0, center = "calendar")
  m3 <- tryCatch(seas(seasonal::imp, xreg = reg, regression.usertype = "holiday",
                      regression.variables = "td", regression.aictest = NULL,
                      outlier = NULL), error = function(e) NULL)
  if (is.null(m3)) { cat(sprintf("  -%2d..0 : failed\n", w)); next }
  rr <- coefs(m3, "^xreg")
  cat(sprintf("  -%2d..0 : AICC = %9.2f   coef = %7.4f   t = %6.2f\n",
              w, g(udg(m3), "aicc"), rr[1,1], rr[1,3]))
}
cat("Shorter wins here: the effect is concentrated in the last few days.\n")
cat("Note the COEFFICIENT barely moves while the FIT degrades -- a longer\n")
cat("window dilutes the same effect over more months.\n")

# EXERCISE 4: what centring is for ---------------------------------------
cat("\n=== what happens without center='calendar' ===\n")
raw_reg <- genhol(cny, start = -7, end = 0, center = "none")
cat(sprintf("  uncentred regressor mean: %.4f  (centred: %.2e)\n",
            mean(raw_reg), mean(cny_reg)))
m_raw <- tryCatch(seas(seasonal::imp, xreg = raw_reg, regression.usertype = "holiday",
                       regression.variables = "td", regression.aictest = NULL,
                       outlier = NULL, x11 = ""), error = function(e) NULL)
m_ctr <- tryCatch(seas(seasonal::imp, xreg = cny_reg, regression.usertype = "holiday",
                       regression.variables = "td", regression.aictest = NULL,
                       outlier = NULL, x11 = ""), error = function(e) NULL)
if (!is.null(m_raw) && !is.null(m_ctr)) {
  a <- as.numeric(series(m_raw, "d10")); b <- as.numeric(series(m_ctr, "d10"))
  cat(sprintf("  seasonal factors differ by up to %.2f%%\n",
              100 * max(abs(a - b) / b)))
  cat("  An uncentred holiday regressor overlaps the seasonal pattern, and the\n")
  cat("  split between them becomes arbitrary.\n")
}

# EXERCISE 5: Diwali -----------------------------------------------------
cat("\n=== Diwali on Indian industrial production ===\n")
dw <- genhol(diwali, start = -7, end = 0, center = "calendar")
m4 <- tryCatch(seas(seasonal::iip, xreg = dw, regression.usertype = "holiday",
                    regression.variables = "td", regression.aictest = NULL,
                    outlier = NULL), error = function(e) NULL)
if (!is.null(m4)) {
  rr <- coefs(m4, "^xreg")
  cat(sprintf("  Diwali effect: %.4f  t = %.2f  p = %.5f\n", rr[1,1], rr[1,3], rr[1,4]))
} else cat("  (could not fit)\n")
cat("\nEvery economy has its own moving holidays. Use the one that belongs to\n")
cat("the series, not the one you happen to know.\n")
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/50-10-calendar-effects.R")
```

Back to [[50-10-calendar-effects]] · index: [[code-index]]
