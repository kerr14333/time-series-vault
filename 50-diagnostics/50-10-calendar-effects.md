---
aliases: [Calendar effects, Trading day, Moving holidays, genhol]
tags: [module-5, key]
---

# Calendar effects: trading day and moving holidays

Code: `R/50-10-calendar-effects.R`

The most commonly *missed* part of a real adjustment, and a frequent hidden cause of residual seasonality ([[50-02-residual-seasonality]]).

## Why the calendar is not the seasonal

A month's activity depends on things that repeat *near* annually but not exactly:

| Effect | Why it moves |
|---|---|
| **trading day** | months contain different numbers of Mondays, Saturdays, … |
| **leap year** | February has 28 or 29 days |
| **Easter** | moves between late March and late April |
| **Chinese New Year** | moves between late January and late February |
| **Diwali** | moves between mid-October and mid-November |

None of these is seasonal in the $B^{12}$ sense, because they do not repeat on the same month-of-year schedule. A seasonal filter cannot remove them, and if you leave them in they *contaminate* the seasonal estimate — a March Easter and an April Easter push in opposite directions on the March and April factors.

So they are removed **before** the decomposition, as regression terms in regARIMA ([[10-12-estimation]]).

## Built-in regressors

X-13 knows about trading day, leap year and Easter directly:

```r
seas(x, regression.variables = c("td", "easter[1]"))
```

`easter[w]` means "the $w$ days before Easter". Measured:

| Series | Easter[1] | $t$ | $p$ |
|---|---|---|---|
| `AirPassengers` | $+0.0234$ | 2.63 | **0.0086** |
| `unemp` | $+21.2$ | 0.52 | 0.60 |

A real Easter effect in air travel; nothing in unemployment. Left to decide for itself via `regression.aictest`, X-13 keeps `Weekday + Easter` for AirPassengers and `Weekday` only for the trade series.

> [!important] Trading day is usually the bigger effect
> On Chinese imports, adding trading day alone improves AICC from 3129.10 to **3117.60** and drives residual-seasonality QS from 0.05 to 0.00. Analysts reach for holidays and forget trading day; the ordering should usually be the reverse.

## Moving holidays are *not* built-in

This is the trap. `easter[w]` is a genuine X-13 regressor. Chinese New Year and Diwali are **not**:

```text
Regression variable name "cny" not found
```

In the `seasonal` package, `cny`, `diwali` and `easter` are **datasets of dates** — `Date` vectors, 101 and 131 entries respectively — not regressors. You build the regressor yourself:

```r
cny_reg <- genhol(cny, start = -7, end = 0, center = "calendar")
seas(x, xreg = cny_reg, regression.usertype = "holiday",
     regression.variables = "td")
```

`genhol()` spreads the holiday's influence over a window of days and converts it to a monthly proportion.

**`center = "calendar"` is not optional.** It subtracts the monthly means so the regressor is orthogonal to the seasonal pattern — mean $\approx 3\times10^{-18}$, i.e. zero. Uncentred, the mean is $0.0833$ ($=1/12$), the regressor overlaps the seasonal pattern, and the split between them becomes arbitrary.

Measured: skipping `center = "calendar"` changes the published **seasonal factors by up to 6.06%**. Not a technicality.

## Worked: Chinese New Year in Chinese imports

Fitting with trading day plus a CNY window of the 7 days before:

| Term | Estimate | $t$ | $p$ |
|---|---|---|---|
| CNY regressor | $-0.1230$ | **−7.52** | $<0.0001$ |
| Mon…Sat (trading day) | all $\|t\| < 1.3$ | | not significant |

Imports fall about **12%** in the run-up to Chinese New Year — factories close. It is one of the largest single regression effects anywhere in the catalogue, and the AICC improvement is decisive:

```text
td only           AICC 3117.60
td + CNY(-7..0)   AICC 3070.96      <- 46.6 better
```

## Choosing the window

The window length is a modelling choice, and it matters:

| Window | AICC | Coefficient | $t$ |
|---|---|---|---|
| $-3\ldots0$ | **3062.97** | $-0.1265$ | −8.26 |
| $-7\ldots0$ | 3070.96 | $-0.1230$ | −7.52 |
| $-14\ldots0$ | 3079.53 | $-0.1286$ | −6.71 |
| $-21\ldots0$ | 3083.25 | $-0.1605$ | −6.34 |

Shorter is better here — the effect is concentrated in the last few days. Note the coefficient stays around $-0.13$ while the *fit* degrades: a longer window dilutes the same effect over more months rather than finding a different one.

Select by AICC, and sanity-check against what you know about the activity. A holiday that closes factories for a week should not need a three-week window.

## And Diwali, for comparison

The same machinery on Indian industrial production, `iip`:

| Holiday | Series | Effect | $t$ | $p$ |
|---|---|---|---|---|
| Chinese New Year | `imp` | $-0.1230$ | −7.52 | $<0.00001$ |
| Diwali | `iip` | $-0.0333$ | −4.03 | 0.00006 |

Both clearly real; Diwali's is about a quarter the size. Industrial production dips around Diwali, but nothing like the way Chinese factories shut for New Year.

The transferable point: **every economy has its own moving holidays.** Use the one that belongs to the series, not the one you happen to know. A Western analyst reaching for `easter[1]` on Chinese trade data will find nothing and conclude there is no holiday effect, while a $-12\%$ effect sits unmodelled.

## The practical checklist

1. **Test trading day first.** It is usually the largest calendar effect and the easiest to forget.
2. **Add the relevant moving holiday** for the economy the series comes from — Easter in the West, Chinese New Year for East Asian trade and production, Diwali for India, Ramadan elsewhere.
3. **Centre the regressor** (`center = "calendar"`), always.
4. **Choose the window by AICC**, not by tradition.
5. **Re-check residual seasonality afterwards** ([[50-02-residual-seasonality]]). Unmodelled calendar effects are one of its most common causes.
6. **Remember the identity changes.** With regressors active, $\log z = \log(\text{s11}) + \log(\text{s10})$ holds against the *linearized* series, not the raw data ([[40-08-validating-against-x13]]).

## Exercises

*Solutions for this note are not written yet — see [[solutions]] for the modules that are covered.*

1. Reproduce the Easter comparison between `AirPassengers` and `unemp`.
2. Build the CNY regressor and confirm the $-7.52$ $t$-statistic.
3. Sweep the window from $-3$ to $-28$ days. Where is the AICC minimum, and how flat is it?
4. Build the regressor **without** `center = "calendar"` and compare the seasonal factors. How much variation moved between the holiday term and the seasonal?
5. Do the same for Diwali on `iip`. Is the effect as large as CNY's?
6. Adjust `imp` with and without the holiday, and compare the March and February seasonal factors specifically.

## Links

- Prev: [[50-09-x11-vs-seats]] · Module map: [[50-00-diagnostics-map]]
- Related: [[10-12-estimation]], [[50-02-residual-seasonality]], [[50-07-outliers-and-breaks]]
- Data: [[series-catalogue]]
