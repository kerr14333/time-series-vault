---
aliases: [Spectrum of an ARMA, Rational spectrum, ARMA spectral density]
tags: [module-3, key]
---

# The spectrum of an ARMA model

Code: [[code-30-03-spectrum-of-an-arma|`R/30-03-spectrum-of-an-arma.R`]]

**This is the central formula of the whole vault.** Everything in Module 4 is algebra performed on it.

$$\boxed{\;f(\omega) = \frac{\sigma_a^2}{2\pi}\cdot\frac{\left|\theta(e^{-i\omega})\right|^2}{\left|\phi(e^{-i\omega})\right|^2}\;}$$

for $\phi(B)z_t = \theta(B)a_t$.

## Where it comes from

Two steps, both already in hand.

1. White noise has a flat spectrum, $f_a(\omega) = \sigma_a^2/2\pi$ ([[30-02-spectral-density]]).
2. Passing a series through a filter $\nu(B)$ multiplies its spectrum by $|\nu(e^{-i\omega})|^2$ ([[30-05-filters-in-the-frequency-domain]]).

An ARMA *is* white noise passed through the filter $\theta(B)/\phi(B)$ ([[10-08-arma-duality]]). Apply step 2 to step 1 and you are done. No new machinery — the formula is the duality note translated into frequencies.

Written with the $B$/$F$ pairing that SEATS uses, since $|w|^2 = w\bar w$:

$$f(\omega) = \frac{\sigma_a^2}{2\pi}\cdot\frac{\theta(B)\theta(F)}{\phi(B)\phi(F)}\Bigg|_{B = e^{-i\omega}}$$

## How to read a model off its spectrum, and vice versa

This is the intuition to build, and it is worth more than the algebra:

> [!important] Roots near the unit circle dominate the spectrum
> - A root of $\phi$ (denominator) near $e^{-i\omega_0}$ makes $f$ **blow up** near $\omega_0$ — a **peak**.
> - A root of $\theta$ (numerator) near $e^{-i\omega_0}$ makes $f$ **collapse** near $\omega_0$ — a **trough**, and an exact zero if the root is *on* the circle.
> - The closer the root to the circle, the sharper the feature.

So: **AR gives peaks, MA gives troughs.** Every spectral shape in this subject is read that way.

Worked cases, all in the script:

| Model | Root location | Spectrum |
|---|---|---|
| AR(1), $\phi = 0.8$ | real, $1/0.8$, near 1 | power piled up at $\omega=0$; smooth, trending-looking |
| AR(1), $\phi = -0.8$ | real, near $-1$ | power piled at $\omega=\pi$; jagged, alternating |
| AR(2), complex, modulus near 1 | at angle $\omega_0$ | a **peak at $\omega_0$** — a pseudo-cycle |
| MA(1), $\theta = 1$ | on the circle at $z=1$ | **zero at $\omega=0$** — see [[10-05-invertibility]] |
| $(1-B^{12})$ as MA | 12 roots on the circle | zeros at all six seasonal frequencies **and at 0** |

That last row is worth pausing on. The operator you difference with, viewed as a filter, has zeros exactly where the seasonal component lives. Differencing seasonally does not "remove the seasonal" by magic — it applies a filter whose gain is zero at precisely those frequencies.

![[30-03-arma-spectra.png]]

