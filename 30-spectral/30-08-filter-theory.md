---
aliases: [Filter theory, LTI, Transfer function, Gain and phase, Group delay, Gibbs]
tags: [module-3, key]
---

# Filter theory: what a filter is, and why frequency is its language

Code: [[code-30-08-filter-theory|`R/30-08-filter-theory.R`]]

Modules 2 and 4 both build filters — X-11 by assembling moving averages, SEATS by deriving one from a model. This note collects the general theory underneath both. Nothing here is specific to seasonal adjustment; all of it is standard linear systems theory, which is why the same vocabulary turns up in engineering, and why borrowing their results is legitimate.

Read it after [[30-05-filters-in-the-frequency-domain]] if you want the applications first, or before it if you prefer the general case first.

## What forces a filter to be a weighted sum

Start with two assumptions, both modest:

- **Linear.** Doubling the input doubles the output; adding two inputs adds their outputs.
- **Time-invariant.** Delay the input by three months and the output is the same, delayed by three months. The filter has no calendar of its own.

Those two assumptions *alone* force the filter to be a convolution:

$$y_t = \sum_{j=-\infty}^{\infty} w_j\, x_{t-j}$$

There is no third possibility. Every filter in this vault — every moving average, every Henderson, every Wiener–Kolmogorov filter — is of this form because it is linear and time-invariant, not because anyone chose the form.

<!-- run -->
```r
source("R/30-08-filter-theory.R")
```
```text
=== 1. LTI forces the convolution form ===
  linearity  : max |F(ax+by) - aF(x) - bF(y)| = 1.065814e-14 
  invariance : max |shift(F(x)) - F(shift(x))| = 0 

=== 2. complex exponentials are EIGENFUNCTIONS ===
Feed in e^{i w t}; get back the SAME function, scaled by a complex number.
That scalar is the transfer function. This one fact is why the frequency
domain is the natural coordinate system for filters.

  f = 0.0833 : output/input constant? sd = 9.90e-16   ratio = +0.84562   H(f) = +0.84562
  f = 0.1667 : output/input constant? sd = 3.32e-15   ratio = +0.10949   H(f) = +0.10949
  f = 0.3000 : output/input constant? sd = 9.76e-15   ratio = +0.01890   H(f) = +0.01890

=== 3. gain = |H|, phase = arg(H) ===
  freq      gain(sym)  phase(sym)   gain(1-sided)  phase(1-sided)
  0.0000    1.00000     0.00000        1.00000         0.00000
  0.0833    0.00000    -0.00007        0.57929         0.13318
  0.1667    0.00000     3.14159        0.07692         3.14159
  0.2500    0.00000     0.00000        0.17201        -2.67795
  0.5000    0.00000     0.00000        0.07692         3.14159
  Symmetric: phase identically 0 or pi -- no cycle is moved in time.
  One-sided: phase varies with frequency -- different cycles shift by
  different amounts, which is how end filters displace turning points.

... [50 more lines]
```
<!-- end -->

The script checks both properties directly on a Henderson filter and finds them to machine precision.

> [!important] Where the assumption fails
> X-11's extreme-value replacement is **not** linear — the weights depend on the data ([[20-06-extreme-values]]). So X-11 as a whole is not an LTI filter, and its "composite filter" is only the linear part. That is why 20-05 recovers the composite by feeding in an impulse *with extreme-value handling off*.

## The one fact everything rests on

Feed a complex exponential $x_t = e^{i\omega t}$ into any LTI filter. What comes out?

$$y_t = \sum_j w_j e^{i\omega(t-j)} = e^{i\omega t}\underbrace{\sum_j w_j e^{-i\omega j}}_{\text{a number}} = H(\omega)\,e^{i\omega t}$$

**The same function comes back, multiplied by a number.** Complex exponentials are *eigenfunctions* of every LTI filter, and $H(\omega)$ is the corresponding eigenvalue — the **transfer function**.

That is the entire reason the frequency domain is the natural coordinate system here. In the time domain a filter is a convolution, which is awkward. In the frequency domain it is *multiplication by a number, one frequency at a time*. Every hard question becomes easy in these coordinates, which is why Modules 3 and 4 are written in them at all.

| Input frequency | output/input constant? | measured ratio | $H(f)$ |
|---|---|---|---|
| $1/12$ | sd $\approx 10^{-15}$ | $0.84562$ | $0.84562$ |
| $1/6$ | sd $\approx 10^{-15}$ | $0.10949$ | $0.10949$ |
| $0.3$ | sd $\approx 10^{-14}$ | $0.01890$ | $0.01890$ |

The ratio really is constant along the whole series, and it really does equal $H$.

## Gain and phase are just modulus and argument

$H(\omega)$ is a complex number, so it has a size and a direction:

$$\text{gain} = |H(\omega)|, \qquad \text{phase} = \arg H(\omega)$$

**Gain** says how much a cycle at that frequency is amplified or suppressed. **Phase** says how far it is shifted in time. That is all the notation means.

For a **symmetric** filter ($w_j = w_{-j}$) the sines cancel in pairs, $H$ is real, and the phase is 0 or $\pi$ — nothing is moved in time ([[derivations#D11. Why a symmetric filter has zero phase, and an end filter does not|D11]]). For a one-sided filter the phase varies with frequency, and *different cycles get shifted by different amounts*.

## Group delay: the shift, in months

Phase in radians is hard to interpret. Convert it to a time shift:

$$\text{group delay}(\omega) = -\frac{d\,\arg H(\omega)}{d\omega}$$

Measured on a 13-term Henderson and its crude one-sided version:

| Period | gain (sym) | delay (sym) | gain (1-sided) | delay (1-sided) |
|---|---|---|---|---|
| 60 months | 0.9997 | $-0.000$ | 1.0027 | $-2.240$ |
| 36 months | 0.9974 | $-0.000$ | 1.0067 | $-2.183$ |
| 24 months | 0.9875 | $-0.000$ | 1.0117 | $-2.088$ |
| 18 months | 0.9632 | $-0.000$ | 1.0130 | $-1.984$ |

The symmetric filter delays **nothing**, at any frequency. The one-sided filter delays by about two months — roughly half its length — and, crucially, **by a different amount at each frequency**.

> [!warning] Why you cannot just subtract the lag off
> If the delay were the same at every frequency you could shift the output back and be done. It is not: 2.24 months at period 60, 1.98 at period 18. A series is a mixture of frequencies, so there is no single correction. **This is the precise reason a concurrent trend estimate lags, and why the lag cannot be tidied away** ([[20-07-end-filters]]).

> [!note] Group delay is undefined where the gain is zero
> At a filter's zero the phase jumps by $\pi$ and the derivative is meaningless — a numerical group delay there returns garbage, not infinity. My first version of the script evaluated it at $f = 1/12$ on the $2\times12$ filter, which is exactly a zero, and got $\pm 2500$. Evaluate group delay only where the gain is appreciable.

## The algebra: cascades multiply

Run one filter, then another. The transfer functions **multiply**:

$$H_{\text{cascade}}(\omega) = H_1(\omega)\,H_2(\omega)$$

so the gains multiply and the phases add. Verified:

| Frequency | gain(cascade) | gain(3)$\times$gain(5) |
|---|---|---|
| $1/12$ | 0.679743 | 0.679743 |
| $1/5$ | 0.000000 | 0.000000 |
| $1/3$ | 0.000000 | 0.000000 |

This is the fact that makes X-11 analysable at all. X-11 is a *chain* of simple filters — a $2\times12$, a seasonal MA, a Henderson, another seasonal MA — and rather than reasoning about the loop you multiply four transfer functions ([[20-05-the-x11-iteration]]). Parallel branches, similarly, add.

## Why the weights sum to one

Every filter in this vault has weights summing to 1, usually stated as a convention. It is not one:

$$H(0) = \sum_j w_j e^{-i\cdot 0\cdot j} = \sum_j w_j$$

**Gain at frequency zero *is* the sum of the weights.** A filter whose weights summed to 1.05 would multiply a flat series by 1.05 — it would change the level of the data. So "weights sum to 1" and "constants pass through untouched" are the same statement, and the script confirms the two quantities agree to ten decimals for four different filters.

## FIR and IIR: why SEATS filters are not moving averages

| | **FIR** (finite impulse response) | **IIR** (infinite impulse response) |
|---|---|---|
| Form | finitely many weights | a **ratio** of polynomials |
| Examples | every X-11 moving average | every Wiener–Kolmogorov filter |
| Stability | automatic | needs roots outside the unit circle |
| How to apply | convolve | truncate, **or** recurse |

This distinction explains the shape of Module 4. A WK filter is $f_s/f_z$ — a ratio — so its weight sequence never terminates. You have two options, and the vault does both:

1. **Truncate** the weights and extend the series so the truncation does not bite. That is `seats_decompose()`, and it needs 331 weights ([[30-07-finite-samples]]).
2. **Recurse** — run the ratio as a difference equation, exactly. That is [[40-09-burman-algorithm]], and it needs 14 coefficients.

Option 2 is available *because* the filter is IIR. You cannot recurse an FIR filter into fewer operations; there is nothing to recurse.

## The brick wall you cannot build

The ideal seasonal filter would have gain exactly 1 everywhere except exactly 0 at the seasonal frequencies. Why not just build it?

> [!tip] A red herring worth naming
> An ideal *notch* — gain 1 except zero at six isolated points — is vacuous. Isolated points have measure zero, so its Fourier coefficients are identical to those of the identity filter. The real constraint appears with an ideal **low-pass**: gain 1 below a cutoff, 0 above.

Truncating the ideal low-pass at half-length $L$:

| Half-length | passband overshoot | transition width | max stopband gain |
|---|---|---|---|
| 12 | 6.36% | 0.0357 | 0.0772 |
| 24 | 9.94% | 0.0178 | 0.0267 |
| 48 | 8.78% | 0.0091 | 0.0221 |
| 96 | 8.87% | 0.0047 | 0.0111 |
| 192 | 8.81% | 0.0023 | 0.0062 |
| 384 | **9.01%** | 0.0012 | 0.0022 |

Read the two middle columns against each other. The **transition width halves every time $L$ doubles** — lengthening the filter really does buy a sharper edge, cleanly like $1/L$. But the **overshoot does not shrink**. It settles near **9%** and stays there forever.

That is **Gibbs' phenomenon**: you can buy sharpness with length, but you can never buy a clean edge. The overshoot converges to a fixed fraction (about 8.9%) of the jump, no matter how many weights you spend.

The consequence for this subject is not a technicality:

> [!important] Every seasonal filter is a compromise, not an approximation
> There is no ideal filter being approached from below. The perfect notch is *unbuildable in principle*, not merely expensive. So the design question is never "how close to ideal" but "which trade-off" — sharper notches versus more ripple, faster response versus more smoothness. X-11 answers it one way with fixed filters chosen by data-dependent rules; SEATS answers it another way by deriving the trade-off from a model ([[50-09-x11-vs-seats]]).

## Where each idea is used

| Idea | Where it does work |
|---|---|
| LTI $\Rightarrow$ convolution | every filter in Modules 2 and 4 |
| eigenfunction property | the whole frequency-domain approach |
| gain | [[20-02-the-12-term-ma]], [[20-03-henderson-filters]] |
| phase / group delay | [[20-07-end-filters]], [[50-06-turning-points]] |
| cascades multiply | [[20-05-the-x11-iteration]] |
| $\sum w_j = H(0)$ | every filter's normalisation |
| FIR vs IIR | [[30-07-finite-samples]], [[40-09-burman-algorithm]] |
| Gibbs | [[30-05-filters-in-the-frequency-domain]] |

## Exercises

*Solutions: [[solutions#30-08-filter-theory|worked answers]] in the solutions appendix.*

1. Verify linearity and time-invariance for a filter of your choice, as the script does. Then break linearity deliberately (say, clip the input at some threshold first) and watch the check fail.
2. Feed $e^{i\omega t}$ through a filter by hand for three frequencies and confirm the output/input ratio is constant along the series.
3. Compute the group delay of the one-sided Henderson at several frequencies. How much does it vary? Would a single constant correction fix it?
4. Confirm that cascading a 3-term and a 5-term average gives a filter whose gain is the product of theirs, and find the frequencies where the cascade is exactly zero.
5. Build an ideal low-pass at half-length 24, 96 and 384. Confirm the transition narrows like $1/L$ while the overshoot does not.
6. Take the X-11 composite gain from [[20-05-the-x11-iteration]] and compare its ripple with the truncated ideal filter's. Which trade-off did X-11's designers choose?
7. Explain, in one sentence each, why a symmetric filter has zero phase and why an end filter cannot.

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** Will cascading two zero-phase filters give a zero-phase filter? Argue it from the algebra before testing.
2. **Break it.** Construct a filter with a deliberate 3-month delay and confirm the group delay reports it.
3. **Transfer.** Apply the LTI test to X-11 *with* extreme-value replacement on. Which of the two properties fails, and at what magnitude of outlier?

## Practice set

*Drills, output-reading and judgement calls. Short answers; the point is fluency and knowing what you are looking at.*

1. **Drill.** Compute gain and phase for a symmetric and a one-sided filter at four frequencies.
2. **Drill.** Confirm $\sum w_j = H(0)$ for four different filters.
3. **Read it.** A filter's phase is $\pi$ at some frequency. What is it doing to that cycle?
4. **Read it.** Group delay is $-2.2$ periods at one frequency and $-1.9$ at another. Why does that matter?
5. **Judgement.** You are told a filter is 'ideal'. What do you ask next?

## Links

- Prev: [[30-07-finite-samples]] · Module map: [[30-00-spectral-map]]
- Applications: [[30-05-filters-in-the-frequency-domain]], [[20-05-the-x11-iteration]], [[40-09-burman-algorithm]]
- Algebra: [[derivations#D11. Why a symmetric filter has zero phase, and an end filter does not|D11]], [[derivations#D6. The spectral density, and the ARMA formula|D6]]
