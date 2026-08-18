---
aliases: [Canonical decomposition, Hillmer-Bell, Maximum irregular]
tags: [module-4, key]
---

# The canonical decomposition

Code: `R/40-03-canonical-decomposition.R`

The convention that makes SEATS's answer unique. Hillmer & Bell (1982), Bell & Hillmer (1984).

## The problem it solves

[[30-06-wiener-kolmogorov]] established that the split is **not identified by the data**. Concretely: if $(f_T, f_S, f_I)$ is a valid decomposition of $f_z$, then so is

$$\big(f_T - c,\ f_S,\ f_I + c\big)$$

for any constant $c$ — you have moved white noise from the trend to the irregular. Both sum to $f_z$; both fit identically; the data cannot choose. And the same holds for the seasonal.

So there is a whole family of decompositions, parameterised by how much white noise you leave in each component. Something other than the data must pick one.

## The rule

> [!important] The canonical decomposition
> **Give the irregular as much variance as possible.**
>
> Equivalently: subtract from each component the **minimum of its spectrum over frequency**, and add all of it to the irregular.
>
> $$f_T^{\text{can}} = f_T - \min_\omega f_T, \qquad f_S^{\text{can}} = f_S - \min_\omega f_S$$
> $$f_I^{\text{can}} = f_I + \min_\omega f_T + \min_\omega f_S$$

You cannot subtract more than the minimum without making a spectrum negative, so this is the extreme point of the admissible family — the reason the answer is unique.

## Why choose *that* extreme

Three defences, in increasing order of how much they should convince you:

1. **It is well defined.** The minimum exists and is unique. Any other rule needs an arbitrary tuning constant.
2. **It makes the components as smooth and stable as possible.** All the "white noise" that could belong to either has been swept into the irregular, so the trend and seasonal contain only what is unambiguously theirs. A trend with white noise left in it would wiggle for no reason.
3. **It is conservative about what you claim to have found.** Any variance that *might* be noise **is** called noise. The signal you report is the part that cannot be anything else.

Point 3 is the real argument. The alternative — leaving noise in the trend — means asserting structure the data cannot support.

## The consequence that confuses everyone

Subtracting the minimum makes each component's spectrum **touch zero** at the frequency where the minimum occurred.

And a spectrum that touches zero is exactly a component with a **unit MA root** — non-invertible ([[10-05-invertibility]]).

> [!warning] Canonical components are non-invertible by construction
> Your ARIMA training says a unit MA root is a symptom of over-differencing — a mistake to fix. In SEATS it is the **goal**, and every canonical component has one.
>
> If your implementation reports a unit MA root in the trend or seasonal, that is not a bug. It is the definition.

Where do the zeros land? The canonical trend's spectrum touches zero at $\omega=\pi$ (the highest frequency — a trend should contain nothing there). The canonical seasonal touches zero *between* the seasonal frequencies.

## Worked, on AirPassengers

Fitted $\theta = 0.4018$, $\Theta = 0.5569$. The partial fractions give component spectra whose minima are:

$$\min_\omega f_T = 0.0514, \qquad \min_\omega f_S = 0.0225$$

The canonical step strips both out:

| | Before | After |
|---|---|---|
| trend, minimum | 0.0514 | **0** |
| seasonal, minimum | 0.0225 | **0** |
| irregular (constant) | 0.2238 | **0.2238 + 0.0514 + 0.0225 = 0.2977** |

So about **25% of the irregular's variance was moved out of the trend and seasonal** by the canonical rule. That is not a rounding detail; it materially changes how smooth the reported trend is.

## In filter terms

The canonical adjustment is a simple modification of the numerators from [[40-04-partial-fractions-in-b-and-f]]:

$$\nu_T^{\text{can}} = \frac{(A - m_T D_T)\,D_S}{N}, \qquad \nu_S^{\text{can}} = \frac{(C - m_S D_S)\,D_T}{N}$$
$$\nu_I^{\text{can}} = \frac{(D + m_T + m_S)\,D_TD_S}{N}$$

with $m_T,m_S$ the two minima. They still sum to 1 — the same numerator identity, with the shifted terms cancelling.

## Is it the right convention?

It is a choice, and worth holding at arm's length.

- The canonical trend is the **smoothest** trend consistent with the model. If you believe the true trend is noisier, you will find SEATS trends too smooth — a common complaint.
- Different conventions give different components from the *same fitted model and the same data*. Two analysts can both be right and disagree.
- X-11 makes no such choice explicitly, but its fixed filters embody one implicitly. Comparing them ([[50-09-x11-vs-seats]]) is partly comparing conventions, not just methods.

The honest summary: the canonical decomposition is a defensible, well-defined, conservative convention — not a discovered truth about the series.

## Exercises

1. Compute $m_T$ and $m_S$ for `AirPassengers` and reproduce the table above.
2. Plot each component's spectrum before and after the canonical shift. Confirm the minima move to zero.
3. Find the frequency at which the canonical trend's spectrum touches zero. Is it $\pi$?
4. Decompose with and without the canonical step and plot both trends. Which is smoother, and by how much (compare the variance of the first difference)?
5. Confirm the canonical filters still sum to 1.
6. Across the catalogue, which series has the largest $m_T + m_S$ — i.e. for which does the canonical rule move the most variance?

## Links

- Prev: [[40-02-admissible-decompositions]] · Next: [[40-04-partial-fractions-in-b-and-f]]
- Why a convention is needed: [[30-06-wiener-kolmogorov]] · Unit MA roots: [[10-05-invertibility]]
