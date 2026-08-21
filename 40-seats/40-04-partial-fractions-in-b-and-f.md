---
aliases: [Partial fractions, Partial fractions in B and F, The SEATS algebra]
tags: [module-4, key]
---

# Partial fractions in $B$ and $F$

Code: [[code-40-04-partial-fractions-in-b-and-f|`R/40-04-partial-fractions-in-b-and-f.R`]]

The mechanical core of SEATS. It is the partial fractions you did in calculus, applied to the pseudo-spectrum. Nothing harder — but the bookkeeping needs care, so this note does it with actual numbers.

## The goal

From [[30-04-pseudo-spectrum]], the airline model's pseudo-spectrum is a ratio:

$$f_z(\omega) \;=\; \frac{\sigma_a^2}{2\pi}\cdot\frac{\overbrace{|\theta(e^{-i\omega})\Theta(e^{-12i\omega})|^2}^{N(\omega)}}{\underbrace{|(1-e^{-i\omega})^2|^2}_{D_T(\omega)}\cdot\underbrace{|S(e^{-i\omega})|^2}_{D_S(\omega)}}$$

We want to split it into one term per component:

$$\frac{N}{D_T D_S} \;=\; \underbrace{\frac{A}{D_T}}_{\text{trend}} \;+\; \underbrace{\frac{C}{D_S}}_{\text{seasonal}} \;+\; \underbrace{D}_{\text{irregular}}$$

Because $f_T = f_S + f_I$ additivity is exactly what [[30-02-spectral-density]] guarantees for independent components, splitting the spectrum **is** splitting the series.

## Everything is a cosine polynomial

The one representational trick that makes this easy.

$|P(e^{-i\omega})|^2$ is real, even, and non-negative. Any such function can be written

$$p(\omega) = c_0 + 2\sum_{k\ge1} c_k\cos(k\omega)$$

and for $|P(e^{-i\omega})|^2$ the $c_k$ are simply the **autocovariances of the coefficient sequence of $P$**:

$$c_k = \sum_j p_j\,p_{j+k}$$

So `cospoly_from_poly(c(1,-0.4))` returns $(1.16,\ -0.4)$, meaning $1.16 - 0.8\cos\omega$. Check: $|1-0.4e^{-i\omega}|^2 = 1 + 0.16 - 0.8\cos\omega$. ✓

Storing everything as the vector $(c_0,c_1,\dots,c_n)$ turns the whole problem into linear algebra over real vectors — no complex arithmetic anywhere.

## The degree bookkeeping

For the airline model with $s=12$:

| Object | Polynomial | Cosine-poly degree |
|---|---|---|
| $N$ | $\|(1-\theta B)(1-\Theta B^{12})\|^2$, MA degree 13 | **13** |
| $D_T$ | $\|(1-B)^2\|^2$ | **2** |
| $D_S$ | $\|S(B)\|^2$, $S$ degree 11 | **11** |
| $D_T D_S$ | | **13** |

Partial fractions requires each numerator to have degree strictly below its denominator, plus a polynomial part for the improper bit:

$$\deg A \le 1,\qquad \deg C \le 10,\qquad \deg D = 13 - 13 = 0$$

Count the unknowns: $A$ has 2 coefficients, $C$ has 11, $D$ has 1. **Fourteen.** And $N$ has 14 cosine coefficients (degrees 0 to 13). Fourteen equations, fourteen unknowns — a square system, uniquely solvable.

That the counts match exactly is not luck. It is why the decomposition is well-posed at all.

## Solving it

Multiply through by $D_TD_S$ to clear denominators:

$$\boxed{\,N(\omega) \;=\; A(\omega)D_S(\omega) \;+\; C(\omega)D_T(\omega) \;+\; D\cdot D_T(\omega)D_S(\omega)\,}$$

This is an identity between cosine polynomials, so it holds coefficient by coefficient — a linear system in the unknowns.

