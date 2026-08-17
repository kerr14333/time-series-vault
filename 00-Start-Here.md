---
aliases: [Start Here, Curriculum, MOC]
tags: [moc]
---

# Seasonal adjustment: X-11 and SEATS

**Goal:** understand X-11 and SEATS well enough to *implement the SEATS decomposition myself*,
from an ARIMA model to trend/seasonal/irregular components, and reproduce what
`seasonal::seas()` prints.

That goal fixes the syllabus. SEATS is a model-based method: it takes a fitted
seasonal ARIMA model, splits that model's **spectrum** into pieces, and turns each piece
back into a **filter**. So the path is forced:

```
ARIMA algebra  →  spectrum of an ARIMA  →  splitting the spectrum  →  filters  →  SEATS
```

X-11 sits alongside as the older, filter-first method. It is easier and it is the
sanity check: whatever SEATS produces should look broadly like what X-11 produces.

---

## The five modules

| # | Module | What you can do at the end |
|---|--------|----------------------------|
| 1 | [[10-00-arima-foundations-map\|ARIMA foundations]] | Read `(0,1,1)(0,1,1)₁₂` and know exactly which polynomial each number lives in; identify a model from ACF/PACF; fit and forecast by hand and in R |
| 2 | [[20-00-x11-map\|X-11]] | Hand-code the X-11 iteration: Henderson trend filter, 3×5 seasonal MA, extreme-value replacement, and see why end-of-sample filters differ |
| 3 | [[30-00-spectral-map\|Spectra and signal extraction]] | Compute the spectrum of an ARIMA model on paper; explain Wiener–Kolmogorov signal extraction |
| 4 | [[40-00-seats-map\|SEATS]] | **Implement the canonical decomposition** and match `seas()` output |
| 5 | [[50-00-diagnostics-map\|Diagnostics and practice]] | Judge whether an adjustment is any good; know when it fails |

---

## How to use this vault

Each note is one idea. Every note that has code names an R script in `R/`.
Run the script *while reading the note* — the notes are written assuming you have the
plot in front of you.

```r
setwd("D:/time-series-vault/time-series-vault")   # the vault root
source("R/10-01-lag-operator.R")
```

Every script `source("R/_setup.R")` first, so the working directory must be the vault root,
not `R/`.

Track where you are in [[_meta/progress]]. Terms you keep forgetting go in
[[_meta/glossary]].

## Prerequisites already assumed

You know what AR and MA mean and you have run something like `arima()`. Everything else
gets built. If a note assumes something it did not define, that is a bug in the note —
flag it and I will fix it.

## The one running example

Every module uses the same series so the modules stack: monthly US airline passengers
(`AirPassengers`, 1949–1960), plus a second real series later. It is the series
Box and Jenkins used, the reason the `(0,1,1)(0,1,1)₁₂` model is called the
**airline model**, and it is short enough to inspect by eye.
