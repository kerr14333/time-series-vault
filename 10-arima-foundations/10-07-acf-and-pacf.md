---
aliases: [ACF, PACF, Identification]
tags: [module-1]
---

# ACF and PACF — reading a model off two plots

Code: [[code-10-07-acf-and-pacf|`R/10-07-acf-and-pacf.R`]]

## ACF

$$\rho_k = \frac{\gamma_k}{\gamma_0} = \frac{\mathrm{Cov}(z_t, z_{t-k})}{\mathrm{Var}(z_t)}$$

Correlation between the series and itself $k$ periods back. Sample version $\hat\rho_k$; under white noise, $\hat\rho_k \approx N(0, 1/n)$, hence the $\pm 1.96/\sqrt{n}$ bands R draws.

Those bands are **pointwise**. With 40 lags plotted, expect ~2 to poke out by chance. Do not model an isolated spike at lag 17.

## PACF

$\phi_{kk}$ = correlation between $z_t$ and $z_{t-k}$ **after removing the linear effect of the intervening lags** $z_{t-1},\dots,z_{t-k+1}$.

Operationally: regress $z_t$ on $z_{t-1},\dots,z_{t-k}$; the PACF at lag $k$ is the coefficient on $z_{t-k}$. (In practice computed by the Durbin–Levinson recursion, not by running $k$ regressions.)

Why it exists: an AR(1) with $\phi=0.8$ has $\rho_2 = 0.64$, which is not a *direct* link — it is $\rho_1$ acting twice. The PACF strips the indirect path out, so $\phi_{22} = 0$. Hence:

## The identification table

| Model | ACF | PACF |
|---|---|---|
| AR($p$) | decays (geometric / damped sine) | **cuts off after lag $p$** |
| MA($q$) | **cuts off after lag $q$** | decays |
| ARMA($p,q$) | decays after lag $q$ | decays after lag $p$ |
| Nonstationary | decays *very* slowly, near-linearly | huge $\phi_{11}\approx1$, little else |

The duality (why AR and MA swap roles) is [[10-08-arma-duality]].

Mnemonic that survives pressure: **the cutoff tells you the order, and it cuts off in the plot named after the *other* letter.** MA order shows in the ACF; AR order shows in the PACF.

## Reading seasonal structure

For monthly data, look at two places at once:

- **Low lags (1–3)** → the regular $p, q$.
- **Seasonal lags (12, 24, 36)** → the seasonal $P, Q$.

The multiplicative model creates **satellite spikes** at $12 \pm 1$ — that is, lags 11 and 13, 23 and 25. Those satellites are the fingerprint of the *product* $\theta(B)\Theta(B^{12})$; a purely additive seasonal model would not produce them. Seeing lag 11 and 13 spikes and being able to say "that's the cross-term" is a real milestone. Worked out in [[10-10-airline-model]].

## The workflow

1. Plot the series. Logs?
2. Difference until the ACF dies at a reasonable rate. Record $d, D$.
3. ACF/PACF of the differenced series → propose $p, q, P, Q$.
4. Fit; check residual ACF is clean ([[10-13-model-selection]]).
5. Compare a couple of candidates by AICC.

Honest caveat: for real data these plots are often ambiguous, and reasonable people pick different models. That ambiguity is exactly why automatic identification (`automdl` in X-13, Hyndman–Khandakar in R) exists — and it is also why SEATS output can differ between analysts who both did nothing wrong.

![[10-07-acf-pacf-grid.png]]

*Drawn by [[figure-index#10-07-acf-pacf-grid.png|`make-figures.R`]] — code and every other figure in the [[figure-index|figure appendix]].*

The identification rule, in one grid. Along the top an AR(1): the ACF decays geometrically while the PACF stops dead after lag 1. Along the bottom an MA(1), doing exactly the reverse. Both from 3000 simulated points, so the sampling noise is small and the pattern is unambiguous.

**The rule:** whichever function *cuts off* names the order, and which function it is names the type. In real data with 100-odd points it is far messier than this, which is why [[10-13-model-selection]] leans on AICC rather than eyeballing.

## Numerically

The identification table, generated rather than memorised.

AR cuts off in the **PACF**; MA cuts off in the **ACF**. Simulate one of each and read the two columns:

<!-- run -->
```r
set.seed(3)
ar1 <- arima.sim(list(ar = 0.8), n = 3000)
ma1 <- arima.sim(list(ma = -0.8), n = 3000)
tab <- rbind(
  `AR(1) acf`  = acf(ar1,  lag.max = 5, plot = FALSE)$acf[-1],
  `AR(1) pacf` = pacf(ar1, lag.max = 5, plot = FALSE)$acf,
  `MA(1) acf`  = acf(ma1,  lag.max = 5, plot = FALSE)$acf[-1],
  `MA(1) pacf` = pacf(ma1, lag.max = 5, plot = FALSE)$acf)
round(tab, 3)
```
```text
             [,1]   [,2]   [,3]   [,4]   [,5]
AR(1) acf   0.795  0.620  0.481  0.374  0.296
AR(1) pacf  0.795 -0.032 -0.006  0.003  0.014
MA(1) acf  -0.484 -0.019  0.043 -0.029  0.002
MA(1) pacf -0.484 -0.331 -0.190 -0.151 -0.118
```
<!-- end -->

The significance band is $\pm 2/\sqrt{n}$ — it narrows with the square root of the sample, so long series flag tiny correlations:

<!-- run -->
```r
round(sapply(c(72, 144, 500, 2000), function(n) 2 / sqrt(n)), 4)
```
```text
[1] 0.2357 0.1667 0.0894 0.0447
```
<!-- end -->

## Exercises

*Solutions: [[solutions#10-07-acf-and-pacf|worked answers]] in the solutions appendix.*

1. Simulate AR(2), MA(2) and ARMA(1,1) at n=300. Print ACF/PACF for each without labels, shuffle them, and identify them cold. Repeat at n=60 and notice how much harder it gets — that is the real-data regime.
2. For log-differenced AirPassengers, name every lag whose ACF exceeds the band, and say which polynomial you think produced it.
3. Why does a nonstationary series show $\phi_{11}\approx1$?

> [!abstract] Derivation
> - [[derivations#D2. The MA(1) autocorrelation, and why it cannot exceed one half|why an MA ACF cuts off]]

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** Sketch the ACF and PACF you expect from an ARMA(1,1) before simulating. Which one cuts off? (Trick question.)
2. **Break it.** Compute an ACF on a series with a level shift in the middle. How does the break distort it, and would you diagnose the right model?
3. **Transfer.** Read the ACF of a *quarterly* differenced series. Where are the seasonal spikes now?

## Links

- Prev: [[10-06-differencing]] · Next: [[10-08-arma-duality]]
