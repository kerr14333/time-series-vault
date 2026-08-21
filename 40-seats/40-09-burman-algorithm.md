---
aliases: [Burman, Burman's algorithm, Exact signal extraction]
tags: [module-4, key]
---

# Burman's algorithm, worked through slowly

Code: [[code-40-09-burman-algorithm|`R/40-09-burman-algorithm.R`]]

This note assumes only Modules 1 and 3. It goes slowly on purpose.

## The problem, stated plainly

By [[30-06-wiener-kolmogorov]] the best estimate of the seasonal component is

$$\hat s_t = \nu_S(B,F)\, z_t$$

where $\nu_S$ is a **two-sided infinite** filter — it wants data stretching infinitely far into the past *and the future*.

You do not have infinite data. You have 144 months. So what do you do?

Our `seats_decompose()` takes the obvious route: chop the filter off once the weights get small, extend the series with ARIMA forecasts so the chopped filter has something to chew on, and accept the tiny error. It works, and it validates against the Census binary to 0.001%. But look at the cost:

> [!warning] The brute-force route is expensive
> For the airline model with $\Theta = 0.557$, the weights do not fall below $10^{-7}$ until lag **331** — that is **27.6 years** of filter, applied to a series only 12 years long ([[30-07-finite-samples]]). You must forecast 27 years in each direction and hope.

Burman (1980) does the same job **exactly**, with two short loops. It is the algorithm inside SEATS, and it is much simpler than its reputation.

## The idea, in one sentence

> A symmetric filter can be split into a **backward-looking half** and a **forward-looking half**, and each half is an ordinary recursion.

That is the whole thing. The rest is bookkeeping.

## Step 1 — notice the filter is a fraction

Write the model as $\phi(B)z_t = \theta(B)a_t$. From [[40-06-wk-filters-for-the-airline-model]], the seasonal filter is

$$\nu_S(B,F) = \frac{W(B,F)}{\theta(B)\,\theta(F)}$$

where $W$ is a polynomial in both $B$ and $F$. The important part is the **denominator**: it is $\theta(B)\theta(F)$ — the MA polynomial, once forwards and once backwards.

For the airline model $\theta(B) = (1-\theta B)(1-\Theta B^{12})$, degree 13, with nonzero coefficients only at lags 0, 1, 12 and 13.

<!-- run -->
```r
source("R/40-09-burman-algorithm.R")
bp <- burman_pieces(0.4018, 0.5569)
cat("theta(B) degree:", length(bp$ma) - 1,
    "  nonzero at lags:", which(abs(bp$ma) > 1e-12) - 1, "\n")
cat("numerator W(B,F) reaches lag:", length(bp$W_seas) - 1, "\n")
```
```text
theta(B) degree: 13   nonzero at lags: 0 1 12 13 
numerator W(B,F) reaches lag: 13 
```
<!-- end -->

## Step 2 — remember partial fractions from calculus

In first-year calculus you learned to split

$$\frac{1}{(x-1)(x-2)} = \frac{-1}{x-1} + \frac{1}{x-2}$$

Same move here, except the two "factors" are $\theta(B)$ and $\theta(F)$:

$$\frac{W(B,F)}{\theta(B)\theta(F)} \;=\; \underbrace{\frac{g(B)}{\theta(B)}}_{\text{uses the past}} \;+\; \underbrace{\frac{g(F)}{\theta(F)}}_{\text{uses the future}}$$

The same $g$ appears in both halves, because the filter is symmetric — the past and the future are treated identically.

**Finding $g$ is just linear algebra.** Multiply through by $\theta(B)\theta(F)$:

$$W(B,F) = g(B)\theta(F) + g(F)\theta(B)$$

Both sides are polynomials. Match the coefficient of $B^k$ on each side for $k = 0, 1, \dots, q$ and you get $q+1$ linear equations in the $q+1$ unknowns $g_0,\dots,g_q$. Solve. Done.

<!-- run -->
```r
g <- burman_g(bp$W_seas, bp$ma)
cat("g has", length(g), "coefficients\n")
round(head(g, 6), 5)
```
```text
g has 14 coefficients
[1]  0.10533 -0.05639 -0.01279 -0.01227 -0.01174 -0.01122
```
<!-- end -->

Fourteen numbers. That is the entire filter — compare with 331 weights for the brute-force version.

> [!tip] Always check the split before trusting it
> The identity above must hold at every frequency. Substituting $B = e^{-i\omega}$ turns it into an ordinary numeric check, and the script does exactly that: the two sides agree to about $7\times10^{-15}$. If you get this wrong, everything downstream is quietly wrong.

## Step 3 — each half is a recursion you can run

Look at the backward-looking half. Define $u_t$ by

$$u_t = \frac{g(B)}{\theta(B)}z_t \qquad\Longleftrightarrow\qquad \theta(B)\,u_t = g(B)\,z_t$$

Write that out with $\theta(B) = 1 - \theta_1 B - \theta_2 B^2 - \cdots$:

$$u_t - \theta_1 u_{t-1} - \cdots - \theta_q u_{t-q} \;=\; g_0 z_t + g_1 z_{t-1} + \cdots + g_q z_{t-q}$$

Rearrange to put $u_t$ alone:

$$\boxed{\;u_t = \sum_{j=0}^{q} g_j z_{t-j} \;+\; \sum_{i=1}^{q}\theta_i u_{t-i}\;}$$

**This is just a loop.** Walk forward through the series; at each step take a weighted sum of recent $z$'s and recent $u$'s. Fourteen multiplications per observation.

The forward-looking half is the identical loop run **backwards** through the series. Then

$$\hat s_t = u_t + v_t$$

That is Burman's algorithm.

> [!important] Why the recursion is stable
> A recursion that feeds its own output back can explode. This one cannot, because $\theta(B)$ is **invertible** — all its roots lie outside the unit circle ([[10-05-invertibility]]) — so the feedback coefficients shrink what they act on. Invertibility was introduced in Module 1 as a bookkeeping convention. Here it is the reason the algorithm terminates with a finite answer. That is not a coincidence: the same condition guarantees the WK filter has no poles on the circle ([[derivations#D10. Why the WK filters have no poles|D10]]).

## Step 4 — does it actually work?

Two independent checks. First, feed pure cosines through the two recursions and measure the output amplitude. If the loops really implement $\nu_S$, the measured gain must match the formula at every frequency:

| Frequency | measured gain | $\nu_S$ |
|---|---|---|
| $\approx 0$ (trend) | 0.00000 | 0.00000 |
| $1/12$ (annual) | 1.00000 | 1.00000 |
| $1/6$ | 1.00000 | 1.00000 |
| $0.2$ (not seasonal) | 0.02094 | 0.02094 |
| $0.5$ (Nyquist) | 1.00000 | 1.00000 |

Exact at every frequency, including **zero gain at the trend frequency** and **gain one at each seasonal frequency**. The loops are the filter.

Second, run it on real data and compare with the brute-force version:

<!-- run -->
```r
ref <- as.numeric(seats_decompose(AirPassengers, 0.4018, 0.5569,
                                  normalize = FALSE)$seasonal)
for (E in c(24, 120, 240)) {
  b <- burman_component(as.numeric(lap), 0.4018, 0.5569,
                        which = "seasonal", extend = E)
  cat(sprintf("  run-up %3d months : max difference %.7f\n", E, max(abs(b - ref))))
}
```
```text
  run-up  24 months : max difference 0.2630249
  run-up 120 months : max difference 0.0027118
  run-up 240 months : max difference 0.0000088
```
<!-- end -->

Agreement to $10^{-5}$ — the same answer, from fourteen coefficients instead of 331 weights.

## What is still approximate here, and why

The version above starts both recursions from **zero**, which is wrong at the very first step: $u_1$ should already reflect the history before the sample. That error decays as the recursion runs, so I give it run-up room by extending the series — and you can see it decay in the table above, from $0.26$ at 24 months to $10^{-5}$ at 240.

**Burman's published algorithm does not need that.** It derives exact starting values from the model, which removes the run-up entirely and needs only $q$ forecasts rather than hundreds. That derivation is the one piece this script leaves out, and it is why the real thing is exact rather than merely convergent.

> [!note] The honest summary
> The *idea* here — split by partial fractions, run two recursions — is all of Burman. The *engineering* is in the starting values. A teaching implementation can skip the second part and still show you why the first part works.

## Why this matters beyond speed

Speed is the least interesting benefit.

1. **No tolerance to choose.** The brute-force route makes you pick a truncation lag. Pick it badly and you get a *constant offset* in the answer — not noise, a bias, which correlates at 0.999 with the truth and is uniformly wrong ([[30-07-finite-samples]]). Burman has no such knob.
2. **It works at the ends.** The recursions run right up to the last observation without a special case, which is where seasonal adjustment is hardest ([[20-07-end-filters]]).
3. **It generalises.** Nothing above used the airline model specifically. Any invertible $\theta(B)$ gives a $g$ and two loops.

![[40-09-burman-vs-truncation.png]]

*Drawn by [[figure-index#40-09-burman-vs-truncation.png|`make-figures.R`]] — code and every other figure in the [[figure-index|figure appendix]].*

**Left:** the WK seasonal filter weights out to lag 120, on a log scale, with year boundaries marked. The spikes sit at multiples of 12 — the filter reaches back through *the same month in previous years*, which is exactly what a seasonal filter should do. And after ten years they are still visibly nonzero.

**Right:** the consequence. As $\Theta$ rises the filter needs more and more history: past $\Theta \approx 0.4$ it already wants more filter than `AirPassengers` has data, and at $\Theta = 0.95$ it wants **50 years**. The dashed line is the length of the series itself.

That gap between the two lines is the whole argument for Burman's algorithm. You cannot supply 50 years of data; you can run two recursions.

## Exercises

*Solutions: [[solutions#40-09-burman-algorithm|worked answers]] in the solutions appendix.*

1. Solve $W(B,F) = g(B)\theta(F) + g(F)\theta(B)$ by hand for a plain MA(1), $\theta(B) = 1-\theta B$, with $W = 1$. You should get two equations in $g_0, g_1$.
2. Confirm the partial-fraction identity numerically on the unit circle, as the script does. Then deliberately perturb one coefficient of $g$ and watch the check fail.
3. Feed a pure cosine at $\omega = 2\pi/12$ through the two recursions and confirm the output amplitude is 1. Try $\omega=0$ and confirm it is 0.
4. Run the recursions with **no** extension at all. How many observations at each end are visibly wrong, and how does that compare with the length of $g$?
5. Apply the same machinery to the **trend** filter (`which = "trend"`). Confirm the trend and seasonal estimates sum to the series minus the irregular.
6. Time both methods on a long series. Where does the brute-force cost actually go — the filter, or the forecasting?

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** How long must $g$ be for a quarterly airline model? Reason from the MA degree before computing.
2. **Break it.** Perturb one coefficient of $g$ by 1% and check both the unit-circle identity and the decomposition. Which detects it first?
3. **Transfer.** Run the recursions on a series with an AR term in the model. Does the method care?

## Links

- Prev: [[40-08-validating-against-x13]] · Module map: [[40-00-seats-map]]
- Needs: [[30-06-wiener-kolmogorov]], [[30-07-finite-samples]], [[10-05-invertibility]]
- Algebra: [[derivations#D8. The Wiener–Kolmogorov filter|D8]], [[derivations#D10. Why the WK filters have no poles|D10]]
