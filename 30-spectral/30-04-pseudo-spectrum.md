---
aliases: [Pseudo-spectrum, Pseudospectrum, Nonstationary spectrum]
tags: [module-3, key]
---

# The pseudo-spectrum

Code: [[code-30-04-pseudo-spectrum|`R/30-04-pseudo-spectrum.R`]]

## The problem

The spectral density of [[30-02-spectral-density]] was defined for a **stationary** series — it needs the $\gamma_k$ to exist. A series with unit roots has infinite variance, so strictly it has no spectrum.

But the formula from [[30-03-spectrum-of-an-arma]] does not care:

$$f(\omega) = \frac{\sigma_a^2}{2\pi}\cdot\frac{|\theta(e^{-i\omega})|^2}{|\phi(e^{-i\omega})|^2}$$

Feed it a $\phi$ containing $(1-B)$ and at $\omega = 0$ the denominator is $|1 - e^{0}|^2 = 0$. The expression **diverges**.

## The move

Use it anyway, and call the result the **pseudo-spectrum**. It is a well-defined function everywhere except at finitely many frequencies, where it goes to $+\infty$.

This is not a fudge. It is the standard object in model-based seasonal adjustment, and the infinities are not a defect — they are precisely the **signature of the components**.

> [!important] Unit roots are infinite spectral peaks, and that is where the components live
> | Factor in $\phi$ | Root at | Infinite peak at | Component |
> |---|---|---|---|
> | $(1-B)$ | $z=1$ | $\omega = 0$ | **trend** |
> | $(1-B)^2$ | $z=1$ twice | $\omega = 0$, sharper | trend with drifting slope |
> | $S(B) = 1+B+\cdots+B^{11}$ | 11 roots on the circle | $\omega = 2\pi k/12$, $k=1..6$ | **seasonal** |
> | stationary complex pair, modulus $\to1$ | angle $\omega_0$ | large finite peak at $\omega_0$ | transitory / cycle |
>
> **Sorting the roots into these bins is step 1 of SEATS.** Everything after is bookkeeping.

## The airline model, drawn

$(1-B)(1-B^{12}) = (1-B)^2 S(B)$ ([[10-06-differencing]]), so its pseudo-spectrum has:

- a **double** infinite peak at $\omega = 0$ — the trend,
- **six** infinite peaks at the seasonal frequencies — the seasonal,
- a finite floor everywhere else — the irregular,

and the numerator $|(1-\theta e^{-i\omega})(1-\Theta e^{-12i\omega})|^2$ modulates how *fast* the spectrum falls away from each peak.

That modulation is the practical content of $\theta$ and $\Theta$:

- $\Theta$ close to 1 puts a numerator near-zero right next to each seasonal denominator-zero, so the peaks are **narrow** — a stable, sharply-defined seasonal.
- $\Theta$ small leaves the peaks **broad** — a seasonal that wanders across neighbouring frequencies, i.e. evolves quickly.

You met exactly this in [[10-10-airline-model]] as "how much the seasonal is allowed to evolve". Here it is visible as peak width. Same fact, third language.

![[30-04-pseudo-spectrum.png]]

