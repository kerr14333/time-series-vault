---
aliases: [Quiz Module 5]
tags: [quiz, module-5]
---

# Quiz — Module 5 (Diagnostics and practice)

#flashcards/module-5

The module about whether to believe any of it.

---

## Is there seasonality?

Why is adjusting a non-seasonal series worse than doing nothing? ::: You subtract a spurious pattern estimated from noise. That adds variance and invents month-to-month movements that were never in the data.

What is the QS statistic? ::: A Ljung–Box-type test on the seasonal lags only, using positive autocorrelations. Distributed $\chi^2_2$, so above about **9** is significant at 1%.

What does M7 measure, and what is the threshold? ::: X-11's combined test for *identifiable* seasonality, mixing the stable- and moving-seasonality F-tests. **M7 > 1 means identifiable seasonality is doubtful** — do not adjust.

The negative control, and its numbers ::: Monthly sunspots — an ~11-year cycle, no annual seasonality. QS(orig) = 3.0 (vs 167–495 for real seasonal series), M7 = 2.47, Q = 1.46, and power at the annual frequency 0.36× the median, i.e. *below* typical.

How do the two methods behave on a non-seasonal series? ::: **SEATS fails outright** — X-13 returns a non-zero exit, because there is no seasonal component to decompose. **X-11 produces factors regardless**, being a fixed recipe with no notion of whether the exercise makes sense.

## Residual seasonality

The cardinal sin, and how to test for it ::: Seasonality surviving in the adjusted series. Test with QS on the output (`qssadj`); you want it near zero.

Three places to check, and what each means ::: The **adjusted series** — the adjustment failed. The **irregular** — seasonality is leaking into what should be noise. The **model residuals** — the model itself is misspecified, so fix the ARIMA, not the filter.

Common causes of residual seasonality ::: Seasonality evolving faster than the filter allows; a break in the seasonal pattern; unmodelled trading-day or moving-holiday effects; the wrong ARIMA; too little data; or aggregating separately adjusted components.

Why does a small residual matter so much? ::: A 0.3% leftover is invisible in a plot and completely changes what a single month appears to say — on top of the ~40% of month-to-month movements that are already false signals.

The warning about X-13's diagnostic keys ::: `udg()` has 377 entries, many undocumented. On AirPassengers `peaks.seas` returns `"rsd sa"`, which reads like a warning, while QS(SA) = 0 (p = 1) and a direct spectral check maxes at 1.10× the median. Prefer statistics with a stated null distribution and checks you compute yourself.

## M and Q

What is Q? ::: A weighted average of the eleven M statistics, on the same "below 1 is acceptable" scale. Q-M2 excludes M2, which is unreliable on short series.

Five limitations of M and Q ::: The thresholds are conventions with no null distribution; the weights in Q are arbitrary and never re-derived; they are X-11-only so cannot compare methods; they say nothing about the ends; and a good Q is compatible with residual seasonality.

The healthy use of Q ::: As a **screen across many series** — flag the worst few percent for human attention — not as a certificate for any single series.

Which catalogue series has the highest M7 among the genuine ones? ::: `cpi`, at 0.66 — the same series that is inadmissible for SEATS. Independent diagnostics converging on the same awkward series suggests they measure something real.

## Sliding spans

What do sliding spans test? ::: Stability — adjust several overlapping spans independently and compare the seasonal factors for months covered by more than one. It asks whether the answer survives moving the *window*.

The thresholds ::: Flag a month if the seasonal factors differ by more than **3%** across spans; the adjustment is unstable if more than **25%** of months are flagged (40% for month-to-month changes).

What do sliding spans catch that nothing else does? ::: Instability. QS asks whether seasonality remains; M and Q are computed from a single adjustment and cannot see instability by construction; revision history perturbs the *end*, not the window.

The awkward limitation ::: They need about 11 years of data. Short series cannot be assessed — and short series are exactly the ones most likely to be unstable.

Sliding spans vs revision history ::: Sliding spans move the whole window and ask "is this robust?". Revision history adds data at the end and asks "how much will this change?". Clean spans with large revisions means *stable but provisional*, which is normal.

## Revisions

Define concurrent and final ::: **Concurrent** is the adjustment for month $t$ computed when $t$ was the last observation — what gets published. **Final** is computed from the full sample with $t$ in the interior — what turns out to be right.

The measurement trap ::: Comparing a method against its *own* later vintage measures self-consistency, so a stably wrong method scores perfectly. Measure every method against one shared reference — the full-sample estimate. On AirPassengers the wrong definition says forecast extension is worthless (0.3%); the right one says 41%.

