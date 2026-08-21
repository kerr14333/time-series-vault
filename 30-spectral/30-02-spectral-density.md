---
aliases: [Spectral density, Spectrum, Periodogram]
tags: [module-3]
---

# The spectral density

Code: [[code-30-02-spectral-density|`R/30-02-spectral-density.R`]]

## Definition

For a stationary series with autocovariances $\gamma_k$:

$$f(\omega) = \frac{1}{2\pi}\sum_{k=-\infty}^{\infty} \gamma_k e^{-i\omega k}, \qquad \omega \in [-\pi, \pi]$$

The **Fourier transform of the autocovariance function**. It is invertible:

$$\gamma_k = \int_{-\pi}^{\pi} f(\omega)\,e^{i\omega k}\,d\omega$$

So $f$ and $\{\gamma_k\}$ carry *identical* information. Nothing is gained or lost by switching — but questions that are awkward in one are trivial in the other, and seasonal adjustment is emphatically a frequency-domain question.

## The interpretation that matters

Set $k=0$ in the inversion formula:

$$\gamma_0 = \mathrm{Var}(z_t) = \int_{-\pi}^{\pi} f(\omega)\,d\omega$$

> [!important] The spectrum distributes variance across frequency
> The area under $f$ over a band of frequencies is **the amount of the series' variance contributed by cycles in that band**.

That single sentence makes the rest of the subject readable:

- A **seasonal** series has spikes at $\omega_k = 2\pi k/12$ — a large share of its variance lives in cycles of period 12, 6, 4, …
- A **trending** series has enormous power near $\omega = 0$ — most of its variance is in very long cycles.
- **White noise** is flat: $f(\omega) = \sigma_a^2/2\pi$, every frequency contributing equally. Hence "white", by analogy with light.
- **Seasonal adjustment** is: remove the variance sitting at the seasonal frequencies, keep the rest.

## Properties

- **Real and symmetric.** $f(-\omega) = f(\omega)$, so only $[0,\pi]$ is ever plotted. (Symmetry holds because $\gamma_k = \gamma_{-k}$ and the imaginary parts cancel.)
- **Non-negative.** $f(\omega) \ge 0$ everywhere. A "spectrum" that goes negative somewhere is not a spectrum — this is exactly the **admissibility** condition that constrains SEATS in [[40-02-admissible-decompositions]].
- **Additive over independent components.** If $z = s + n$ with $s \perp n$, then $f_z = f_s + f_n$. This is the property the entire decomposition rests on.

That last point deserves emphasis. Decomposing a series into trend + seasonal + irregular is *hard* in the time domain and *addition* in the frequency domain. That is the whole reason SEATS works in frequencies.

## Estimating it: the periodogram

The natural sample estimate at Fourier frequency $\omega_j = 2\pi j/n$:

$$I(\omega_j) = \frac{1}{2\pi n}\left|\sum_{t=1}^{n} z_t e^{-i\omega_j t}\right|^2$$

> [!warning] The periodogram is not consistent
> Its variance does **not** shrink as $n$ grows. More data gives you more frequencies, not a better estimate at each one. A raw periodogram looks like grass — wildly noisy — and people routinely over-interpret its spikes.

Fixes, all amounting to averaging neighbouring frequencies:

- **Smoothing** with a Daniell kernel — R's `spans` argument. `spec.pgram(x, spans = c(3,5))`.
- **Tapering** the ends to reduce leakage — R's `taper`, default 0.1.
- **Parametric estimation**: fit an AR or ARMA and use its theoretical spectrum ([[30-03-spectrum-of-an-arma]]). This is what X-13's diagnostic spectra do, and it is much smoother.

Practical note: always plot on a **log scale**. Trend power at $\omega\approx0$ is orders of magnitude above everything else, and on a linear axis it flattens the entire rest of the plot into the floor.

## What you will actually look at

In diagnostics ([[50-02-residual-seasonality]]) you examine the spectrum of the *irregular* or the *differenced adjusted series*, and ask: **is there still a peak at a seasonal frequency?** If yes, the adjustment failed. That is the single most decisive diagnostic in the field, and it is just this note applied.

## Numerically

The spectrum is the autocovariances, rewritten. Nothing is added or lost.

Two routes to the same function: the Fourier transform of the ACF, and the closed form. They agree to machine precision:

<!-- run -->
```r
ar <- 0.7
g  <- ar^(0:200) / (1 - ar^2)          # autocovariances of an AR(1)
a <- spectrum_from_acov(g)
b <- arma_spectrum(ar_poly = c(1, -ar))
cat("max |definition - closed form| =", format(max(abs(a - b))), "\n")
```
```text
max |definition - closed form| = 1.110223e-15 
```
<!-- end -->

The spectrum integrates to the variance. That is the sense in which it *decomposes* the variance across frequencies:

<!-- run -->
```r
f <- arma_spectrum(ar_poly = c(1, -0.7))
tot <- 2 * mean(f) * 0.5 * 2 * pi       # over -pi..pi, FREQ is 0..0.5 cycles
cat("integral of spectrum :", round(tot, 6), "\n")
cat("gamma_0 = 1/(1-phi^2):", round(1 / (1 - 0.7^2), 6), "\n")
```
```text
integral of spectrum : 1.964548 
gamma_0 = 1/(1-phi^2): 1.960784 
```
<!-- end -->

White noise is flat — every frequency contributes equally. That is what makes it the reference against which peaks mean something:

<!-- run -->
```r
w <- arma_spectrum()
cat("white noise spectrum: min", round(min(w), 6), " max", round(max(w), 6), "\n")
cat("flat to within", format(diff(range(w))), "\n")
```
```text
white noise spectrum: min 0.159155  max 0.159155 
flat to within 0 
```
<!-- end -->

## Exercises

*Solutions: [[solutions#30-02-spectral-density|worked answers]] in the solutions appendix.*

1. Simulate white noise. Plot the raw periodogram, then with `spans = c(3,3)` and `c(7,7)`. Watch it settle toward the flat truth.
2. Confirm $\int f = \gamma_0$ numerically by summing the periodogram.
3. Plot the spectrum of `log(AirPassengers)` after $\nabla\nabla_{12}$. Where are the peaks? Compare with the ACF of the same series from [[10-07-acf-and-pacf]] — the same facts in two languages.
4. Compare the spectrum of the raw series with that of the seasonally adjusted series from Module 2. Did the seasonal peaks go?

> [!abstract] Derivation
> - [[derivations#D6. The spectral density, and the ARMA formula|from autocovariances to the ARMA ratio]]

## Links

- Prev: [[30-01-frequency-domain-basics]] · Next: [[30-03-spectrum-of-an-arma]]
