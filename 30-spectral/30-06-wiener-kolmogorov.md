---
aliases: [Wiener-Kolmogorov, WK filter, Signal extraction]
tags: [module-3, key]
---

# Wiener–Kolmogorov signal extraction

Code: [[code-30-06-wiener-kolmogorov|`R/30-06-wiener-kolmogorov.R`]]

The formula SEATS is built on. Everything in Module 4 is this note plus bookkeeping.

## The problem

You observe $z_t$. You believe it is a sum of unobserved components,

$$z_t = s_t + n_t,$$

with $s$ and $n$ **independent**, each with a known model and hence a known spectrum. Estimate $s_t$ from the *whole* observed series, minimising mean squared error.

## The answer

$$\boxed{\;\hat{s}_t = \nu_s(B,F)\,z_t, \qquad \nu_s(B,F) = \frac{f_s(\omega)}{f_z(\omega)} = \frac{f_s(\omega)}{f_s(\omega)+f_n(\omega)}\;}$$

**At each frequency, keep the share of the power that belongs to the component.**

That is the whole idea, and it is worth reading three times, because after it everything in Module 4 is algebra.

## Why it is obviously right

Because filtering acts on each frequency independently ([[30-05-filters-in-the-frequency-domain]]), the problem separates into one tiny problem per frequency: given observed power $f_s + f_n$, how much should you keep to best estimate the part contributing $f_s$?

That is the classic signal-to-noise shrinkage answer, $f_s/(f_s+f_n)$ — the frequency-by-frequency analogue of a regression coefficient, or of the Kalman gain. The limits confirm it:

| Situation | $\nu_s(\omega)$ | Behaviour |
|---|---|---|
| the component owns all the power, $f_n = 0$ | 1 | keep everything |
| the component has none, $f_s = 0$ | 0 | discard everything |
| equal power | 0.5 | split the difference |

And notice: $\nu_s + \nu_n = 1$ at every frequency. **The component estimates add back up to the observed series exactly** — the decomposition is additive by construction, not approximately.

## In model terms

Suppose the components follow ARIMA models

$$\phi_s(B)\,s_t = \theta_s(B)\,a_{st}, \qquad \phi_n(B)\,n_t = \theta_n(B)\,a_{nt}$$

with innovation variances $\sigma_s^2,\sigma_n^2$, and the observed series follows $\phi(B)z_t = \theta(B)a_t$ where $\phi = \phi_s\phi_n$. Substituting the ARMA spectra of [[30-03-spectrum-of-an-arma]] and cancelling:

$$\nu_s(B,F) = \frac{\sigma_s^2}{\sigma_a^2}\cdot\frac{\theta_s(B)\,\theta_s(F)\,\phi_n(B)\,\phi_n(F)}{\theta(B)\,\theta(F)}$$

Three things to notice, all of which matter in [[40-06-wk-filters-for-the-airline-model]]:

1. **The component's own MA appears in the numerator**, squared as $\theta_s(B)\theta_s(F)$.
2. **The *other* component's AR appears in the numerator too.** The trend filter carries the seasonal's $\phi$ — which is why the trend filter has zeros exactly at the seasonal frequencies. Its job is to reject the seasonal, so of course it inherits the seasonal's denominator.
3. **The observed series' MA is the denominator**, shared by every component's filter.

## Properties of the filter

- **Symmetric** in $B$ and $F$, hence **zero phase** — no turning points get moved. Compare [[30-05-filters-in-the-frequency-domain]].
- **Doubly infinite** — it uses the entire past *and the entire future*. That is what [[30-07-finite-samples]] has to deal with.
- **Convergent** — the weights decay geometrically, at a rate set by how close the roots of $\theta(B)$ are to the unit circle. Near-unit MA roots mean slowly decaying weights, hence a filter that reaches far in both directions, hence **larger end effects and bigger revisions**.

That last point closes a loop: $\Theta$ near 1 makes the *seasonal peaks narrow* ([[30-04-pseudo-spectrum]]) and also makes the *filter weights decay slowly*. Narrow notches require long filters. There is no way around it — a sharp frequency-domain feature demands a wide time-domain window. That is the uncertainty principle showing up in seasonal adjustment.

![[30-06-wk-gain.png]]

