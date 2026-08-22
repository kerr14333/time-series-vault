---
aliases: [SEATS, Canonical decomposition, Module 4]
tags: [moc, module-4, key]
---

# Module 4 — SEATS

**SEATS** = Signal Extraction in ARIMA Time Series (Gómez & Maravall, Bank of Spain; theory from Hillmer & Bell 1982, Bell & Hillmer 1984, Burman 1980). This is the destination.

## The algorithm, complete, in seven steps

Given a fitted regARIMA model for the linearized series $z_t$:

$$\phi(B)\,\delta(B)\, z_t = \theta(B)\, a_t$$

where $\delta(B)$ collects the differencing operators (the nonstationary AR factors).

1. **Factor the AR side.** Split $\phi(B)\delta(B)$ into $\phi_T(B)\,\phi_S(B)$ by root location:
   - roots at or near $z=1$ (frequency 0), and any stationary roots with low frequency → **trend**
   - roots at or near the seasonal frequencies $2\pi k/12$ → **seasonal**
   - anything left (high-frequency, or short-cycle) → **transitory / irregular**

   For the airline model, $\delta(B)=(1-B)(1-B^{12}) = (1-B)^2 S(B)$, so $\phi_T = (1-B)^2$ and $\phi_S = S(B) = 1+B+\cdots+B^{11}$. That is [[10-06-differencing]] doing real work.

2. **Write the model spectrum.** $f_z(\omega) = \frac{\sigma_a^2}{2\pi} \frac{|\theta(e^{-i\omega})|^2}{|\phi_T\,\phi_S|^2}$ — a rational function ([[30-03-spectrum-of-an-arma]]).

3. **Partial fractions.** Decompose

   $$\frac{\theta(B)\theta(F)}{\phi_T(B)\phi_T(F)\,\phi_S(B)\phi_S(F)} = \frac{g_T(B,F)}{\phi_T(B)\phi_T(F)} + \frac{g_S(B,F)}{\phi_S(B)\phi_S(F)} + g_I$$

   This is ordinary partial-fraction algebra, done in $B$ and $F$ jointly. Each denominator carries its own unit roots, so each term is the (pseudo-)spectrum of one component. **This is the mechanical core of SEATS** and it is where an implementation actually lives.

4. **Admissibility.** The pieces must all be non-negative spectra. Not every ARIMA admits a decomposition; when it does not, SEATS replaces the model with a nearby admissible one and tells you. Map the admissible region for the airline model — good exercise.

5. **Canonical choice.** The decomposition in step 3 is **not unique**: you can move a constant amount of white noise between any component and the irregular. Hillmer & Bell's canonical rule pins it down:

   > Subtract from each component the **minimum of its spectrum**, and give all of it to the irregular.

   Result: each component is as *smooth and stable as possible*, the irregular absorbs as much variance as possible, and the answer is unique. The cost: each component's spectrum now **touches zero** somewhere — i.e. each component has a **unit MA root**, non-invertible by construction. Reread [[10-05-invertibility]]; this is the payoff of that note.

6. **Build the WK filters.** For each component, $\nu_c(B,F) = f_c(\omega)/f_z(\omega)$ ([[30-06-wiener-kolmogorov]]). In model terms the trend filter comes out as
   $$\nu_T(B,F) = \frac{\sigma_T^2}{\sigma_a^2}\cdot \frac{\theta_T(B)\theta_T(F)\,\phi_S(B)\phi_S(F)}{\theta(B)\theta(F)}$$
   and similarly for the seasonal. Symmetric, convergent, doubly infinite.

7. **Apply to finite data.** Extend the series with forecasts and backcasts from the same ARIMA model, then apply the truncated symmetric filter (Burman's algorithm does this efficiently). Ends therefore depend on forecasts → revisions ([[10-14-forecasting]]).

## Notes to write

- [[40-01-unobserved-components-and-reduced-form]] — why every UC model has an ARIMA reduced form
- [[40-02-admissible-decompositions]] — the non-uniqueness and its bounds
- [[40-03-canonical-decomposition]] — the minimum-variance rule, worked on the airline model
- [[40-04-partial-fractions-in-b-and-f]] — the algebra, step by step, with numbers
- [[40-05-component-models]] — what ARIMA each component turns out to follow
- [[40-06-wk-filters-for-the-airline-model]] — derive and plot the gain functions
- [[40-07-implementing-seats-in-r]] — **the build**
- [[40-08-validating-against-x13]] — match `seasonal::seas()` table by table
- [[40-09-burman-algorithm]] — how SEATS actually computes the filter: partial fractions into two one-sided recursions, worked slowly
- [[40-10-general-seats]] — beyond the airline model: sort the AR roots by frequency and modulus to discover the trend/seasonal split, and pick up a fourth **transitory** component for cyclical roots that belong to neither
- [[40-11-validating-general-seats]] — check the root sorting against X-13's own printed factorization, and the four errors that internal consistency checks could not see

## The build target

`R/40-seats-from-scratch.R`: input a series and $(\theta,\Theta)$, output trend, seasonal, irregular and seasonally adjusted series. Validation: against `seasonal::seas(x, ...)` with SEATS mode, checking the identity

$$\log z = \log(\text{SA}) + \log(\text{seasonal factor})$$

table by table (X-13 tables `s10`, `s11`, `s12`, `s13`, `s16`).

## Traps worth knowing before you start

- **Sign convention.** The algebra manipulates $\theta(B)\theta(F)$ directly. Get the MA sign wrong and everything still *looks* plausible. [[10-11-sign-conventions]]
- **The mean/drift.** SEATS keeps the model mean *in* the series it decomposes (unlike trading day and outliers, which are removed as deterministic regressors). It centres the differenced series by the mean, decomposes, then folds the drift back into the **trend** — seasonal and irregular do not carry it. Error signature: a trend error that grows toward the sample ends.
- **Which series is actually decomposed.** Verify with the identity above before you trust anything.

## Prerequisites

Modules 1 and 3. Module 2 is not strictly required but makes the results interpretable.
