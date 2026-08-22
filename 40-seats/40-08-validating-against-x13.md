---
aliases: [Validating against X-13, SEATS validation, X-13 tables]
tags: [module-4]
---

# Validating against X-13

Code: [[code-40-08-validating-against-x13|`R/40-08-validating-against-x13.R`]]

Having built it, prove it. This note is also a general recipe for checking *any* implementation against a reference, including a black-box one.

## Getting comparable output

The trap is comparing two things that were never the same computation. Pin every option:

```r
m <- seas(AirPassengers,
          transform.function  = "log",          # MULTIPLICATIVE. "none" runs additive.
          arima.model         = "(0 1 1)(0 1 1)",# no automatic selection
          regression.aictest  = NULL,            # no trading-day / Easter tests
          outlier             = NULL)            # no outlier detection
```

Every one of those matters:

| Option | If you omit it |
|---|---|
| `transform.function` | X-13 may run **additive** while you run multiplicative — nothing lines up. This cost me an hour. |
| `arima.model` | X-13 picks its own model, so you are comparing different models |
| `regression.aictest` | X-13 may remove trading-day effects you did not remove |
| `outlier` | X-13 may replace observations you did not |

The lesson generalises: **when a comparison fails by a lot, suspect the harness before the algorithm.** An 8.7% discrepancy is almost never a subtle numerical issue; it is a different computation.

## The tables

| Table | Contents | X-11 equivalent |
|---|---|---|
| `s10` | seasonal factors | `d10` |
| `s11` | seasonally adjusted series | `d11` |
| `s12` | trend-cycle | `d12` |
| `s13` | irregular | `d13` |
| `s16` | combined adjustment factors | |

Pull them with `series(m, "s10")`.

## The identity that tells you what was actually decomposed

$$\log z = \log(\text{s11}) + \log(\text{s10})$$

Verified at $6\times10^{-15}$ on `AirPassengers`. Two uses:

1. **Confirms the multiplicative convention** — components multiply, so logs add.
2. **Reveals which series SEATS really decomposed.** With regARIMA preadjustment active, the identity holds against the *linearized* series, not the raw data. If it holds against the raw data, no preadjustment happened; if it does not, something was removed first. That is how you find out what a black box did.

## The results

| Table | Interior mean | Max |
|---|---|---|
| `s10` | 0.000003% | 0.000012% |
| `s11` | 0.000003% | 0.000012% |
| `s12` | 0.000027% | 0.000114% |
| `s13` | 0.000027% | 0.000116% |

Those numbers used to be a thousand times larger — 0.001% on `s11`, 0.012% on `s12`. Two conventions were missing, and both were found by validating the *general* implementation in [[40-11-validating-general-seats]] on a series this one cannot handle. The airline model was too forgiving to show either.

Note that the error is **not concentrated at the ends** — unlike the X-11 build in [[20-05-the-x11-iteration]], where the ends were much worse. Because both implementations extend with forecasts from the same model, both effectively apply the symmetric filter throughout, so the ends are no harder than the middle.

That is itself a finding: the end-of-sample *revision* problem ([[20-07-end-filters]]) is about not yet having the data, not about the filter being unable to cope once you supply forecasts.

## Where the residual comes from

What is left is $3\times10^{-6}$%, about one part in thirty million, and it is numerical:

- **Truncation.** 331 lags leaves weights of order $10^{-7}$ unused.
- **The backcast.** I fit a second ARIMA to the reversed series; X-13 backcasts more carefully.
- **Burman vs extension.** X-13 computes the exact finite-sample answer; the extension approaches it.
- **Parameter estimates.** `arima()` and X-13's optimiser agree to about 4 decimals, not exactly.

Each of those explains $10^{-6}$ or so, which is what remains.

> [!important] What the size of a disagreement tells you
> The rule that got me here: **numerical error and convention error live on different scales, and the scale tells you which one you have.**
>
> A percent is a convention. The 0.88% offset in [[40-07-implementing-seats-in-r]] was a missing normalisation; a further 0.01% was a *second* normalisation nobody had noticed. Both were exact rules stated somewhere in Census output, not noise. Truncation, backcasting and optimiser differences buy you $10^{-4}$ at the very most.
>
> So when a comparison sits at $10^{-2}$ or $10^{-3}$, do not reach for a longer filter. Go looking for a rule. That instinct is what took this note from 0.001% to 0.000003%, and it is more useful than either number.

## A general recipe

1. **Force every option** so both sides compute the same thing.
2. **Check internal identities first** ($T+S+I=z$, filters summing to 1). They need no reference and localise the bug.
3. **Compare interior and ends separately.** Different error patterns mean different causes.
4. **If the discrepancy is constant, it is a convention.** If it grows toward the ends, it is the extension. If it is proportional, it is a scale or transform mismatch.
5. **Only then** consider numerical precision.

Step 4 is the one people skip, and it is the one that identified both of this module's real bugs.

## The result worth ending on

Measured on `AirPassengers`:

| Comparison | Mean absolute difference |
|---|---|
| SEATS vs X-11 — a **method** difference | **0.760%** |
| ours vs X-13 SEATS — an **implementation** difference | **0.000004%** |

Five orders of magnitude. The implementation difference is now down at the level of the forecast extension and the printed precision of X-13's own tables, so the ratio has stopped being a meaningful number — it says only that the two implementations agree and the two methods do not.

> [!important] Perspective
> Which method you publish is a real decision with real consequences for the numbers people read. Whether your code agrees with Census to four decimals or six is not.
>
> Spend your scepticism on the modelling choices — logs or levels, which ARIMA, X-11 or SEATS, how to treat outliers — and not on the last decimal place.

## Exercises

*Solutions: [[solutions#40-08-validating-against-x13|worked answers]] in the solutions appendix.*

1. Reproduce the comparison table.
2. Deliberately set `transform.function = "none"` and observe the failure. How large, and what shape?
3. Turn on `outlier` and re-compare. Which months move, and why?
4. Verify the `s10`/`s11` identity, then re-run with `regression.aictest = "td"` and check whether it still holds against the raw series.
5. Compare SEATS `s11` with your X-11 `d11` from Module 2 on the same series. How large is the method difference relative to the implementation error you just measured? Which dominates?

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** Will turning outliers on change s10 more, or s12 more? Reason about which component absorbs an outlier, then measure.
2. **Break it.** Compare against X-13 with `transform.function = 'none'` and confirm the ~100% discrepancy. What is the lesson about failed comparisons?
3. **Transfer.** Validate a quarterly decomposition against X-13 and report the same four numbers.

## Practice set

*Drills, output-reading and judgement calls. Short answers; the point is fluency and knowing what you are looking at.*

1. **Drill.** Reproduce the four-number comparison table.
2. **Drill.** List every `seas()` argument needed to force a bare airline fit, and say what each one switches off.
3. **Read it.** Agreement is 103%. Bug in the algorithm or the harness?
4. **Judgement.** What agreement would you consider good enough to trust an independent implementation?

## Links

- Prev: [[40-07-implementing-seats-in-r]] · **Module 4 complete** → [[50-00-diagnostics-map]]
- Quiz: [[_quiz/quiz-module-4]]
