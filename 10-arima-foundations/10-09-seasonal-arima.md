---
aliases: [SARIMA, Seasonal ARIMA, Multiplicative seasonal model]
tags: [module-1]
---

# Seasonal ARIMA

Code: [[code-10-09-seasonal-arima|`R/10-09-seasonal-arima.R`]]

## The notation, decoded

$$\text{ARIMA}(p,d,q)(P,D,Q)_s$$

$$\phi(B)\,\Phi(B^s)\,(1-B)^d(1-B^s)^D\,z_t \;=\; \theta(B)\,\Theta(B^s)\,a_t$$

Four polynomials. Two act on the data (AR side), two act on the shocks (MA side); within each side one is in $B$ and one is in $B^s$.

| Symbol | Order | In | Side |
|---|---|---|---|
| $\phi(B)$ | $p$ | $B$ | AR |
| $\Phi(B^s)$ | $P$ | $B^{12}$ | AR |
| $\theta(B)$ | $q$ | $B$ | MA |
| $\Theta(B^s)$ | $Q$ | $B^{12}$ | MA |

The differencing orders $d, D$ are the unit-root parts of the AR side ([[10-06-differencing]]).

## Why *multiplicative* and not additive

The seasonal polynomial $\Phi(B^{12})$ alone says "this January relates to last January". The regular $\phi(B)$ alone says "this month relates to last month". Real data has both, **and the interaction**: this January relates to last December *and* to last January, so it relates to last December-to-January too.

Multiplying the polynomials generates exactly those cross terms, for free, with no extra parameters. Expand the airline MA:

$$(1-\theta B)(1-\Theta B^{12}) = 1 - \theta B - \Theta B^{12} + \theta\Theta B^{13}$$

Four terms, **two** parameters. The $B^{13}$ coefficient is forced to be the product. An additive model would need a third free parameter to reach lag 13, and would fit worse per parameter spent.

This is why the ACF of such data shows those **satellite spikes at lags 11 and 13** ([[10-07-acf-and-pacf]]): the cross term is doing visible work.

## Seasonal AR vs seasonal differencing

- $\Phi(B^{12})$ with $|\Phi| < 1$: a **stationary** seasonal — the pattern reverts toward a fixed shape.
- $(1-B^{12})$: seasonal **unit roots** — the pattern is a random walk from year to year, free to evolve without bound.

Most real economic seasonality is evolving, which is why $D=1$ is far more common than $P=1$. And an estimated $\Phi$ near 0.9 is a hint that you should have differenced instead.

This distinction is precisely what separates seasonal-adjustment methods from seasonal *dummies*: dummy variables impose a fixed pattern forever. Every method in this vault assumes the pattern moves.

## Which coefficients you actually see in practice

For monthly series, the overwhelmingly common models are:

- $(0,1,1)(0,1,1)_{12}$ — the airline model, the default. [[10-10-airline-model]]
- $(0,1,2)(0,1,1)_{12}$, $(2,1,0)(0,1,1)_{12}$ — mild variants
- $(0,1,1)(0,1,1)_{12}$ **with regressors** — trading day, Easter, outliers: that is **regARIMA**, and it is what X-13 actually fits before handing anything to SEATS.

![[10-09-seasonal-acf.png]]

*Drawn by [[figure-index#10-09-seasonal-acf.png|`make-figures.R`]] — code and every other figure in the [[figure-index|figure appendix]].*

**Left:** after removing the trend with $(1-B)$, the seasonal structure is unmistakable — spikes at 12, 24 and 36, decaying slowly. Seasonal dependence lives at multiples of the period, not at lag 1.

**Right:** after the seasonal difference as well, almost everything is gone. What survives is a negative spike at lag 1 and another at lag 12 — precisely the two MA terms the airline model provides. The picture is the model specification.

## Numerically

The seasonal part multiplies, and multiplication is where the extra terms come from.

$(1-\theta B)(1-\Theta B^{12})$ expanded. Note the $B^{13}$ term nobody writes down by hand:

<!-- run -->
```r
poly_show(airline_ma(theta = 0.4, Theta = 0.6))
```
```text
[1] "1 - 0.4B - 0.6B^12 + 0.24B^13"
```
<!-- end -->

Seasonal dependence shows up at multiples of 12 in the ACF, not at lag 1:

<!-- run -->
```r
set.seed(4)
x <- arima.sim(list(ma = c(rep(0, 11), -0.7)), n = 3000)
a <- acf(x, lag.max = 26, plot = FALSE)$acf[-1]
round(a[c(1, 11, 12, 13, 23, 24, 25)], 3)
```
```text
[1] -0.020  0.009 -0.474  0.005  0.009  0.012 -0.010
```
<!-- end -->

## Exercises

1. Expand $(1 - \phi B)(1 - \Phi B^{12})$ fully. Which lags get nonzero coefficients?
2. Write $(0,1,1)(1,0,0)_{12}$ out in full scalar form.
3. Simulate an airline model with $\theta=0.4,\Theta=0.6$; plot its ACF after $\nabla\nabla_{12}$ and locate the satellite spikes.

> [!abstract] Derivation
> - [[derivations#D4. The seasonal difference contains the trend difference|where the seasonal roots come from]]

## Links

- Prev: [[10-08-arma-duality]] · Next: [[10-10-airline-model]]