*Drawn by [[figure-index#30-04-pseudo-spectrum.png|`make-figures.R`]] — code and every other figure in the [[figure-index|figure appendix]].*

Left: all seven poles, on a log axis. Right: the annual peak alone, as $\Theta$ varies — the same coefficient you read off X-13 output, now visible as peak width.

## Why the infinities are harmless

Two reasons SEATS can work with them:

1. **The decomposition is about *shares*.** The Wiener–Kolmogorov filter ([[30-06-wiener-kolmogorov]]) is the ratio $f_s/f_z$. At a seasonal frequency both numerator and denominator are infinite, and the *ratio tends to 1* — the seasonal owns all the power there. Ratios of infinities behave, even when the pieces do not.
2. **Differencing makes everything finite.** In practice you work with the stationary differenced series, where the offending factors have been divided out, and reinstate them at the end.

## Deterministic versus evolving seasonality, spectrally

$\Theta$ sets the peak width, so two real series make the extremes visible.

| Series | $\Theta$ | What the seasonal is | Peaks |
|---|---|---|---|
| `nottem` (temperatures) | 0.922 | genuinely **deterministic** — the Earth's orbit | very narrow |
| `co2` (Mauna Loa) | 0.912 | stochastic but extremely stable | very narrow |
| `AirPassengers` | 0.557 | ordinary evolving | moderate |
| `UKgas` | 0.235 | re-rolls almost yearly | **broad** |

A perfectly deterministic seasonal is a set of **pure spectral lines** — infinitely narrow spikes, zero width, no power at neighbouring frequencies. As $\Theta \to 1$ the airline model's seasonal peaks approach exactly that, which is the frequency-domain statement of "the pattern stops evolving".

So the spectral picture and the time-domain reading of $\Theta$ from [[10-10-airline-model]] are the same fact:

```text
Theta -> 1     narrow peaks     pattern fixed        small revisions
Theta -> 0     broad peaks      pattern wanders      large revisions
```

`nottem` and `co2` reach nearly the same $\Theta$ by different routes — one because the physics is fixed, the other because the process is very stable. The model cannot tell them apart, and does not need to.

## Reading a pseudo-spectrum plot

Always plot $\log f$, and expect the peaks to run off the top of the axis. What to look at:

- **Where** the peaks are — which components the model implies.
- **How wide** they are — how stable each component is.
- **The floor** between peaks — the irregular's contribution.
- **The trough locations** — numerator roots, i.e. frequencies the model says contain *nothing*.

## Numerically

A unit root makes the spectrum infinite. The 'pseudo' is doing real work in that name.

The airline model has seven infinite peaks: frequency 0 plus the six seasonal ones. Evaluated exactly at those frequencies the denominator is zero:

<!-- run -->
```r
ff <- c(0, seas_freq(12))
den <- sq_gain_poly(airline_ar(), ff)
round(rbind(freq = ff, `|AR|^2` = den), 12)
```
```text
       [,1]       [,2]      [,3] [,4]      [,5]      [,6] [,7]
freq      0 0.08333333 0.1666667 0.25 0.3333333 0.4166667  0.5
|AR|^2    0 0.00000000 0.0000000 0.00 0.0000000 0.0000000  0.0
```
<!-- end -->

Approach one of them and the pseudo-spectrum blows up. It is not large, it is unbounded:

<!-- run -->
```r
near <- 1/12 + c(1e-2, 1e-3, 1e-4, 1e-5)
ps <- arma_spectrum(ma_poly = airline_ma(0.4, 0.6), ar_poly = airline_ar(), freq = near)
round(rbind(distance_from_1_12 = near - 1/12, pseudo_spectrum = ps), 4)
```
```text
                     [,1]   [,2]     [,3]     [,4]
distance_from_1_12 0.0100 0.0010   0.0001     0.00
pseudo_spectrum    0.2105 7.8385 779.7582 78085.76
```
<!-- end -->

Theta controls the *width* of the peak, not whether it exists. A high Theta means stable seasonality, hence a narrow, well-pinned peak:

<!-- run -->
```r
w <- 1/12 + 0.004
for (Th in c(0.2, 0.6, 0.95))
  cat(sprintf("  Theta = %.2f : pseudo-spectrum just off the peak = %8.2f\n",
              Th, arma_spectrum(ma_poly = airline_ma(0.4, Th),
                                ar_poly = airline_ar(), freq = w)))
```
```text
  Theta = 0.20 : pseudo-spectrum just off the peak =     1.89
  Theta = 0.60 : pseudo-spectrum just off the peak =     0.61
  Theta = 0.95 : pseudo-spectrum just off the peak =     0.25
```
<!-- end -->

## Exercises

*Solutions: [[solutions#30-04-pseudo-spectrum|worked answers]] in the solutions appendix.*

1. Plot the airline-model pseudo-spectrum on a log axis for $(\theta,\Theta) = (0.4, 0.6)$. Mark the seven infinite peaks.
2. Vary $\Theta$ from 0.2 to 0.95 and watch the seasonal peaks narrow. Relate to revision size ([[20-08-x11-arima]]).
3. Vary $\theta$ and watch the trend peak change shape.
4. Plot the pseudo-spectrum of $(1-B)$ alone and of $(1-B^{12})$ alone. Confirm the peak locations against the root table in [[10-06-differencing]].
5. Overlay a smoothed periodogram of the *undifferenced* `log(AirPassengers)`. It cannot show infinities, but the peaks should line up.

> [!abstract] Derivation
> - [[derivations#D7. Why differencing is a filter with zeros where the seasonal lives|why unit roots give infinite peaks]]

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** How many infinite peaks does a *quarterly* airline model have? Answer before computing.
2. **Break it.** Evaluate the pseudo-spectrum exactly at $\omega = 0$ numerically. What does R return, and why is that the right answer?
3. Explain in two sentences why the infinities are a property of the model rather than of any dataset.

## Links

- Prev: [[30-03-spectrum-of-an-arma]] · Next: [[30-05-filters-in-the-frequency-domain]]
- Payoff: [[40-00-seats-map]]
