---
aliases: [ARIMA foundations, Module 1]
tags: [moc, module-1]
---

# Module 1 — ARIMA foundations

You said you know AR and MA but the surrounding algebra is fuzzy. That is the normal place to be stuck, and it is worth fixing properly, because **SEATS is nothing but algebra done to the ARIMA polynomials.** If the polynomials are fuzzy, SEATS will stay magic forever.

The whole module builds toward one sentence being obvious:

> $(1-B)(1-B^{12})\,z_t = (1-\theta B)(1-\Theta B^{12})\,a_t$

## Order

1. [[10-01-lag-operator]] — treating "one period ago" as a number you can multiply and divide
2. [[10-02-stationarity-and-roots]] — what stationarity is, and why we look at polynomial *roots*
3. [[10-03-ar-processes]] — AR as an infinite echo
4. [[10-04-ma-processes]] — MA as a finite memory of shocks
5. [[10-05-invertibility]] — the MA-side mirror of stationarity, and why anyone cares
6. [[10-06-differencing]] — the "I" in ARIMA, regular and seasonal
7. [[10-07-acf-and-pacf]] — reading a model off two plots
8. [[10-08-arma-duality]] — why AR and MA are the same object seen from two sides
9. [[10-09-seasonal-arima]] — multiplying polynomials in $B$ and $B^{12}$
10. [[10-10-airline-model]] — the one model you must know cold
11. [[10-11-sign-conventions]] — the trap that will bite you in X-13 vs R
12. [[10-12-estimation]] — how the parameters actually get found
13. [[10-13-model-selection]] — AIC, residual tests, automatic identification
14. [[10-14-forecasting]] — $\psi$-weights and forecast error variance; this is what X-13 uses to extend the series

## Checkpoint

You are done with this module when you can, on paper:

- expand $(1-B)(1-B^{12})$ into four terms and say what each does to the data,
- state whether $(1 - 1.2B + 0.5B^2)$ is stationary and *show* it,
- sketch the ACF of an MA(1) with $\theta = 0.4$,
- explain why forecasting is required before you can seasonally adjust the most recent month.

Code: `R/10-*.R`.