*Drawn by [[figure-index#30-06-wk-gain.png|`make-figures.R`]] — code and every other figure in the [[figure-index|figure appendix]].*

Right-hand panel: the weights are symmetric and decay geometrically — but they never stop. That is what [[30-07-finite-samples]] has to resolve.

## The catch that motivates the canonical decomposition

The formula needs $f_s$ and $f_n$ **separately**. But all you ever observe is $z$, so all you can ever fit is $f_z$. And infinitely many pairs $(f_s, f_n)$ sum to the same $f_z$ — move a constant amount of white noise from one to the other and nothing observable changes.

> [!important] The decomposition is not identified by the data
> Splitting $f_z$ into components requires an assumption **beyond** the fitted model. It cannot be estimated, because every admissible split fits identically.

Two ways out:

- **Structural modelling**: specify the components directly and fit them (the Harvey / STAMP approach).
- **Canonical decomposition**: fit the *observed* series, then pick the split by a stated convention — maximise the irregular's variance, so every other component is as smooth and stable as possible.

SEATS takes the second. That convention is [[40-03-canonical-decomposition]], and this note is the reason one is needed at all.

## Numerically

Keep the share of the power that is yours. That is the whole filter.

The gains must sum to 1 at every frequency — every bit of power goes somewhere:

<!-- run -->
```r
ma <- airline_ma(0.4018, 0.5569); ar <- airline_ar()
sp <- seats_ar_split(1, 1, 12)
pf <- seats_partial_fractions(ma, sp$trend, sp$seas)
cn <- seats_canonical(pf)
w  <- seq(0, pi, length.out = 400)
nu <- seats_filters(cn, w)
cat("max |nu_T + nu_S + nu_I - 1| =",
    format(max(abs(nu$trend + nu$seasonal + nu$irregular - 1))), "\n")
```
```text
max |nu_T + nu_S + nu_I - 1| = 1.17395e-12 
```
<!-- end -->

Ownership at the poles is total, not approximate. The trend takes everything at frequency 0; the seasonal takes everything at each seasonal frequency:

<!-- run -->
```r
wq <- c(0, 2*pi/12, 2*pi/6, pi)
nq <- seats_filters(cn, wq)
round(rbind(omega = wq, trend = nq$trend,
            seasonal = nq$seasonal, irregular = nq$irregular), 5)
```
```text
          [,1]   [,2]   [,3]    [,4]
omega        0 0.5236 1.0472 3.14159
trend        1 0.0000 0.0000 0.00000
seasonal     0 1.0000 1.0000 1.00000
irregular    0 0.0000 0.0000 0.00000
```
<!-- end -->

The filter weights, returned as lags $0,1,2,\dots$ — the filter is symmetric by construction, so $w_{-j} = w_j$ and only one side needs storing. Watch how slowly they die:

<!-- run -->
```r
wts <- filter_weights(nu$seasonal, w, max_lag = 60)   # index 1 is lag 0
cat("lags 0..5 :", round(wts[1:6], 5), "\n")
cat("lag 12    :", round(wts[13], 5), "   lag 24:", round(wts[25], 5), "\n")
cat("lag 60    :", format(wts[61]), " -- still not zero after five years\n")
```
```text
lags 0..5 : 0.21067 -0.01406 -0.01844 -0.01967 -0.01965 -0.01912 
lag 12    : 0.15641    lag 24: 0.08711 
lag 60    : 0.01504468  -- still not zero after five years
```
<!-- end -->

## Exercises

1. Signal + noise: random walk plus white noise. Plot $f_s$, $f_n$, and $\nu_s = f_s/f_z$. Confirm the gain is near 1 at low frequencies and near 0 at high.
2. Vary the noise-to-signal ratio and watch the filter's cutoff move. Relate to the MA coefficient you fitted in `R/10-04-ma-processes.R`.
3. Compute the WK filter weights by inverting the transfer function numerically, and confirm they are symmetric and decay.
4. Confirm $\nu_s(\omega) + \nu_n(\omega) = 1$ at every frequency.
5. Show two different $(f_s, f_n)$ pairs giving the same $f_z$ — the identification problem, made concrete.

> [!abstract] Derivation
> - [[derivations#D8. The Wiener–Kolmogorov filter|the orthogonality argument for $f_s/f_z$]]

## Links

- Prev: [[30-05-filters-in-the-frequency-domain]] · Next: [[30-07-finite-samples]]
- Payoff: [[40-03-canonical-decomposition]], [[40-06-wk-filters-for-the-airline-model]]