The implementation solves it the lazy way: evaluate both sides on a fine grid of $\omega$ and solve the resulting (over-determined but exactly consistent) linear system by QR. Since it is a polynomial identity, "least squares" returns the exact answer.

> [!important] The check that proves it worked
> Residual of the identity on `AirPassengers` ($\theta=0.4018$, $\Theta=0.5569$):
> $$\max_\omega \left|N - (AD_S + CD_T + D\,D_TD_S)\right| \;=\; 6.1\times10^{-14}$$
> That is machine precision. If your residual is not at that level, the degree bookkeeping is wrong — recount before doing anything else.

SEATS does this algebraically rather than numerically, but it is the same identity.

## The answer, for AirPassengers

Solving gives the three component spectra. Their minima over frequency:

| Component | $\min_\omega$ of its spectrum |
|---|---|
| trend $A/D_T$ | $0.0514$ |
| seasonal $C/D_S$ | $0.0225$ |
| irregular $D$ | $0.240$ (constant) |

All three are **non-negative**, so this model is admissible ([[40-02-admissible-decompositions]]). Those two minima are exactly what the canonical step will strip out and hand to the irregular ([[40-03-canonical-decomposition]]).

![[40-04-spectrum-split.png]]

*Drawn by [[figure-index#40-04-spectrum-split.png|`make-figures.R`]] — code and every other figure in the [[figure-index|figure appendix]].*

The total pseudo-spectrum (black) and its three pieces. The trend owns the pole at 0, the seasonal owns the six seasonal poles, and the irregular is the flat floor. The partial fractions are just this picture, written algebraically.

## Why the filters end up pole-free

Worth noticing, because it makes implementation far easier than the theory suggests. The WK filter is

$$\nu_T = \frac{f_T}{f_z} = \frac{A/D_T}{N/(D_TD_S)} = \frac{A\,D_S}{N}$$

**$D_T$ cancels.** The infinite peaks of [[30-04-pseudo-spectrum]] are in *both* numerator and denominator and divide out exactly. So although $f_T$ and $f_z$ are individually infinite at $\omega=0$, the filter $\nu_T$ is an ordinary smooth function — the ratio-of-infinities argument, made concrete.

Likewise $\nu_S = C\,D_T/N$ and $\nu_I = D\,D_TD_S/N$. And summing them:

$$\nu_T+\nu_S+\nu_I = \frac{AD_S + CD_T + D\,D_TD_S}{N} = \frac{N}{N} = 1$$

by the boxed identity. **The filters sum to 1 for the same reason the partial fractions work.** Verified numerically at $7\times10^{-12}$.

## Exercises

*Solutions: [[solutions#40-04-partial-fractions-in-b-and-f|worked answers]] in the solutions appendix.*

1. Verify `cospoly_from_poly(c(1,-0.4))` equals $(1.16,-0.4)$ by hand.
2. Recount the degrees for a *quarterly* airline model ($s=4$): what are $\deg N$, $\deg D_T$, $\deg D_S$, and how many unknowns? Confirm the system is still square.
3. Solve the system for `AirPassengers` and reproduce the $6\times10^{-14}$ residual.
4. Deliberately mis-set $\deg C$ to 11 instead of 10. What happens to the residual, and why?
5. Confirm $\nu_T+\nu_S+\nu_I=1$ numerically, and that each is finite at $\omega=0$ despite $f_z$ being infinite there.

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** How many unknowns will the quarterly system have, against the monthly one? Count before solving.
2. **Break it.** Set one numerator degree wrong and watch the residual. How many orders of magnitude does it move?
3. **Transfer.** Solve the system for a model with an AR term and confirm the residual stays near $10^{-12}$.

## Links

- Prev: [[40-03-canonical-decomposition]] · Next: [[40-05-component-models]]
- Foundation: [[30-03-spectrum-of-an-arma]], [[30-04-pseudo-spectrum]]
