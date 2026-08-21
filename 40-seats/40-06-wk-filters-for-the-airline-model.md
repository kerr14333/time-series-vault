---
aliases: [WK filters for the airline model, SEATS filters, Component gains]
tags: [module-4, key]
---

# The WK filters for the airline model

Code: [[code-40-06-wk-filters-for-the-airline-model|`R/40-06-wk-filters-for-the-airline-model.R`]]

Where all of Module 3 becomes a picture you can look at.

## The three filters

From [[40-04-partial-fractions-in-b-and-f]], with the canonical numerators of [[40-03-canonical-decomposition]]:

$$\nu_T = \frac{(A - m_TD_T)\,D_S}{N},\qquad
\nu_S = \frac{(C - m_SD_S)\,D_T}{N},\qquad
\nu_I = \frac{(D + m_T + m_S)\,D_TD_S}{N}$$

All three are ratios of cosine polynomials with **no poles** — $N$ has no zeros on the unit circle whenever the model is invertible. So they are ordinary smooth functions of frequency, despite $f_z$ itself being infinite at seven of them.

## What the gains look like

Measured on `AirPassengers` ($\theta = 0.4018$, $\Theta = 0.5569$):

| Frequency | $\nu_T$ | $\nu_S$ | $\nu_I$ |
|---|---|---|---|
| $\omega = 0$ (trend) | **1.00000** | 0.00000 | 0.00000 |
| $\omega = 2\pi/12$ (annual) | 0.00005 | **0.99993** | 0.00002 |
| $\omega = \pi$ (Nyquist) | 0.00000 | **1.00000** | 0.00000 |

Read it as ownership. At frequency 0 the trend takes everything; at each seasonal frequency the seasonal takes everything; in between they share according to the model. Exactly the Wiener–Kolmogorov principle of [[30-06-wiener-kolmogorov]] — *keep the share of the power that is yours* — with the shares turning out to be 0 or 1 at the poles because those frequencies are unambiguously owned.

And $\nu_T + \nu_S + \nu_I = 1$ at every frequency, verified to $\sim10^{-12}$.

> [!important] Note $\nu_S(\pi) = 1$
> $\omega = \pi$ *is* a seasonal frequency for monthly data — it is $k=6$, the two-month cycle, the last harmonic. So the seasonal component legitimately claims all the power at the highest observable frequency. First-time implementers often think this is a bug. It is not.

![[40-06-seats-filters.png]]

*Drawn by [[figure-index#40-06-seats-filters.png|`make-figures.R`]] — code and every other figure in the [[figure-index|figure appendix]].*

Left: the three gains, summing to 1 at every frequency. Right: the seasonal filter alone as $\Theta$ varies — this is the adaptivity X-11 cannot offer.

## The filter weights

Inverting the gains gives the time-domain weights, which are what actually get applied:

- **Symmetric**, hence zero phase — no turning points move.
- **Sum to $\nu(0)$**: 1 for the trend, 0 for the seasonal and irregular. That is a sharp implementation check, and getting it wrong produces a constant level offset (see [[40-07-implementing-seats-in-r]]).
- **Slowly decaying.** The trend weights fall off smoothly; the seasonal weights have a spike every 12 lags with a slowly shrinking envelope.

That last point has teeth. The seasonal weights decay at roughly $\Theta$ **per year**, so for $\Theta = 0.557$ you need about **28 years** of weights before they are negligible, and for $\Theta = 0.9$ over fifty. This is precisely the "narrow notches require long filters" trade-off of [[30-06-wiener-kolmogorov]], showing up as an array length.

## Comparing with X-11

Both methods reduce to a single symmetric linear filter, so they can be overlaid directly — the payoff promised in [[30-05-filters-in-the-frequency-domain]].

| | X-11 | SEATS |
|---|---|---|
| notch shape | fixed by the chosen MA lengths | derived from $\theta,\Theta$ |
| notch width | same for every series | adapts to how fast the seasonality evolves |
| adaptivity | filter length chosen from MSR/IC ratios | continuous in the parameters |
| behaviour at $\omega=0$ | gain 1 | gain 1 |

The important difference is not sharpness but **adaptivity**: SEATS narrows the notches for a series with stable seasonality and widens them for a volatile one, automatically, because $\Theta$ says which it is. X-11 picks from a small menu.

Whether the model-derived notch is *better* is an empirical question, and [[50-09-x11-vs-seats]] takes it up. On a series that fits the model well, SEATS should win; on one that does not, the fixed filters are more robust.

## Exercises

1. Plot all three gains on one axis. Mark the seasonal frequencies. Confirm they sum to 1.
2. Reproduce the ownership table above.
3. Vary $\Theta$ from 0.3 to 0.95 and watch the seasonal notches narrow. Overlay X-11's fixed composite gain from [[20-05-the-x11-iteration]] — where does each method concede more?
4. Plot the trend and seasonal weights. Find the 12-lag spikes in the seasonal weights and measure the envelope's decay rate. Is it $\Theta$ per year?
5. Compute how many lags are needed for the weights to fall below $10^{-7}$, for $\Theta = 0.3$, $0.6$, $0.9$. Relate to the run time of your implementation.
6. Confirm $\nu_S(\pi) = 1$ and explain why in one sentence.

## Links

- Prev: [[40-05-component-models]] · Next: [[40-07-implementing-seats-in-r]]
- Theory: [[30-06-wiener-kolmogorov]] · Comparison: [[50-09-x11-vs-seats]]
