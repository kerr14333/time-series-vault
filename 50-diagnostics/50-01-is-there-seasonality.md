---
aliases: [Is there seasonality, QS test, Identifiable seasonality]
tags: [module-5]
---

# Is there any seasonality to remove?

Code: [[code-50-01-is-there-seasonality|`R/50-01-is-there-seasonality.R`]]

The first question, and the one most often skipped. **Adjusting a series with no seasonality is worse than doing nothing** — you subtract a spurious pattern estimated from noise, adding variance and inventing movements that were never there.

## The tests

**QS statistic.** A Ljung–Box-type statistic computed on the *seasonal lags only* (12, 24, …) of the differenced series, using positive autocorrelations only. Distributed $\chi^2_2$ under no seasonality, so **above about 9 is significant at 1%**.

X-13 reports it for several series at once:

| Key | On what |
|---|---|
| `qsori` | the original series — is there seasonality to remove? |
| `qssadj` | the **adjusted** series — is any left? ([[50-02-residual-seasonality]]) |
| `qsirr` | the irregular |
| `qsrsd` | the model residuals |

**M7.** X-11's combined test for *identifiable* seasonality, mixing the stable-seasonality F-test with the moving-seasonality F-test. **M7 > 1 means identifiable seasonality is doubtful.** It is the single most useful of the M statistics ([[50-03-m-and-q-statistics]]).

**The spectrum.** Look for peaks at $k/12$. Direct, visual, and hard to fool.

## A negative control

Every diagnostic needs a case where the answer is known to be "no". Monthly **sunspot** numbers have a strong ~11-year cycle and *no annual seasonality* — the Sun does not know about the calendar.

| Series | QS(orig) | M7 | Q | spectrum at $1/12$ |
|---|---|---|---|---|
| `co2` | 495.3 | 0.03 | 0.12 | strong peak |
| `unemp` | 414.9 | 0.17 | 0.18 | strong peak |
| `AirPassengers` | 167.6 | 0.20 | 0.20 | strong peak |
| `ldeaths` | 26.6 | 0.28 | 0.75 | peak |
| **`sunspots`** | **3.0** | **2.47** | **1.46** | **0.36× the median — no peak at all** |

Everything agrees. QS of 3.0 is not close to the 9 threshold; M7 of 2.47 is well over 1; and the power at the annual frequency is *below* the median, i.e. there is less there than at a typical frequency.

> [!important] SEATS refuses outright
> Running `seas(sunspots)` in SEATS mode **fails** — X-13 returns a non-zero exit status. A model-based method has nothing to decompose when there is no seasonal component, and rather than invent one it stops.
>
> X-11 does *not* stop. It happily produces seasonal factors, because it is a fixed recipe with no notion of whether the exercise makes sense. That difference is worth remembering: the model-based method fails loudly, the filter-based one fails silently.

## What to do about a "no"

- **Do not publish an adjusted series.** Publish the original, and say why.
- Consider whether the seasonality is *there but unstable* — a series can have real seasonality that moves too fast to estimate. M7 catches this too, since it penalises moving seasonality relative to stable.
- Consider whether the span is too short. Six years is a common practical minimum; `USAccDeaths` at 72 observations is right at it.
- For a **composite** series (a sum of components), check whether the components are seasonal even if the total is not — offsetting seasonal patterns can cancel.

## The trap in reading X-13's diagnostics

X-13's `udg()` dictionary has 377 entries, many undocumented and easy to misread. On `AirPassengers` the key `peaks.seas` returns `"rsd sa"`, which looks alarming — as though seasonal peaks were found in both the residuals and the adjusted series.

But the two unambiguous checks both say clean:

```text
QS(SA)                              0   (p = 1)
own spectral check, max ratio    1.10   at the seasonal frequencies
```

> [!warning] Do not build a claim on an undocumented diagnostic key
> Prefer the statistics with a stated null distribution (QS) and checks you compute yourself (the spectrum). If a `udg` key seems to contradict them, you have probably misunderstood the key — confirm before reporting it.

![[50-01-seasonal-vs-cyclical.png]]

*Drawn by [[figure-index#50-01-seasonal-vs-cyclical.png|`make-figures.R`]] — code and every other figure in the [[figure-index|figure appendix]].*

**Seasonal is not the same as cyclical**, and this is the picture that settles it.

**Left:** `AirPassengers` has sharp peaks sitting exactly on the seasonal frequencies $k/12$ (red lines). That is seasonality.

**Right:** `sunspots` has an enormous peak — but at about $1/132$ cycles per month, the 11-year solar cycle, and **nothing at $k/12$**. It is strongly cyclical and not seasonal at all.

The practical consequence is in the note: SEATS refuses to adjust `sunspots`, while X-11 will produce seasonal factors for it without complaint. Test before adjusting.

## Numerically

Before adjusting, ask whether there is anything to adjust.

The QS statistic on a seasonal series and on white noise. Above 9 is significant at 1%:

<!-- run -->
```r
set.seed(5)
noise <- ts(rnorm(144), frequency = 12, start = c(1949, 1))
g <- function(m, k) { u <- udg(m); if (k %in% names(u)) as.numeric(u[[k]])[1] else NA }
for (nm in c("AirPassengers", "white noise")) {
  x <- if (nm == "AirPassengers") AirPassengers else noise
  m <- tryCatch(seas(x, x11 = ""), error = function(e) NULL)
  if (!is.null(m)) cat(sprintf("  %-14s QS = %8.2f  %s\n", nm, g(m, "qsori"),
                               if (isTRUE(g(m, "qsori") > 9)) "SEASONAL" else "no evidence"))
}
```
```text
  AirPassengers  QS =   167.65  SEASONAL
  white noise    QS =     0.86  no evidence
```
<!-- end -->

## Exercises

*Solutions: [[solutions#50-01-is-there-seasonality|worked answers]] in the solutions appendix.*

1. Reproduce the table. Confirm `sunspots` fails every test the others pass.
2. Try `seas(sunspots)` in SEATS mode and observe the failure; then in X-11 mode and observe that it produces factors regardless.
3. Plot the sunspot spectrum. Find the 11-year cycle. Confirm nothing at $k/12$.
4. Simulate white noise, "adjust" it, and compare the variance of the adjusted series with the original. Adjusting noise makes it *worse* — by how much?
5. Take a seasonal series and progressively shorten it. At what length do the diagnostics stop detecting the seasonality you know is there?

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** Will a series with a *deterministic* seasonal (a fixed sine plus noise) pass the seasonality tests? Predict, then test.
2. **Break it.** Adjust white noise and compare variances before and after. Then explain why anyone would ever do this by accident.
3. **Transfer.** Test a daily series with a weekly cycle for 'seasonality'. Do the monthly tools apply at all?

## Practice set

*Drills, output-reading and judgement calls. Short answers; the point is fluency and knowing what you are looking at.*

1. **Drill.** Report QS for four catalogue series and mark which exceed 9.
2. **Drill.** Compare the variance of white noise before and after 'adjustment'.
3. **Read it.** QS is 2.4. Seasonal or not?
4. **Judgement.** A stakeholder insists a series is seasonal; every test disagrees. How do you handle it?

## Links

- Next: [[50-02-residual-seasonality]] · Module map: [[50-00-diagnostics-map]]
- Data: [[series-catalogue]]