*Drawn by [[figure-index#30-03-arma-spectra.png|`make-figures.R`]] — code and every other figure in the [[figure-index|figure appendix]].*

**Left — poles.** An AR(2) whose complex root pair sits at the annual frequency, drawn for three moduli. The nearer the roots to the unit circle, the taller and narrower the peak: heights **4.91**, **26.98**, **404.02** for moduli 0.80, 0.92 and 0.98. The vertical scale is logarithmic — on a linear one the third curve would flatten the other two onto the axis. At modulus exactly 1 the peak is infinite and this stops being a spectrum at all, which is [[30-04-pseudo-spectrum]].

**Right — zeros.** An MA(1), $\theta(B) = 1 - \theta B$, on a linear scale. Its value at frequency 0 is $(1-\theta)^2/2\pi$: **0.0398** at $\theta = 0.5$, **0.0016** at $\theta = 0.9$, and exactly **0** at $\theta = 1$. Near the circle is not on it — 0.0016 is small, but only the root *on* the circle gives a true zero.

Read together: **denominators make peaks, numerators make zeros.** AR roots push the spectrum up, MA roots pull it down, and the unit-modulus cases are the two extremes — an infinite peak and an exact zero. Note that $\theta = 1$ *is* the operator $1 - B$, so the right panel is ordinary differencing viewed as a filter: gain exactly zero at frequency 0, the trend. The same statement as the paragraph above, at one frequency instead of six.

> [!warning] The peak is not quite at the root's frequency
> The dashed line marks $f = 1/12$, the root's angle. The measured peaks are at **0.0760**, **0.0825** and **0.0835** — the first sits 0.0073 *below* the line, and the gap closes only as the modulus approaches 1. A broad spectral peak is a biased estimate of the cycle's period, which is one reason eyeballing peaks is a weaker diagnostic than the tests in [[50-01-is-there-seasonality]].

## Why "rational" matters

$f$ is a ratio of two polynomials in $e^{-i\omega}$ — a **rational** function. Two consequences that Module 4 lives on:

1. **Partial fractions apply.** Any rational function splits into a sum of simpler rational functions, one per denominator factor. Split $\phi$ into $\phi_T\phi_S$ and you can split $f$ into $f_T + f_S + f_I$. **That is the SEATS decomposition**, and it is nothing more exotic than the partial fractions from calculus, done in $B$ and $F$.
2. **Any spectrum can be approximated.** Rational functions are dense enough that a modest ARMA reproduces almost any spectral shape — the frequency-domain statement of why ARMA is a useful model class at all.

## The airline model's spectrum

For $(1-B)(1-B^{12})z_t = (1-\theta B)(1-\Theta B^{12})a_t$ the numerator and denominator have matching structure: both contain factors that vanish at $\omega=0$ and at the seasonal frequencies. The denominator's zeros are exactly *on* the circle (unit roots) and the numerator's are strictly inside (for $\theta,\Theta<1$).

The result is a spectrum that is **infinite** at 0 and at the six seasonal frequencies — which is not a well-defined spectral density at all. That is the subject of [[30-04-pseudo-spectrum]], and rather than being a problem it is the structure SEATS exploits.

## Exercises

*Solutions: [[solutions#30-03-spectrum-of-an-arma|worked answers]] in the solutions appendix.*

1. Plot the AR(1) spectrum for $\phi = 0.5, 0.9, -0.9$. Match each to the shape of the simulated series.
2. Plot the AR(2) spectrum with complex roots of modulus 0.95 at angle $2\pi/12$. Confirm the peak sits at the annual frequency, and that it sharpens as the modulus $\to 1$.
3. Plot the MA(1) spectrum for $\theta = 0.5$ and $\theta = 1$. Confirm the exact zero at $\omega=0$ in the second.
4. Overlay the theoretical airline-model spectrum on a smoothed periodogram of $\nabla\nabla_{12}\log(\text{AirPassengers})$.
5. Verify the formula numerically: compute $\gamma_k$ from `ARMAacf`, sum the definition in [[30-02-spectral-density]], and compare to the closed form.

> [!abstract] Derivation
> - [[derivations#D6. The spectral density, and the ARMA formula|where $|\theta|^2/|\phi|^2$ comes from]]

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** For an AR(1) with $\phi = -0.9$, will the spectral peak be at low or high frequency? Say why before plotting.
2. **Break it.** Compute an ARMA spectrum with the MA sign flipped. How different is it, and would you notice without the correct version beside it?
3. **Transfer.** Plot the spectrum of a quarterly airline model and count its peaks.

## Links

- Prev: [[30-02-spectral-density]] · Next: [[30-04-pseudo-spectrum]]
- Payoff: [[40-04-partial-fractions-in-b-and-f]]
