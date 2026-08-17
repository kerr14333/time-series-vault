---
aliases: [Spectra, Signal extraction, Module 3]
tags: [moc, module-3]
---

# Module 3 — Spectra and signal extraction

This is the module that makes SEATS possible. It is also the one people skip, and then SEATS
stays magic. Do not skip it.

## The one-line summary

> A time-series model is a recipe for a **spectrum**. A filter is a recipe for **reshaping** a
> spectrum. Seasonal adjustment is: split the spectrum into pieces, then build the filter that
> extracts each piece.

## Notes to write

- [[30-01-frequency-domain-basics]] — frequency $\omega \in [0,\pi]$, period $= 2\pi/\omega$;
  monthly seasonal frequencies $\omega_k = 2\pi k/12$, $k=1..6$
- [[30-02-spectral-density]] — $f(\omega) = \frac{1}{2\pi}\sum_k \gamma_k e^{-i\omega k}$;
  the Fourier transform of the ACF; total area = variance
- [[30-03-spectrum-of-an-arma]] —
  $$f(\omega) = \frac{\sigma_a^2}{2\pi}\,\frac{|\theta(e^{-i\omega})|^2}{|\phi(e^{-i\omega})|^2}$$
  Everything follows from this. AR roots near the unit circle → **peaks**. MA roots near the
  unit circle → **troughs/zeros**.
- [[30-04-pseudo-spectrum]] — for a nonstationary ARIMA, $\phi(e^{-i\omega})$ hits zero at the
  unit-root frequencies, so $f \to \infty$ there. Infinite peaks at 0 and at the seasonal
  frequencies. This is not a problem; it is the *signature* of the components, and it is what
  gets partitioned.
- [[30-05-filters-in-the-frequency-domain]] — a filter $\nu(B)$ multiplies the spectrum by
  $|\nu(e^{-i\omega})|^2$; **gain** and **phase**; why symmetric filters have zero phase shift
  (and why that matters: a phase shift would move turning points in time)
- [[30-06-wiener-kolmogorov]] — the minimum-MSE estimate of an unobserved component:
  $$\hat s_t = \frac{f_s(\omega)}{f_z(\omega)}\,z_t \quad\text{(in filter form: } \nu_s(B,F) = \frac{f_s}{f_z}\text{)}$$
  Read it as: **at each frequency, keep the share of the power that belongs to the component.**
  This is the single formula SEATS is built on.
- [[30-07-finite-samples]] — the WK filter is doubly infinite; real data is not. Burman's
  algorithm and the forecast-extension approach.

## Why the WK formula is intuitive

At a frequency where the seasonal owns all the power, $f_s/f_z = 1$ — keep everything. Where the
seasonal owns none, the ratio is 0 — discard. In between you keep a proportion. It is the
frequency-domain version of "signal-to-noise ratio", applied one frequency at a time, and it is
provably the minimum-MSE linear estimator under the model.

## Checkpoint

You are ready for Module 4 when you can, for the airline model, sketch the pseudo-spectrum and
mark: the infinite peak at $\omega=0$, the infinite peaks at each $\omega_k$, and the effect of
$\theta$ and $\Theta$ on how sharp those peaks are.

## Prerequisites

Module 1 in full, especially [[10-05-invertibility]] (spectral zeros) and
[[10-02-stationarity-and-roots]] (unit roots as frequencies). Complex exponentials —
if $e^{-i\omega} $ is uncomfortable, say so and we will do a warm-up note.
