---
aliases: [Differencing, Integration, The I in ARIMA]
tags: [module-1]
---

# Differencing — the "I" in ARIMA

Code: [[code-10-06-differencing|`R/10-06-differencing.R`]]

## Two operators

$$\nabla = 1 - B \quad\text{(regular)}, \qquad \nabla_s = 1 - B^s \quad\text{(seasonal, } s=12\text{ monthly)}$$

A model with $d$ regular and $D$ seasonal differences:

$$\phi(B)\Phi(B^s)\,(1-B)^d (1-B^s)^D z_t \;=\; \theta(B)\Theta(B^s)\,a_t$$

Read left to right: differencing operators sit on the **AR side**, applied to the data. They are AR factors whose roots sit exactly *on* the unit circle — nonstationary AR factors. That framing is the one that carries into SEATS.

## What each one removes

| Operator | Kills | Leaves |
|---|---|---|
| $(1-B)$ | a constant level; a random walk's unit root | a linear trend becomes a constant |
| $(1-B)^2$ | a linear trend | |
| $(1-B^{12})$ | a fixed monthly seasonal pattern; the seasonal unit roots | |

Verify #1 by hand: $(1-B)(\alpha + \beta t) = \alpha + \beta t - \alpha - \beta(t-1) = \beta$.

> [!important] The consequence people get wrong
> A **constant term in a differenced model is a drift, not a level.** If $d \ge 1$, the fitted "Constant" is the mean of the *differenced* series. Its effect on the original level is an integrated polynomial — a straight-line ramp when $d=1$. So a printed constant in a $d=1$ log model is not "the level"; it is a per-period growth rate. Fitting $\log$ `AirPassengers` as $(0,1,1)$ with a drift regressor gives $+0.009726$ per month — that is $+0.97\%$ per month, or $+12.4\%$ per year, not a level near zero. You will meet this again reading X-13 output.
>
> **The R trap:** `arima()` *silently ignores* `include.mean = TRUE` when $d \ge 1$. You get no intercept, no warning, and `coef(fit)["intercept"]` is `NA` rather than an error. To fit a drift you must pass it yourself: `arima(x, order = c(0,1,1), xreg = 1:n)`. Its $t$ here is only $0.89$ — with the level already differenced away, drift is weakly identified.

## The factorisation that explains everything

$$1 - B^{12} = (1-B)\,(1 + B + B^2 + \cdots + B^{11}) = (1-B)\,S(B)$$

- $(1-B)$ contributes the root at $z=1$ — **frequency 0** — that is the *trend* unit root.
- $S(B)$ contributes the other 11 roots, spread around the unit circle at the **seasonal frequencies** $2\pi k/12$, $k=1..6$ (as complex-conjugate pairs, plus a real root at $-1$ for $k=6$, the two-month cycle).

Two payoffs:

1. **$(1-B)(1-B^{12})$ contains the root $z=1$ twice.** So the airline model has a *second-order* trend unit root — it accommodates a slowly-changing slope, not just a changing level. That is why it fits so many economic series.
2. **This factorisation is literally the first step of SEATS.** SEATS takes the differencing operator of the fitted model, splits it as above, gives $(1-B)^{d+D}$ to the trend and $S(B)^D$ to the seasonal, and then works out which MA numerator goes with each. Everything after that is bookkeeping. See [[40-00-seats-map]].

## How much to difference

Rules that actually work:

- Look at the ACF. Slow, near-linear decay that refuses to die → needs a difference. A big spike at lag 12, 24, 36 decaying slowly → needs a seasonal difference.
- **Almost never** use $d > 2$ or $D > 1$. $(0,1,1)(0,1,1)$ covers a huge share of real economic series.
- Formal tests exist (ADF, KPSS, HEGY for seasonal roots, and X-13's own `automdl` procedure), but they are a tiebreaker, not the primary tool.
- **Over-differencing has a signature**: the MA coefficient pins near 1, i.e. a non-invertible root that is trying to cancel the difference you should not have taken. See [[10-05-invertibility]]. It also inflates the variance of the differenced series — a simple check: differencing again should *reduce* variance; if it increases, stop.

## The variance check, on a series where it matters

Differencing once too often *increases* the variance of the result. That gives a cheap test needing no model at all: difference, measure, and stop when the variance stops falling.

On `ldeaths` (monthly UK lung-disease deaths):

| Stage | Variance of $\log$(ldeaths) |
|---|---|
| undifferenced | 0.0812 |
| after $(1-B^{12})$ | **0.0189** ← stop here |
| after $(1-B)(1-B^{12})$ | 0.0349 ← worse |

So this series needs the **seasonal** difference and not the regular one — $d=0$, $D=1$ — which is exactly the model X-13 chooses when left alone. Compare `AirPassengers`, where both differences reduce the variance and the airline model is right.

The habit worth forming: run this check before accepting $(1,1)$ out of reflex. It costs one line and catches the most common modelling error in the field. See [[10-05-invertibility]] for the same conclusion reached from the MA coefficients.

## Logs come first

Before differencing, decide on logs. If the seasonal swing grows with the level (multiplicative), take logs — that turns multiplicative structure into additive, which is what ARIMA models. AirPassengers is the textbook case: raw amplitude fans out, log amplitude is roughly constant.

X-13 automates this as the **log/level test** (AICC comparison between the two). In SEATS, working in logs means the components multiply: $Z = T \times S \times I$, and the printed seasonal factors are ratios around 1 rather than deviations around 0.

![[10-06-differencing-ladder.png]]

*Drawn by [[figure-index#10-06-differencing-ladder.png|`make-figures.R`]] — code and every other figure in the [[figure-index|figure appendix]].*

The whole point of differencing in four panels. The raw series has trend *and* seasonal. $(1-B)$ removes the trend and leaves an obvious annual wave. $(1-B^{12})$ does the opposite — the wave goes, a drifting level remains. Only the product removes both, and the bottom panel is what actually gets modelled.

Read bottom-up and it is also the argument for the airline model: two differences, so two MA terms, one at lag 1 and one at lag 12.

## Numerically

Differencing is a choice with a cost. The numbers make both visible.

The factorisation that the whole SEATS split rests on — $(1-B^{12})$ contains the trend root $(1-B)$:

<!-- run -->
```r
S <- diff_poly(D = 1)                      # 1 - B^12
cat("1 - B^12          =", poly_show(S), "\n")
cat("(1-B)(1+B+...+B^11) =", poly_show(poly_mult(c(1, -1), rep(1, 12))), "\n")
cat("identical:", isTRUE(all.equal(S, poly_mult(c(1, -1), rep(1, 12)))), "\n")
```
```text
1 - B^12          = 1 - B^12 
(1-B)(1+B+...+B^11) = 1 - B^12 
identical: TRUE 
```
<!-- end -->

Over-differencing inflates the variance. On `ldeaths` the regular difference makes things *worse*, which is the model telling you to stop:

<!-- run -->
```r
ld <- log(ldeaths)
round(c(undifferenced = var(ld),
        seasonal      = var(diff(ld, 12)),
        both          = var(diff(diff(ld, 12)))), 5)
```
```text
undifferenced      seasonal          both 
      0.08117       0.01890       0.03492 
```
<!-- end -->

## Exercises

*Solutions: [[solutions#10-06-differencing|worked answers]] in the solutions appendix.*

1. Take logs of AirPassengers, apply $\nabla$, then $\nabla_{12}$, and plot at each stage. At which stage does it start to look stationary?
2. Compute the variance after each stage. What happens if you difference once more?
3. Find the 12 roots of $1-B^{12}$ numerically and convert each to a period in months. Confirm you get 12, 6, 4, 3, 2.4 and 2 months.

> [!abstract] Derivation
> - [[derivations#D4. The seasonal difference contains the trend difference|the factorisation of $1-B^s$]]
> - [[derivations#D5. A constant in a differenced model is a drift|why the constant is a slope]]

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** For `co2`, which differencing do you expect X-13 to choose, and why? Then check with `seas()`.
2. **Break it.** Difference `log(AirPassengers)` three times and look at the variance and the ACF. What are the symptoms of over-differencing?
3. **Transfer.** Repeat the variance-at-each-stage table for a quarterly series. Does the same $d, D$ combination win?

## Links

- Prev: [[10-05-invertibility]] · Next: [[10-07-acf-and-pacf]]
- Quiz: [[_quiz/quiz-module-1]]
