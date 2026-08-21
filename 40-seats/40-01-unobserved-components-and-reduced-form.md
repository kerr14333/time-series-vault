---
aliases: [Unobserved components, Reduced form, Structural model]
tags: [module-4]
---

# Unobserved components and the reduced form

Code: [[code-40-01-unobserved-components-and-reduced-form|`R/40-01-unobserved-components-and-reduced-form.R`]]

## Two ways to describe the same series

**Structural.** Say what the components are, directly:

$$z_t = T_t + S_t + I_t$$
$$(1-B)^2 T_t = \eta_t, \qquad S(B)\,S_t = \omega_t, \qquad I_t = \varepsilon_t$$

A trend that is a doubly-integrated random walk, a seasonal driven by $S(B) = 1+B+\cdots+B^{11}$, and white noise. Three independent shocks, three variances. This is the *basic structural model*, and it is easy to explain to anyone.

**Reduced form.** Say what the *observed* series does:

$$(1-B)(1-B^{12})\,z_t = (1-\theta B)(1-\Theta B^{12})\,a_t$$

One equation, two parameters, one shock. Harder to explain, trivial to fit.

## They are the same model

Apply $\nabla\nabla_{12} = (1-B)^2 S(B)$ to the structural model. Each component's own operator cancels part of it:

| Component | Its operator | What survives of $(1-B)^2S(B)$ |
|---|---|---|
| $T_t$ | $(1-B)^2$ | $S(B)\,\eta_t$ |
| $S_t$ | $S(B)$ | $(1-B)^2\omega_t$ |
| $I_t$ | — | $(1-B)^2S(B)\,\varepsilon_t$ |

So

$$\nabla\nabla_{12} z_t = S(B)\eta_t + (1-B)^2\omega_t + (1-B)^2S(B)\varepsilon_t$$

The right-hand side is a sum of three independent moving averages, each of finite order. **A sum of independent MAs is an MA.** Its highest order here is 13, and its autocovariances vanish beyond lag 13 — exactly the structure of $(1-\theta B)(1-\Theta B^{12})a_t$.

> [!important] The bridge
> A structural model you can describe in English has an **ARIMA reduced form**. The airline model is not an arbitrary equation someone liked; it is what "trend + seasonal + noise" *looks like* after differencing.

## And SEATS runs the bridge backwards

You cannot observe $T$, $S$ or $I$ — only $z$. So:

```text
structural model  --(differencing)-->  ARIMA reduced form   [theory]
        ^                                     |
        |                                     | fit to data
        +-------- SEATS ----------------------+
```

**Fit the reduced form, then recover the structural components it must have come from.** That is the entire method, and the rest of Module 4 is doing it carefully.

## The count that explains everything

Compare the parameters:

| Model | Free parameters |
|---|---|
| structural | $\sigma_\eta^2,\ \sigma_\omega^2,\ \sigma_\varepsilon^2$ — **three** |
| airline reduced form | $\theta,\ \Theta,\ \sigma_a^2$ — **three** |

Three and three. That looks like a clean correspondence, and over much of the parameter space it is.

But it is not a *bijection*:

- Some $(\theta,\Theta)$ correspond to **no** valid set of non-negative variances. Those models cannot be decomposed — [[40-02-admissible-decompositions]].
- Where a decomposition exists it is generally **not unique** — you can shift white noise between components. [[30-06-wiener-kolmogorov]] showed why; [[40-03-canonical-decomposition]] fixes it by convention.

Both facts follow from this counting exercise, and both are the subject of the next two notes.

## Why not just fit the structural model directly?

You can — that is the Harvey/STAMP tradition, and it is a perfectly respectable alternative. Trade-offs:

| | Structural (STAMP) | Reduced-form (SEATS) |
|---|---|---|
| Components | specified up front | derived from the fitted model |
| Estimation | state space + Kalman filter | ARIMA, then algebra |
| Identification | by assumption | needs a convention ([[40-03-canonical-decomposition]]) |
| If the model is wrong | components are wrong | components are wrong |
| Institutional use | some agencies | Bank of Spain, Eurostat, X-13 |

Neither dominates. SEATS's practical advantage is that fitting an ARIMA is routine, well-diagnosed, and shares all its machinery with the regARIMA preadjustment that has to happen anyway.

## Numerically

Step one of SEATS: split the AR side by frequency.

The differencing operator factors into a trend part and a seasonal part, exactly as D4 says:

<!-- run -->
```r
sp <- seats_ar_split(d = 1, D = 1, s = 12)
cat("trend side (1-B)^2 :", poly_show(sp$trend), "\n")
cat("seasonal side S(B) :", poly_show(sp$seas), "\n")
cat("product = (1-B)(1-B^12)?",
    isTRUE(all.equal(poly_mult(sp$trend, sp$seas), airline_ar())), "\n")
```
```text
trend side (1-B)^2 : 1 - 2B + B^2 
seasonal side S(B) : 1 + B + B^2 + B^3 + B^4 + B^5 + B^6 + B^7 + B^8 + B^9 + B^10 + B^11 
product = (1-B)(1-B^12)? TRUE 
```
<!-- end -->

## Exercises

*Solutions: [[solutions#40-01-unobserved-components-and-reduced-form|worked answers]] in the solutions appendix.*

1. Simulate the structural model with known $\sigma_\eta^2, \sigma_\omega^2, \sigma_\varepsilon^2$. Apply $\nabla\nabla_{12}$, fit an airline model, and check the ACF vanishes beyond lag 13.
2. Vary the three variances and watch the fitted $(\theta,\Theta)$ move. Which variance controls which parameter?
3. Set $\sigma_\omega^2 = 0$ (fixed seasonality). What does $\Theta$ come back as? Relate to [[10-10-airline-model]].
4. **The one that matters**: keep the simulated components, decompose the fitted reduced form with the tools of this module, and compare the recovered components to the truth you generated.

> [!abstract] Derivation
> - [[derivations#D4. The seasonal difference contains the trend difference|the AR-side split]]

## Links

- Prev: [[40-00-seats-map]] · Next: [[40-02-admissible-decompositions]]
- Foundation: [[10-10-airline-model]], [[30-06-wiener-kolmogorov]]
