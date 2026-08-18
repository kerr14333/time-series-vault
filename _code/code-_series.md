---
aliases: [_series.R]
tags: [code, generated]
---

# `R/_series.R`

The standard test series for this vault.

> [!info] Generated file
> Mirror of `R/_series.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> No concept note; this is a shared helper.

```r
# _series.R -- the standard test series for this vault.
#
# AirPassengers is the running example because it is clean and short. It is also
# UNREPRESENTATIVE: no outliers, no calendar effects, no breaks, stable seasonality,
# and comfortably inside the SEATS admissible region. Every method looks good on it.
#
# These are the series that break things. Each earns its place by exposing something
# AirPassengers cannot. See _meta/series-catalogue.md.

suppressMessages(if (requireNamespace("seasonal", quietly = TRUE)) library(seasonal))

vault_series <- function() {
  s <- list(
    airline      = AirPassengers,   # the baseline: clean, stable, well-behaved
    temperature  = nottem,          # near-DETERMINISTIC seasonality; additive, no logs
    co2          = co2,             # very stable seasonal, long (n=468), smooth trend
    accdeaths    = USAccDeaths,     # short (n=72)
    ldeaths      = ldeaths,         # airline model OVER-differences it (theta pinned at 1)
    ukgas        = UKgas,           # QUARTERLY, s=4, and an ARMA(1,1) component
    jj           = JohnsonJohnson   # QUARTERLY, strong growth
  )
  if (requireNamespace("seasonal", quietly = TRUE)) {
    s$unemp <- seasonal::unemp      # real US unemployment: RECESSIONS = turning points
    s$cpi   <- seasonal::cpi        # SEATS rejects the fitted model here (admissibility)
    s$imp   <- seasonal::imp        # Chinese New Year: a MOVING HOLIDAY
    s$iip   <- seasonal::iip        # Indian industrial production: Diwali
  }
  s
}

# What each series is for, in one line -- printed by the catalogue script.
vault_series_notes <- c(
  airline     = "clean baseline; stable seasonality; flatters every method",
  temperature = "near-deterministic seasonality; auto model is (1 0 0)(1 1 1), no log",
  co2         = "very stable seasonal (Theta ~ 0.91); long series",
  accdeaths   = "only 72 observations; how little data can you adjust?",
  ldeaths     = "airline model over-differences; auto model has d=0",
  ukgas       = "quarterly (s=4); everything must generalise beyond 12",
  jj          = "quarterly with strong exponential growth",
  unemp       = "real economic series with business-cycle turning points",
  cpi         = "SEATS replaces the fitted model -- inadmissible decomposition",
  imp         = "Chinese New Year: a moving holiday, not a fixed calendar effect",
  iip         = "Diwali; a second moving-holiday case"
)

# Fit the airline model in Census signs, whatever the series.
airline_fit <- function(x, logs = NULL) {
  if (is.null(logs)) logs <- min(x, na.rm = TRUE) > 0
  y <- if (logs) log(x) else x
  f <- arima(y, c(0, 1, 1), list(order = c(0, 1, 1), period = frequency(x)))
  list(fit = f, logs = logs,
       theta = unname(-coef(f)["ma1"]), Theta = unname(-coef(f)["sma1"]))
}
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/_series.R")
```

Index: [[code-index]]
