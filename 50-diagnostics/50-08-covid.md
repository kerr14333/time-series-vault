---
aliases: [COVID, Pandemic adjustment, Extreme values 2020]
tags: [module-5]
---

# COVID-19: the canonical modern breakdown

Code: [[code-50-08-covid|`R/50-08-covid.R`]]

Every assumption in this vault broke at once in March 2020. Worth studying because it shows what the machinery is actually resting on.

## What broke, assumption by assumption

| Assumption | What happened |
|---|---|
| the trend evolves smoothly | it fell off a cliff, then partly rebounded |
| shocks are small relative to the seasonal | shocks were **many times** the seasonal amplitude |
| outliers are isolated | months of consecutive extreme values |
| the seasonal pattern persists | some seasonal patterns genuinely stopped (travel, hospitality) |
| the model forecasts the near future | no model fitted to pre-2020 data could forecast 2020 |

The last one is the killer, because forecast extension ([[20-08-x11-arima]]) is how the end of the sample gets adjusted at all.

## Why it damages more than the affected months

This is the part people miss. A 2020 shock does not only corrupt 2020:

1. **Seasonal factors are estimated across years within a calendar month** ([[20-04-seasonal-moving-averages]]). An extreme April 2020 contaminates the April factor for **several years either side**.
2. **The ARIMA parameters are estimated from the whole span.** Enormous 2020 residuals inflate $\sigma_a^2$ and drag $\theta$ and $\Theta$, changing the filters applied to *every* observation.
3. **The trend filter is symmetric**, so a 2020 shock leaks into the trend estimate for 2019 as well as 2021.

So an untreated pandemic corrupts a decade, not a year.

## What agencies actually did

Broadly three strategies, in increasing order of intervention:

**1. Additive outliers for the affected months.** Simple, and it works when the shock is a spike. Treats the observations as uninformative about the seasonal pattern while keeping them in the published series ([[20-06-extreme-values]]).

**2. Level shifts and ramps** where the change was persistent. Necessary, and contentious — an LS asserts the series will not return to its old path, which was a forecast, not an observation, at the time it had to be decided.

**3. Excluding 2020 from the estimation span** while still publishing adjusted values for it. The seasonal factors come from pre- and post-pandemic data; 2020 gets factors but does not influence them. Cleanest in principle, and it requires deciding when "2020" ended.

Most agencies used a mixture, documented it prominently, and warned users that adjusted series through the period carry unusual uncertainty.

## The judgement that could not be avoided

> [!important] No diagnostic could make this call
> Whether March 2020 was an AO, an LS, or the start of a new regime **could not be determined from the data at the time**. The distinction depends on what happens next, and next had not happened.
>
> Every diagnostic in this module — QS, M7, sliding spans, revision history — answers a question about the *past*. None answers "is this the start of something".

That is the honest limit of the whole subject. Seasonal adjustment is an extrapolation, and at a genuine regime change the extrapolation is wrong in a way no amount of diagnostics can rescue. COVID made that visible at a scale nobody could ignore, but it is the same mechanism as an ordinary business-cycle turning point ([[50-06-turning-points]]) — just enormously larger.

## The transferable lessons

1. **Say what you did.** The agencies that came out best documented their treatment prominently and early.
2. **Publish the unadjusted series alongside.** When the adjustment is unreliable, users need the raw data.
3. **Do not let one episode set the parameters forever.** Fixing the estimation span, or the outlier set, and revisiting it annually beats re-deciding every month.
4. **Widen the uncertainty you report**, rather than reporting the usual number with the usual confidence.
5. **The problem is not unique to COVID.** Any regime change does this. COVID was just large enough that everyone had to have a policy.

## Exercises

*Solutions: [[solutions#50-08-covid|worked answers]] in the solutions appendix.*

1. Simulate a COVID-like shock: a monthly series with a −40% drop in one month and a partial recovery over six. Adjust it untreated and inspect the seasonal factors for the *other* years.
2. Now treat the shock as AOs. How much of the contamination goes away?
3. Try an LS instead. Compare the trend.
4. Exclude the shock period from the estimation span but keep publishing it. Compare all three strategies.
5. Quantify the reach: how many years either side of the shock have seasonal factors that moved by more than 1%?

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** How many years either side of a 2020 shock will seasonal factors move by more than 1%? Guess, then measure.
2. **Break it.** Treat the shock with a single AO when it actually lasted six months. How much contamination survives?
3. Argue both sides of the LS-versus-AO choice for 2020, and say what evidence would settle it.

## Practice set

*Drills, output-reading and judgement calls. Short answers; the point is fluency and knowing what you are looking at.*

1. **Drill.** Simulate a 40% drop with partial recovery and report the max seasonal-factor change, untreated.
2. **Read it.** Seasonal factors for 2017 changed after adding 2020 data. How is that possible?
3. **Judgement.** Write the two-sentence footnote you would publish alongside 2020 figures.

## Links

- Prev: [[50-07-outliers-and-breaks]] · Next: [[50-09-x11-vs-seats]]
- Mechanism: [[50-06-turning-points]], [[20-04-seasonal-moving-averages]]
