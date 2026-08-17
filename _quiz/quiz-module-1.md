---
aliases: [Quiz Module 1]
tags: [quiz, module-1]
---

# Quiz — Module 1 (ARIMA foundations)

#flashcards/module-1

Two ways to use this:

- **Offline drill.** Install the Obsidian **Spaced Repetition** plugin. It reads `Q ::: A` as a
  card (`:::` = reversed off, one-directional) and schedules reviews. Nothing else to configure.
- **Live.** Say *"quiz me on module 1"* (or on a single note, or "quiz me hard") and I will run
  an adaptive session in chat — I ask, you answer, I push on whatever you get shaky on. That
  version is better, because I can follow up.

---

## Notation and algebra

What does the operator $B$ do? ::: $Bz_t = z_{t-1}$. Shift back one period. $B^k z_t = z_{t-k}$.

Expand $(1-B)(1-B^{12})$ ::: $1 - B - B^{12} + B^{13}$, i.e. $z_t - z_{t-1} - z_{t-12} + z_{t-13}$.

Does it matter whether you difference regularly or seasonally first? ::: No. Polynomial multiplication commutes, so the two orders give the identical series.

What is $(1-B)$ applied to $\alpha + \beta t$? ::: $\beta$. Differencing turns a linear trend into a constant — which is why a constant in a $d\ge1$ model is a **drift**, not a level.

Factor $1 - B^{12}$ ::: $(1-B)(1 + B + \cdots + B^{11})$. The first factor is the trend unit root, the second carries the 11 seasonal roots.

## Stationarity and roots

Three conditions for weak stationarity ::: constant mean; constant finite variance; autocovariance depends only on the lag $k$, not on $t$.

Stationarity condition on $\phi(B)$ ::: all roots of $\phi(z)=0$ lie strictly **outside** the unit circle, $|z_i|>1$. Equivalently the inverse roots are inside.

What is a unit root, and what does it do? ::: A root with $|z|=1$. Shocks never die, variance grows without bound, process is nonstationary.

Where do trend and seasonal unit roots sit in frequency? ::: Trend at $\omega=0$; seasonal at $\omega_k = 2\pi k/12$, $k=1..6$, i.e. periods 12, 6, 4, 3, 2.4, 2 months.

Why can't you fix a unit root by regressing out a straight line? ::: The nonstationarity is stochastic — the level wanders permanently. No fixed deterministic function absorbs it; the detrended residuals still have a near-unit-root ACF.

## AR and MA

Identification table: AR($p$) ::: ACF decays (geometric or damped sine); PACF **cuts off after lag $p$**.

Identification table: MA($q$) ::: ACF **cuts off after lag $q$**; PACF decays.

Why does the ACF of an AR obey the same difference equation as the process? ::: Multiply the model by $z_{t-k}$ and take expectations; $a_t$ is uncorrelated with $z_{t-k}$ for $k\ge1$, so the $\gamma_k$ satisfy the Yule–Walker recursion.

$\rho_1$ for an MA(1) in Census convention ::: $\rho_1 = -\theta/(1+\theta^2)$, with $|\rho_1| \le 1/2$ always.

Why do $\theta$ and $1/\theta$ give the same ACF? ::: $-\theta/(1+\theta^2)$ is invariant under $\theta \mapsto 1/\theta$. Two MA(1) models, one autocorrelation function — hence the need for an invertibility rule to pick one.

## Invertibility

Invertibility condition ::: all roots of $\theta(z)=0$ strictly outside the unit circle; for MA(1), $|\theta|<1$.

Three reasons invertibility matters ::: (1) picks a unique model out of the $\theta$ vs $1/\theta$ pair; (2) the $\pi$-weights must converge for the shocks to be recoverable from the observed past, which forecasting needs; (3) it controls how fast the AR($\infty$) weights decay.

An estimated MA coefficient pinned near 1 usually means what? ::: Over-differenced. The MA is trying to cancel a difference you should not have taken.

