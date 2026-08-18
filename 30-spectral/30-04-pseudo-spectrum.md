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

Left: all seven poles, on a log axis. Right: the annual peak alone, as $\Theta$ varies — the same coefficient you read off X-13 output, now visible as peak width.

## Why the infinities are harmless

Two reasons SEATS can work with them:

1. **The decomposition is about *shares*.** The Wiener–Kolmogorov filter ([[30-06-wiener-kolmogorov]]) is the ratio $f_s/f_z$. At a seasonal frequency both numerator and denominator are infinite, and the *ratio tends to 1* — the seasonal owns all the power there. Ratios of infinities behave, even when the pieces do not.
2. **Differencing makes everything finite.** In practice you work with the stationary differenced series, where the offending factors have been divided out, and reinstate them at the end.

## Reading a pseudo-spectrum plot

Always plot $\log f$, and expect the peaks to run off the top of the axis. What to look at:

- **Where** the peaks are — which components the model implies.
- **How wide** they are — how stable each component is.
- **The floor** between peaks — the irregular's contribution.
- **The trough locations** — numerator roots, i.e. frequencies the model says contain *nothing*.

## Exercises

1. Plot the airline-model pseudo-spectrum on a log axis for $(\theta,\Theta) = (0.4, 0.6)$. Mark the seven infinite peaks.
2. Vary $\Theta$ from 0.2 to 0.95 and watch the seasonal peaks narrow. Relate to revision size ([[20-08-x11-arima]]).
3. Vary $\theta$ and watch the trend peak change shape.
4. Plot the pseudo-spectrum of $(1-B)$ alone and of $(1-B^{12})$ alone. Confirm the peak locations against the root table in [[10-06-differencing]].
5. Overlay a smoothed periodogram of the *undifferenced* `log(AirPassengers)`. It cannot show infinities, but the peaks should line up.

## Links

- Prev: [[30-03-spectrum-of-an-arma]] · Next: [[30-05-filters-in-the-frequency-domain]]
- Payoff: [[40-00-seats-map]]
