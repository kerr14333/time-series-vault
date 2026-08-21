---
aliases: [Moving averages as filters, Linear filters, Gain function]
tags: [module-2]
---

# Moving averages are filters

Code: [[code-20-01-moving-averages-as-filters|`R/20-01-moving-averages-as-filters.R`]]

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

![[20-01-gain-basics.png]]

*Drawn by [[figure-index#20-01-gain-basics.png|`make-figures.R`]] — code and every other figure in the [[figure-index|figure appendix]].*

The simplest case: a 3-term average annihilates cycles of period 3 exactly (gain 0 at $\omega = 1/3$), and because it is symmetric its phase is flat zero.

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

## Numerically

A moving average is a filter, and a filter is defined by what it does to each frequency.

The 3-term average, as weights and as a gain. Gain 1 at frequency 0 means the trend passes untouched; the dip is what it removes:

<!-- run -->
```r
w3 <- rep(1, 3) / 3
f  <- c(0, 1/12, 1/6, 1/4, 1/3, 5/12, 1/2)
round(rbind(freq = f, gain = gain(w3, f)), 4)
```
```text
     [,1]   [,2]   [,3]   [,4]   [,5]   [,6]   [,7]
freq    0 0.0833 0.1667 0.2500 0.3333 0.4167 0.5000
gain    1 0.9107 0.6667 0.3333 0.0000 0.2440 0.3333
```
<!-- end -->

Weights always sum to 1, which *is* the statement that gain at frequency 0 equals 1 — a filter that changes the level of a flat series would be useless:

<!-- run -->
```r
for (w in list(rep(1,3)/3, ma_2xs(12), henderson(13))) {
  cat(sprintf("length %2d  sum = %.10f  gain(0) = %.10f\n",
              length(w), sum(w), gain(w, 0)))
}
```
```text
length  3  sum = 1.0000000000  gain(0) = 1.0000000000
length 13  sum = 1.0000000000  gain(0) = 1.0000000000
length 13  sum = 1.0000000000  gain(0) = 1.0000000000
```
<!-- end -->

## Exercises

*Solutions: [[solutions#20-01-moving-averages-as-filters|worked answers]] in the solutions appendix.*

1. Plot the gain of a simple 3-term MA $(1/3, 1/3, 1/3)$. What does it do at $\omega = 2\pi/3$? Why exactly zero?
2. Plot the gain of a 12-term *uncentred* MA. Notice the phase is nonzero — confirm it, and confirm centring fixes it.
3. Convolve a 3-term and a 5-term MA. Verify the gain of the product equals the product of the gains.

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** Where will a 5-term average have its zeros? Say so before plotting, then confirm.
2. **Break it.** Build a filter whose weights sum to 1.1 and apply it to a flat series. What happens, and which property have you violated?
3. **Transfer.** What length of simple average annihilates a quarterly seasonal? Confirm its gain at $k/4$.

## Practice set

*Drills, output-reading and judgement calls. Short answers; the point is fluency and knowing what you are looking at.*

1. **Drill.** Compute the gain of a 3-, 5- and 7-term average at $f = 1/12$ and at $f = 1/3$.
2. **Drill.** For each, list the frequencies where the gain is exactly zero.
3. **Read it.** A filter has gain 1 at $f=0$ and 0.02 at $f=1/12$. Trend filter or seasonal filter?
4. **Judgement.** You need to suppress a 5-month cycle without touching the annual one. What length do you choose?

## Links

- Next: [[20-02-the-12-term-ma]]
- Theory: [[30-05-filters-in-the-frequency-domain]]
