---
aliases: [Lag operator, Backshift operator, B]
tags: [module-1]
---

# The lag operator $B$

Code: [[code-10-01-lag-operator|`R/10-01-lag-operator.R`]]

## The definition

$$B z_t = z_{t-1}, \qquad B^k z_t = z_{t-k}, \qquad B^0 = 1$$

That is all it is: "shift back one period". Some books write $L$ for *lag*; Box–Jenkins and the entire seasonal-adjustment literature write $B$ for *backshift*. Same thing.

The forward operator is its inverse: $F = B^{-1}$, $F z_t = z_{t+1}$. You will meet $F$ in [[30-00-spectral-map|Module 3]], because signal-extraction filters are two-sided — they use past *and* future.

## The one idea that makes everything else work

**$B$ behaves like an ordinary algebraic variable.** You can multiply, factor, expand, and (carefully) divide polynomials in $B$, and the answer means what you would hope.

Example. What is $(1-B)(1-B^{12})$?

$$(1-B)(1-B^{12}) = 1 - B - B^{12} + B^{13}$$

Apply that to $z_t$:

$$z_t - z_{t-1} - z_{t-12} + z_{t-13}$$

So "difference, then seasonally difference" is a four-term recipe, and — because polynomial multiplication commutes — **the order does not matter**. Seasonally differencing first gives the identical series. That commutativity is not obvious from the recipe; it is obvious from the algebra. That is why we use the algebra.

Do not take that on faith — expand it:

<!-- run -->
```r
# (1 - B)(1 - B^12), multiplied out
poly_show(poly_mult(c(1, -1), diff_poly(D = 1)))
```
```text
[1] "1 - B - B^12 + B^13"
```
<!-- end -->

And check the commutativity claim on real data, both orders:

<!-- run -->
```r
a <- diff(diff(lap, lag = 1),  lag = 12)   # difference, then seasonally difference
b <- diff(diff(lap, lag = 12), lag = 1)    # the other way round
c(same_length = length(a) == length(b), max_gap = max(abs(a - b)))
```
```text
same_length     max_gap 
          1           0 
```
<!-- end -->

Identical to the last bit, which is what "commutes" buys you.

> [!tip] The habit to build
> Whenever an expression in $B$ confuses you, expand it and apply it to $z_t$ term by term. Every polynomial in $B$ is a weighted sum of past values. Nothing more.

## Why not just write it out?

Because models get long and the structure disappears. Compare

$$z_t = \phi_1 z_{t-1} + \phi_2 z_{t-2} + a_t - \theta_1 a_{t-1}$$

with

$$\phi(B) z_t = \theta(B) a_t$$

The second form makes visible that there are **two polynomials**, one acting on the data and one acting on the shocks. Every question in this vault — stationarity, invertibility, differencing, seasonal structure, and the entire SEATS decomposition — is a question about those two polynomials and their roots.

## Division and infinite series

$1/(1-\phi B)$ is legal *if* you read it as a geometric series:

$$\frac{1}{1-\phi B} = 1 + \phi B + \phi^2 B^2 + \phi^3 B^3 + \cdots$$

Check it: multiply both sides by $(1-\phi B)$ and everything cancels except 1.

This converges only when $|\phi| < 1$. That convergence condition **is** the stationarity condition for AR(1) — see [[10-02-stationarity-and-roots]]. The algebra and the statistics are the same statement.

## Operator on a constant

$B c = c$ for a constant $c$, so $(1-B)c = 0$. Differencing kills a constant. And $(1-B)(\alpha + \beta t) = \beta$: differencing turns a linear trend into a constant. This is why a **constant term in a differenced model is a drift, not a level** — a distinction that matters enormously later, and one that trips people up constantly. Filed under [[10-06-differencing]].

## Exercises

1. Expand $(1-B)^2$ and write the resulting recipe on $z_t$. What kind of trend does it kill?
2. Show $(1-B^{12}) = (1-B)(1 + B + B^2 + \cdots + B^{11})$. What does the second factor mean in words? (This factorisation is the seed of the whole trend/seasonal split — see [[10-06-differencing]].)
3. Expand $1/(1 - 0.8B)$ to five terms. How much weight does an observation 5 periods ago get?

## Links

- Next: [[10-02-stationarity-and-roots]]
- Used later by: [[10-09-seasonal-arima]], [[40-00-seats-map]]
