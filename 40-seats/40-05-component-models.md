---
aliases: [Component models, Component ARIMA, IMA(2,2) trend]
tags: [module-4]
---

# What model does each component follow?

Code: [[code-40-05-component-models|`R/40-05-component-models.R`]]

The decomposition does not just produce three *series* — it produces three *models*. Knowing them is what lets you forecast the components, compute their error variances, and sanity-check an implementation.

## Reading the models off the partial fractions

Each component's spectrum is a ratio, and a ratio of that form **is** an ARIMA spectrum read backwards ([[30-03-spectrum-of-an-arma]]):

$$f_c(\omega) = \frac{\text{numerator}(\omega)}{|\phi_c(e^{-i\omega})|^2} \;\;\Longleftrightarrow\;\; \phi_c(B)\,c_t = \theta_c(B)\,b_t$$

- The **denominator** is already in hand — it is the AR factor assigned to that component.
- The **numerator** is a non-negative cosine polynomial, and any such thing factors as $|\theta_c(e^{-i\omega})|^2$ for some polynomial $\theta_c$. Finding it is **spectral factorisation**.

So: denominator gives the AR side, spectral factorisation of the numerator gives the MA side.

## The airline model's components

| Component | AR side | Numerator degree | Model |
|---|---|---|---|
| trend $T_t$ | $(1-B)^2$ | 2 (after the canonical shift) | **ARIMA(0,2,2)** |
| seasonal $S_t$ | $S(B) = 1+B+\cdots+B^{11}$ | 11 | $S(B)S_t = \theta_S(B)b_t$, $\deg\theta_S = 11$ |
| irregular $I_t$ | — | constant | **white noise** |

Three facts worth holding on to:

**The trend is an IMA(2,2).** Doubly integrated, with a 2-term MA. This is the classic result and it is reassuring — an IMA(2,2) is precisely the reduced form of a *local linear trend* (level and slope both random walks). The decomposition recovers a component whose model is one you would have written down yourself.

**The numerator degrees rise by one at the canonical step.** Before it, $\deg A \le 1$; after subtracting $m_T D_T$ (degree 2) it becomes degree 2. That extra degree is the unit MA root the canonical rule creates ([[40-03-canonical-decomposition]]).

**The irregular really is white noise.** Its spectrum is the constant $D + m_T + m_S$. Not "approximately white" — exactly, by construction.

## Verifying without implementing spectral factorisation

Spectral factorisation is fiddly (Wilson's algorithm, or root-finding on a degree-22 polynomial). You do not need it to *check* the claims, because there is a cheaper equivalent test.

If the canonical trend is an ARIMA(0,2,2), then $(1-B)^2T_t$ is an MA(2), and **an MA(2)'s autocovariances vanish beyond lag 2**. So:

1. Take the canonical trend's spectrum $f_T^{\text{can}}(\omega)$.
2. Multiply by $|1-e^{-i\omega}|^4$ to difference it twice.
3. Inverse-Fourier to autocovariances.
4. Check $\gamma_k \approx 0$ for $k \ge 3$.

The script does this. It is a genuinely decisive test and it needs nothing beyond the numerical Fourier machinery from [[30-06-wiener-kolmogorov]].

Same idea for the seasonal: $S(B)S_t$ should have autocovariances vanishing beyond lag 11.

## Why the component models matter in practice

- **Forecasting components.** X-13 reports forecasts of the trend and of the seasonal factors. Those come from these models, not from anything extra.
- **Error variances.** SEATS reports standard errors for the components. They follow from the component models plus the WK filter.
- **Sanity checks.** A trend that is not an IMA(2,2) when it should be means the partial fractions or the canonical step is wrong.
- **Seasonal factor projections.** The one-year-ahead seasonal factors agencies publish in advance are forecasts from the seasonal component's model.

## A caution about interpretation

The component models are **implied by** the fitted reduced form plus the canonical convention. They were not estimated from data about the components, because no such data exists. If the reduced form is wrong, or the convention is inappropriate, the component models are wrong in ways no diagnostic on $z_t$ can reveal.

This is the standing limitation of model-based adjustment, and it is worth stating plainly rather than burying: **you are reporting the consequences of assumptions, not measurements of unobservable things.**

![[40-05-component-spectra.png]]

*Drawn by [[figure-index#40-05-component-spectra.png|`make-figures.R`]] — code and every other figure in the [[figure-index|figure appendix]].*

The three component spectra that the decomposition produces, with the seasonal frequencies marked. Read it as ownership: the trend takes the low-frequency power, the seasonal takes the spikes at $k/12$, and the irregular takes the flat remainder.

Note the irregular is **exactly flat** — that is white noise, and it is white by construction because the canonical step swept every component's floor into it. Note also that the three curves sum to $f_z$ at every frequency: nothing is created or lost, only assigned.

## Numerically

Each component is itself an ARIMA. SEATS tells you which one.

The trend inherits (1-B)^2 from the differencing and picks up an MA(2) — an ARIMA(0,2,2), the classic local-linear-trend model:

<!-- run -->
```r
sp <- seats_ar_split(1, 1, 12)
cat("trend AR side:", poly_show(sp$trend), " -> d = 2\n")
cat("so the trend is ARIMA(0,2,2): a local linear trend.\n")
cat("seasonal AR side:", poly_show(sp$seas), "\n")
cat("-> the seasonal is ARIMA(0,0,11) driven by S(B), i.e. 11 MA terms.\n")
```
```text
trend AR side: 1 - 2B + B^2  -> d = 2
so the trend is ARIMA(0,2,2): a local linear trend.
seasonal AR side: 1 + B + B^2 + B^3 + B^4 + B^5 + B^6 + B^7 + B^8 + B^9 + B^10 + B^11 
-> the seasonal is ARIMA(0,0,11) driven by S(B), i.e. 11 MA terms.
```
<!-- end -->

## Exercises

*Solutions: [[solutions#40-05-component-models|worked answers]] in the solutions appendix.*

1. Difference the canonical trend twice and confirm its autocovariances vanish beyond lag 2.
2. Do the same for the seasonal with $S(B)$ and lag 11.
3. Confirm the irregular's autocovariances vanish beyond lag 0 — that it is exactly white.
4. Compare the variance of the canonical trend's innovation with $\sigma_a^2$. What fraction of the total innovation variance goes to each component?
5. Without the canonical step, what is the trend's numerator degree? Confirm it is 1 rather than 2.

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** What ARIMA order will the seasonal component have for a *quarterly* airline model? Reason from $S(B)$ before computing.
2. **Break it.** Compute the irregular's autocovariances without the canonical step. Are they still zero beyond lag 0?
3. **Transfer.** Derive the component models for $(0,1,1)(0,1,1)$ with $s=4$ and compare degrees with the monthly case.

## Practice set

*Drills, output-reading and judgement calls. Short answers; the point is fluency and knowing what you are looking at.*

1. **Drill.** Difference the canonical trend twice and report the autocovariances at lags 0..4.
2. **Drill.** Apply $S(B)$ to the seasonal and report autocovariances at lags 10..13.
3. **Read it.** The irregular's autocovariance at lag 1 is $10^{-14}$. What does that confirm?
4. **Judgement.** Someone reports a trend that is ARIMA(0,2,1). What do you suspect they skipped?

## Links

- Prev: [[40-04-partial-fractions-in-b-and-f]] · Next: [[40-06-wk-filters-for-the-airline-model]]
