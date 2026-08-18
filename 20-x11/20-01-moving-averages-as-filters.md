---
aliases: [Moving averages as filters, Linear filters, Gain function]
tags: [module-2]
---

# Moving averages are filters

Code: `R/20-01-moving-averages-as-filters.R`

## The reframe

A moving average is usually taught as "smoothing". That framing is too weak to get you through X-11. The useful framing is:

> A moving average is a **linear filter**: it multiplies each frequency in the data by a fixed amount. Choosing a moving average *is* choosing which frequencies to keep and which to destroy.

Once you hold that, X-11 stops being a pile of arbitrary recipes and becomes a sequence of deliberate frequency surgeries.

## Notation

A symmetric filter of length $2m+1$:

$$\hat{x}_t = \sum_{j=-m}^{m} w_j\, x_{t-j}, \qquad \nu(B) = \sum_{j=-m}^{m} w_j B^{j}$$

Note $j$ runs negative too, so $\nu$ contains $B^{-1} = F$, the forward operator. **The filter uses the future.** That single fact generates every revision problem in this subject — see [[20-07-end-filters]].

## Gain and phase

Substitute $B = e^{-i\omega}$ (the move that gets fully justified in [[30-05-filters-in-the-frequency-domain]]; take it on trust for now):

$$\nu(e^{-i\omega}) = \sum_j w_j e^{-i\omega j} = G(\omega)\,e^{-i\varphi(\omega)}$$

- **Gain** $G(\omega) = |\nu(e^{-i\omega})|$ — how much a cycle of frequency $\omega$ is scaled. $G=1$ means "pass untouched", $G=0$ means "annihilate".
- **Phase** $\varphi(\omega)$ — how much that cycle is shifted in time.

Two properties worth memorising:

> [!important] Symmetric filters have zero phase
> If $w_j = w_{-j}$, the imaginary parts cancel and $\nu(e^{-i\omega})$ is **real**. Phase shift is 0 (or $\pi$, a sign flip, where the gain function goes negative).
>
> This matters enormously: a filter with nonzero phase would **move turning points in time**. A recession would appear to start in a different month than it did. Every filter in X-11's interior is symmetric for exactly this reason — and the asymmetric end filters, which cannot have zero phase, are correspondingly suspect at precisely the moments people care about.

Second: $\sum_j w_j = 1$ implies $G(0) = 1$ — the filter preserves the level. Every trend filter in X-11 has weights summing to 1.

## Reading a gain function

For seasonal adjustment you want to look at three places on the $\omega$ axis:

| Where | $\omega$ | You want the *trend* filter to | You want the *seasonal adjustment* filter to |
|---|---|---|---|
| Frequency 0 | $0$ | pass ($G=1$) | pass ($G=1$) |
| Seasonal frequencies | $2\pi k/12$, $k=1..6$ | kill ($G=0$) | kill ($G=0$) |
| High frequencies | near $\pi$ | kill (that is noise) | mostly pass (irregular stays in an SA series) |

The difference between the last two columns is the whole distinction between a **trend-cycle** estimate and a **seasonally adjusted** series. The SA series keeps the irregular; the trend does not. People conflate these constantly.

## Composition is multiplication

Apply filter $\nu_1$ then $\nu_2$ and you get $\nu_2(B)\nu_1(B)$ — polynomial multiplication again ([[10-01-lag-operator]]), so the gains multiply:

$$G_{\text{total}}(\omega) = G_1(\omega)\,G_2(\omega)$$

This is how you analyse X-11 despite it being an iteration of six or seven separate averages: **compose them into one filter and plot its gain.** That is the goal of [[20-05-the-x11-iteration]], and the reason X-11 is comparable to SEATS at all — both end up as a single linear filter with a plottable gain.

## Exercises

1. Plot the gain of a simple 3-term MA $(1/3, 1/3, 1/3)$. What does it do at $\omega = 2\pi/3$? Why exactly zero?
2. Plot the gain of a 12-term *uncentred* MA. Notice the phase is nonzero — confirm it, and confirm centring fixes it.
3. Convolve a 3-term and a 5-term MA. Verify the gain of the product equals the product of the gains.

## Links

- Next: [[20-02-the-12-term-ma]]
- Theory: [[30-05-filters-in-the-frequency-domain]]