How fast do revisions decay? ::: Revision variance falls about 50% after 1 year, 77% after 3, 88% after 5 (Maravall 1996). Geometrically, and never entirely.

What are projected factors, and what do they trade? ::: Computing factors once a year and applying them for the following twelve months. The published series does not revise within the year — the revision is deferred to the annual reanalysis, not eliminated. A stream of small revisions is traded for one large annual one.

What should be published about revisions but usually is not? ::: The distribution rather than the mean (the tails do the damage), and revisions **conditioned on where in the cycle they occurred**.

## Turning points

The headline measurement ::: On US unemployment 1990–2016, mean absolute revision is **1.11%** within a year of a recession versus **0.62%** elsewhere — a ratio of **1.79×**. For 2008–2010 specifically it is 1.60% versus 0.63%, a ratio of **2.53×**.

What happens in the tail? ::: **64%** of the worst 10% of revisions fall near a recession, against a 35% baseline — a 1.81× enrichment. Nine of the fifteen worst-revised months in twenty-six years sit in 2007–2010.

The three mechanisms ::: **Forecast contamination** (the model extrapolates the old regime, so the error is systematic not random); **asymmetric end-filter weights** (structurally different filter, nonzero phase); and **the revision path** (later vintages converge to the symmetric-filter value, so the concurrent estimate was biased, not merely noisy).

Why can't a better model fix it? ::: A better model forecasts the *old regime* more precisely. The information about the turn does not exist yet, so no estimator can recover it.

What is the practical advice for users? ::: Stop reading single months. Three-month averages or year-on-year comparisons are far more robust — roughly 40% of month-to-month movements in an adjusted series can be false signals.

The methodological warning from measuring this ::: Using trend curvature as a proxy for "near a turning point" gave 1.42× and correlation 0.083 — the correlation essentially nil. Using actual NBER recession dates gave 1.79× (2.53× for 2008–2010). **A weak result can mean the effect is absent, or that your operationalisation is bad.**

## Outliers and COVID

The three outlier types ::: **AO** a single point; **LS** a permanent step; **TC** a spike decaying geometrically. Getting the type right matters as much as the location.

What goes wrong if you model an LS as an AO? ::: The step stays in the data, distorting the trend and inflating residual variance from then on. The seasonal factors inherit the error.

The dangerous detection case ::: A level shift in the final months is indistinguishable from the start of a recession. Treating a real downturn as an LS **removes the recession from the trend**, and no diagnostic can tell them apart — only later data can.

Why does a 2020 shock corrupt years either side? ::: Seasonal factors are estimated across years within a calendar month, so an extreme March 2020 contaminates the March factor for several years; ARIMA parameters are estimated from the whole span; and the symmetric trend filter reaches backwards as well as forwards.

The three COVID strategies ::: Additive outliers for the affected months; level shifts or ramps where the change persisted; or excluding the period from the estimation span while still publishing adjusted values for it. Most agencies mixed these and documented prominently.

The honest limit COVID exposed ::: Whether March 2020 was an AO, an LS, or a regime change could not be determined from the data at the time — it depends on what happens next. Every diagnostic in this module answers a question about the past.

## Choosing a method

How much do X-11 and SEATS differ in practice? ::: Usually very little — correlations above 0.99, and `co2` differs by 0.018%. But `UKgas` differs by 4.2% on average and `imp` by 27% in one month. When they disagree, they disagree a lot.

What predicts the disagreement? ::: **Low $\Theta$.** The three worst (`UKgas` 0.235, `JohnsonJohnson` 0.315, `imp` 0.498) all have volatile seasonality; the best (`co2` 0.912, `iip` 0.932) are stable. SEATS adapts its notch width to $\Theta$; X-11 picks from a fixed menu.

When to prefer each ::: SEATS when the model fits well, you want series-specific filters, and the decomposition is admissible. X-11 when the model fits poorly or is unstable, you want uniform treatment across many series, or you need M/Q diagnostics.

The one-line summary of the trade-off ::: SEATS is better when its model is right; X-11 degrades more gracefully when it is not.

Method versus implementation, in proportion ::: SEATS vs X-11 differ by 0.760% on AirPassengers; our from-scratch build differs from X-13 by 0.001%. A factor of ~660. The method choice dominates implementation precision by three orders of magnitude.

The institutional rule that matters most ::: Do not switch methods between vintages. A series adjusted by SEATS one month and X-11 the next has revisions that mean nothing.