Why does SEATS **want** non-invertible components? ::: The canonical decomposition minimises each component's variance, which makes each component spectrum touch zero — a spectral zero *is* a unit MA root. Non-invertibility is the goal there, not a bug.

## Seasonal ARIMA

Write out ARIMA$(p,d,q)(P,D,Q)_s$ ::: $\phi(B)\Phi(B^s)(1-B)^d(1-B^s)^D z_t = \theta(B)\Theta(B^s)a_t$.

Why multiplicative rather than additive seasonal terms? ::: The product generates the cross terms (e.g. lag 13) for free, with no extra parameters. Additive would need a separate parameter to reach lag 13 and fits worse per parameter.

What produces ACF spikes at lags 11 and 13? ::: The cross term $\theta\Theta B^{13}$ of $\theta(B)\Theta(B^{12})$ — "satellites" around the seasonal lag. Their presence is the fingerprint of a multiplicative model.

The airline model ::: $(0,1,1)(0,1,1)_{12}$: $(1-B)(1-B^{12})z_t = (1-\theta B)(1-\Theta B^{12})a_t$.

What does $\Theta$ mean in practice? ::: How much the seasonal pattern is allowed to evolve. $\Theta\to1$ cancels the seasonal unit roots and gives a nearly fixed pattern (stable factors, small revisions); low $\Theta$ means volatile seasonality and large revisions.

Why does the airline model have a *double* unit root at frequency 0? ::: $(1-B^{12})$ contains a $(1-B)$ factor, so $(1-B)(1-B^{12}) = (1-B)^2 S(B)$. It therefore accommodates a drifting slope, not just a drifting level.

## Conventions and estimation

Relationship between R's and Census's MA coefficients ::: $\theta^{\text{Census}} = -\theta^{R}$. `stats::arima()` uses the plus convention; X-13, TRAMO/SEATS and Box–Jenkins use minus.

For a healthy economic series, what sign are the Census-convention airline MA parameters? ::: Positive. Negative values should make you suspect a sign flip before you suspect the data.

Why exact ML rather than CSS for seasonal models? ::: Seasonal MA parameters sit near the unit circle, exactly where the CSS approximation degrades and biases the estimate toward the interior.

What is regARIMA, and what does it output for the adjustment? ::: Regression terms (trading day, holidays, outliers) plus ARIMA errors, estimated jointly by exact ML. Its output is the **linearized series** — the data minus the estimated regression effects — which is what gets decomposed.

Which regression effect is NOT removed before decomposition, and what happens to it? ::: The constant/mean. SEATS keeps it in, centres the differenced series by it, and folds the drift back into the **trend**; seasonal and irregular do not carry it.

Common trap when using `Box.test()` ::: It does not subtract the fitted parameters unless you pass `fitdf=`. Without it the p-value is wrong (too generous).

## Forecasting — the hinge

Forecast error variance in terms of $\psi$-weights ::: $V(h) = \sigma_a^2 \sum_{j=0}^{h-1}\psi_j^2$. Bounded for a stationary model; unbounded when there are unit roots.

Why does seasonal adjustment need forecasts at all? ::: The seasonal filter is symmetric and two-sided, but at the end of the sample there is no future data. X-13 forecast-extends with the regARIMA model so the symmetric filter can still be applied.

Why are the most recent seasonal factors revised? ::: They were computed partly from forecasts. As real data replaces those forecasts, the factors move — converging toward the symmetric-filter value.

Why is a business-cycle turning point the worst case? ::: The forecast extrapolates the old regime, so it is wrong in a systematic direction exactly at the turn. That contaminates the end-of-sample factors precisely when people care most.

Roughly what fraction of month-to-month movements in a seasonally adjusted series can be false signals? ::: About 40% (Maravall & Pierce 1983).

How fast does seasonal-adjustment revision variance decay? ::: About −50% after 1 year, −77% after 3, −88% after 5 (Maravall 1996).
