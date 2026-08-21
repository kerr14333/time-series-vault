---
aliases: [Filters in the frequency domain, Transfer function, Squared gain]
tags: [module-3]
---

# Filters in the frequency domain

Code: [[code-30-05-filters-in-the-frequency-domain|`R/30-05-filters-in-the-frequency-domain.R`]]

[[20-01-moving-averages-as-filters]] introduced gain and phase operationally. This note supplies the theorem they rest on and applies it to the operators from Module 1.

## The filtering theorem

If $y_t = \nu(B)x_t$ then

$$\boxed{\,f_y(\omega) = \left|\nu(e^{-i\omega})\right|^2 f_x(\omega)\,}$$

The spectrum is multiplied pointwise by the **squared gain**. Filtering does not mix frequencies — it only rescales each one independently. That independence is what makes frequency-domain reasoning so much easier than time-domain reasoning, and it is why [[30-03-spectrum-of-an-arma]] followed in one line.

$\nu(e^{-i\omega})$ is the **transfer function**; $|\nu|$ is the gain and $\arg\nu$ the phase.

## Differencing, seen properly

Now the operators of [[10-06-differencing]] become plottable objects.

**First difference $(1-B)$:**

$$\left|1 - e^{-i\omega}\right|^2 = (1-e^{-i\omega})(1-e^{i\omega}) = 2 - 2\cos\omega = 4\sin^2(\omega/2)$$

so the gain is $2|\sin(\omega/2)|$ — **zero at $\omega=0$**, rising monotonically to **2 at $\omega=\pi$**.

Two readings, both important:

- It annihilates the trend exactly. Good.
- It **amplifies high frequencies by up to a factor of 2**. Differencing is not a neutral operation: it whitens by suppressing the low end *and boosting the high end*. This is why an over-differenced series looks noisier, and the frequency-domain explanation of the over-differencing signature in [[10-05-invertibility]].

**Seasonal difference $(1-B^{12})$:** gain $2|\sin(6\omega)|$ — zero at $\omega = 2\pi k/12$ for $k = 0,1,\dots,6$. Seven zeros: the six seasonal frequencies **and** frequency 0.

That last point is the factorisation $1-B^{12} = (1-B)S(B)$ made visible: the $(1-B)$ factor supplies the zero at 0, and $S(B)$ supplies the other six.

![[30-05-differencing-gain.png]]

*Drawn by [[figure-index#30-05-differencing-gain.png|`make-figures.R`]] — code and every other figure in the [[figure-index|figure appendix]].*

## Composition and the X-11 payoff

Filters compose by multiplication, so squared gains multiply:

$$\left|\nu_2\nu_1\right|^2 = |\nu_2|^2\,|\nu_1|^2$$

which is why the whole X-11 iteration collapses to a single gain function ([[20-05-the-x11-iteration]]). At this point X-11 and SEATS become **directly comparable objects**: both are linear filters, both have a plottable gain, and you can overlay them. That comparison is [[50-09-x11-vs-seats]], and it is only possible because of this note.

## Phase, and why symmetric filters are non-negotiable

For a symmetric filter ($w_j = w_{-j}$) the transfer function is real, so the phase is 0 or $\pi$ — no time shift.

An asymmetric filter has genuinely frequency-dependent phase: different cycles get shifted by different amounts. In a seasonally adjusted series that means **turning points move**, and they move by different amounts depending on which frequencies dominate locally. This is the precise statement of what goes wrong at the ends of the sample ([[20-07-end-filters]]).

## The ideal seasonal-adjustment filter, and why you cannot have it

Frequency-domain thinking makes the goal easy to state:

$$\nu_{\text{ideal}}(\omega) = \begin{cases} 0 & \omega = 2\pi k/12,\ k=1..6\\ 1 & \text{otherwise}\end{cases}$$

Kill the seasonal frequencies exactly, pass everything else untouched.

> [!warning] Why no such filter exists
> A filter with a discontinuous gain requires **infinitely many** weights — and worse, it is the wrong target anyway. Real seasonality is not confined to exactly six frequencies: because it **evolves**, its power is smeared into narrow *bands* around them ([[30-04-pseudo-spectrum]]).
>
> So any real filter must trade off notch depth, notch width, and how much of the neighbouring non-seasonal power it destroys. X-11 resolves that trade-off with a fixed empirical recipe; SEATS resolves it using a model fitted to the series. **That is the entire difference between the two methods.**

Everything else — Henderson lengths, 3×5 versus 3×9, canonical decomposition — is detail hanging off that one sentence.

## Exercises

*Solutions: [[solutions#30-05-filters-in-the-frequency-domain|worked answers]] in the solutions appendix.*

1. Plot the gain of $(1-B)$ and confirm $2|\sin(\omega/2)|$, including the value 2 at $\omega = \pi$.
2. Plot the gain of $(1-B^{12})$ and count the zeros.
3. Difference white noise and compare its periodogram with the flat original. Confirm the high-frequency amplification.
4. Overlay the X-11 composite gain from [[20-05-the-x11-iteration]] on the ideal notch filter. Where does the real filter over- or under-shoot?
5. Confirm the phase of a symmetric filter is 0, and of a one-sided filter is not.

> [!abstract] Derivation
> - [[derivations#D11. Why a symmetric filter has zero phase, and an end filter does not|the zero-phase proof]]
> - [[derivations#D7. Why differencing is a filter with zeros where the seasonal lives|the gain of $1-B^s$]]

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** Does differencing amplify or attenuate high frequencies? By what factor at $\omega=\pi$? Guess, then compute.
2. **Break it.** Apply a one-sided filter to a pure sine and measure how far the output is shifted in time. Compare with the group delay.
3. **Transfer.** Compute the gain of $(1-B^4)$ and count its zeros. Compare with $(1-B^{12})$.

## Links

- Prev: [[30-04-pseudo-spectrum]] · Next: [[30-06-wiener-kolmogorov]]
