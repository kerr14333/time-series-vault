---
aliases: [Solutions, Answers, Exercise solutions, Appendix C]
tags: [meta, appendix, reference]
---

# Appendix: exercise solutions

Answers to the exercises at the end of each note. Every note links here from its own **Exercises** section.

Use them the way you would use the back of a textbook: attempt first, check second. An exercise you have merely read the answer to has taught you nothing — the whole point of the numeric ones is that *running* them is where the surprise lives.

Where a solution says "the script does this", the file named prints the result already; where it gives code, the code is short enough to type.

Notation is Census/Box–Jenkins throughout: $\theta(B) = 1 - \theta_1 B - \cdots$, the opposite of `stats::arima()` ([[10-11-sign-conventions]]).

---

# Module 1 — ARIMA foundations

## 10-01-lag-operator

**1.** $(1-B)^2 = 1 - 2B + B^2$, so the recipe is $z_t - 2z_{t-1} + z_{t-2}$. It kills a **linear** trend: differencing once turns $\alpha + \beta t$ into the constant $\beta$ (D5), and differencing again turns that constant into zero. In general $(1-B)^{d}$ annihilates any polynomial of degree $d-1$.

**2.** Multiply out and watch it telescope: $(1-B)(1+B+\cdots+B^{11}) = (1 + B + \cdots + B^{11}) - (B + B^2 + \cdots + B^{12}) = 1 - B^{12}$. In words, the second factor $S(B)$ is **a twelve-month running total** — it sums the year. It carries the eleven *seasonal* roots while $(1-B)$ carries the single trend root, and that division of labour is step one of SEATS ([[derivations#D4. The seasonal difference contains the trend difference|D4]]).

**3.** $1/(1-0.8B) = 1 + 0.8B + 0.64B^2 + 0.512B^3 + 0.4096B^4 + \cdots$, so an observation five periods back gets weight $0.8^5 = 0.328$ — about a third. Note this converges only because $|0.8|<1$, which is exactly the stationarity condition.

## 10-02-stationarity-and-roots

**1.** The discriminant is $1.44 - 4(0.5) = -0.56$, so the roots are complex: $z = (1.2 \pm i\sqrt{0.56})/1.0 \cdot \tfrac{1}{2\cdot0.5}$ — do it with `polyroot(c(1, -1.2, 0.5))` rather than by hand. Both roots have modulus $\sqrt{1/0.5} = \sqrt2 \approx 1.414 > 1$, so **yes, stationary**. The general shortcut for AR(2): the roots' modulus is $1/\sqrt{\phi_2}$ when they are complex.

**2.** The roots of $1-B^{12}=0$ are the twelve 12th roots of unity, $e^{2\pi i k/12}$ for $k = 0,\dots,11$, evenly spaced around the circle at 30° intervals. Their frequencies are $k/12$ cycles per month, i.e. periods $\infty, 12, 6, 4, 3, 2.4, 2$ months (with conjugate pairs sharing a period). The $k=0$ root at $B=1$ is the trend; the rest are seasonal.

**3.** Because subtracting a fitted line removes a *deterministic* trend, and a unit root is a *stochastic* one. A random walk has no fixed line to subtract — its "trend" is the accumulated history of shocks and it changes direction permanently at random. Detrending leaves the residual still nonstationary (and, worse, gives it a spurious cycle); only differencing removes it.

## 10-03-ar-processes

**1.** $\phi = 0.9$ wanders slowly, staying on one side of the mean for long stretches — the ACF decays gently. $\phi = -0.9$ **alternates**, flipping sign almost every period, and its ACF alternates too: $\rho_k = (-0.9)^k$. Same persistence in magnitude, opposite character. See the figure in [[10-03-ar-processes]].

**2.** `polyroot(c(1, -1.6, 0.9))` gives a complex pair of modulus $1/\sqrt{0.9} = 1.054$ and argument $\approx 0.5675$ radians, so the period is $2\pi/0.5675 \approx 11.07$ periods. Just outside the unit circle means a long, slowly damping cycle — the snippet in that note prints exactly this.

**3.** Yule–Walker at lags 1 and 2: $\rho_1 = \phi_1 + \phi_2\rho_1$ (using $\rho_{-1}=\rho_1$), which rearranges to $\boxed{\rho_1 = \phi_1/(1-\phi_2)}$; and $\rho_2 = \phi_1\rho_1 + \phi_2$.

## 10-04-ma-processes

**1.** $\rho_1(\theta) = -\theta/(1+\theta^2)$ — the figure in [[10-05-invertibility]] plots it. Both $\theta=0.5$ and $\theta=2$ give $\rho_1 = -0.4$, which is the whole point: they are indistinguishable from the data.

**2.** The MA(2) ACF is nonzero at lags 1 and 2 and **exactly zero** from lag 3 on, because $z_t$ and $z_{t-3}$ share no shock. The PACF decays instead of cutting off — the mirror image of the AR case ([[derivations#D2. The MA(1) autocorrelation, and why it cannot exceed one half|D2]]).

**3.** Differencing a random walk plus noise gives an **MA(1)** with $\rho_1$ **negative** (bounded below by $-0.5$). Negative because differencing over-corrects: the noise term enters two consecutive differences with opposite signs. This is the canonical example of differencing inducing an MA structure, and it is why $d=1$ so often comes with $q=1$.

## 10-05-invertibility

**1.** $\pi_j = \theta^j$. For $\theta=0.5$: $0.5, 0.25, 0.125, \dots$ — dead by lag 8. For $\theta=0.95$: $0.95, 0.90, 0.86, \dots, 0.66$ — still substantial at lag 8. Near the boundary the model has very long memory, which is why estimation there is delicate.

**2.** You get $\theta \approx 1$, pinned at the invertibility boundary, because differencing white noise creates an exactly non-invertible MA(1). Repeating it, the estimate lands at or near 1 nearly every time. **That pinning is the diagnostic for over-differencing** — when you see $\hat\theta \approx 1$, suspect an unnecessary $d$.

**3.** Over-differencing multiplies the model's MA polynomial by $(1-B)$, which puts a root exactly *on* the unit circle — and a root on the circle is precisely what non-invertibility means.

## 10-06-differencing

**1.** After $\nabla$ alone the trend is gone but a strong annual wave remains; after $\nabla_{12}$ as well it looks stationary. The four-panel figure in [[10-06-differencing]] is exactly this experiment.

**2.** Variance falls at each useful stage and **rises** when you go too far. On `log(ldeaths)` the seasonal difference helps (0.081 → 0.019) and the regular difference then hurts (→ 0.035) — the series wanted $d=0, D=1$, which is what X-13 picks unaided.

**3.** Periods 12, 6, 4, 3, 2.4 and 2 months, plus the infinite-period trend root. `poly_roots(diff_poly(D = 1))` prints all twelve with their periods.

## 10-07-acf-and-pacf

**1.** At $n=300$ the patterns are unmistakable; at $n=60$ they are often not, and honest people misidentify them. **That is the lesson** — identification by eye is a starting point, not a decision procedure, which is why [[10-13-model-selection]] leans on AICC.

**2.** After $\nabla\nabla_{12}$ on log `AirPassengers`, lags **1** and **12** stand out, with a smaller satellite at 13 or 11. Lag 1 comes from $(1-\theta B)$, lag 12 from $(1-\Theta B^{12})$, and the satellite from their product's cross term $\theta\Theta B^{13}$. The picture *is* the airline model's specification.

**3.** Because for a nonstationary series the best single-lag predictor of $z_t$ is essentially $z_{t-1}$ itself: the first partial autocorrelation approaches 1 as the root approaches the unit circle. A PACF starting near 1 and an ACF decaying very slowly are the standard visual cue to difference.

## 10-08-arma-duality

**1.** Equating coefficients in $\phi(B)\psi(B) = \theta(B)$: $\psi_0 = 1$, $\psi_1 = \phi - \theta = 0.3$, and $\psi_j = \phi\psi_{j-1}$ thereafter, so $\psi_j = 0.3 \cdot 0.7^{j-1}$. Check with `ARMAtoMA(ar = 0.7, ma = -0.4, lag.max = 12)` — remembering R's opposite MA sign.

**2.** Symmetrically, $\pi_j$ solves $\theta(B)\pi(B) = \phi(B)$, giving $\pi_1 = \phi - \theta$ and $\pi_j = \theta\pi_{j-1}$. The AR and MA sides swap roles — that is the duality.

**3.** The fitted ARMA(2,2) will show an AR root and an MA root at nearly the same place. That shared factor cancels, the likelihood goes flat along a ridge, and the standard errors inflate. The snippet in that note constructs the case explicitly.

## 10-09-seasonal-arima

**1.** $(1-\phi B)(1-\Phi B^{12}) = 1 - \phi B - \Phi B^{12} + \phi\Phi B^{13}$. Nonzero at lags **1, 12 and 13** — the lag-13 cross term is the one people forget.

**2.** $(0,1,1)(1,0,0)_{12}$ is $(1 - \Phi B^{12})(1-B)z_t = (1-\theta B)a_t$, i.e. $z_t - z_{t-1} = \Phi(z_{t-12} - z_{t-13}) + a_t - \theta a_{t-1}$.

**3.** The ACF after $\nabla\nabla_{12}$ shows spikes at 1 and 12 with satellites at 11 and 13 — the satellites are the signature of the *multiplicative* seasonal structure, and they are what distinguishes it from an additive model with terms at 1 and 12 only.

## 10-10-airline-model

**1.** `arima()` reports roughly $-0.402$ and $-0.557$; flipping sign gives Census $\theta = 0.402$, $\Theta = 0.557$. $\Theta$ near 0.6 says the seasonal pattern **evolves moderately** — high $\Theta$ means a nearly fixed seasonal, low means a rapidly changing one. $\Theta$ is the single most consequential number for how much your published factors will revise.

**2.** $(0.9, 0.95)$ looks more like real economic data: smoother, with a seasonal pattern that holds its shape. $(0.4, 0.6)$ is noisier and its seasonality wanders more visibly.

**3.** With $\Theta = 1$ the seasonal MA root sits on the unit circle and the seasonal pattern becomes **deterministic** — it stops evolving entirely and every January is the same. That limiting case is exactly why $\Theta \to 1$ means "fixed seasonality".

## 10-12-estimation

**1.** ML gives $\Theta = 0.5569$, CSS $0.5724$ — here CSS is *closer* to 1, and CSS's $\theta$ is *lower*. There is no direction to memorise; the point is that the two methods disagree, and they disagree most near the invertibility boundary where seasonal parameters live. Use ML.

**2.** An unmodelled level shift distorts the ARIMA parameters, typically inflating $d$'s apparent need and dragging the MA terms. Adding it as a regressor restores them nearly to their original values. **This is why regARIMA exists**: outliers are removed *before* the ARIMA is estimated, not after ([[50-07-outliers-and-breaks]]).

**3.** Standard errors balloon and may exceed the estimates themselves, because the likelihood surface has a ridge rather than a peak ([[derivations#D13. What the likelihood actually is|D13]]).

## 10-13-model-selection

**1.** The airline model wins or ties on AICC. The extra parameter usually does *not* earn its place — AICC's penalty is stricter than AIC's at these sample sizes, which is the reason to prefer it here.

**2.** Without `fitdf=`, the degrees of freedom are wrong and the p-value is **too large** — the test looks more forgiving than it is. Always pass the number of estimated ARMA parameters.

**3.** Dropping the seasonal MA leaves an obvious spike at $1/12$ in the residual spectrum. That is residual seasonality caught in the frequency domain, and it is the same signal QS formalises ([[50-02-residual-seasonality]]).

## 10-14-forecasting

**1.** The 95% band is already about ±7% at twelve months and keeps widening. The figure in [[10-14-forecasting]] plots it.

**2.** After expanding to ARMA(0,13), `ARMAtoMA` gives $\psi_0 = 1$ then a **constant** $1-\theta = 0.598$ for every horizon inside the first year. They do not decay because $d=1$; with no decay, $\sigma_a^2\sum\psi_j^2$ grows without bound ([[derivations#D14. Forecasting, from the difference equation|D14]]).

**3.** Forecast errors over a smooth stretch are modest; over a turning point they are large and **systematically signed** — the model extrapolates the regime it has seen. That asymmetry is the seed of the entire turning-point problem ([[50-06-turning-points]]).

**4.** The January-1958 factor moves as later data arrives and then settles. You have measured a revision path by hand — which is what [[50-05-revision-history]] automates and what [[20-07-end-filters]] explains.

---

# Module 2 — X-11

## 20-01-moving-averages-as-filters

**1.** The gain is $|1 + 2\cos\omega|/3$, which is **exactly zero** at $\omega = 2\pi/3$ — period 3. Exactly, not approximately: a 3-term average of a period-3 cycle sums one whole cycle, and a full cycle of a sine sums to zero. Every $k$-term average annihilates period $k$ for the same reason.

**2.** An uncentred 12-term average has its effective centre half a step off the observation, so its transfer function is complex and the phase is nonzero — cycles come out shifted in time. Averaging two adjacent 12-term averages (the $2\times12$) recentres it, the weights become symmetric, and the phase collapses to zero ([[derivations#D12. Why a centred $2\times s$ moving average is needed for even $s$|D12]]).

**3.** Convolving filters multiplies their transfer functions, so $|\nu_1\nu_2| = |\nu_1|\,|\nu_2|$ — gains multiply. This is why a cascade of simple filters can be analysed one stage at a time, and it is the fact that makes the X-11 composite filter tractable at all.

## 20-02-the-12-term-ma

**1.** Multiplying $\tfrac12(1+B)$ by $\tfrac1{12}(1+B+\cdots+B^{11})$ gives 13 terms: the interior eleven each get $1/12$ and the two ends get $1/24$. The halved endpoints are the recentring correction, not a rounding artefact — the snippet in that note prints them.

**2.** The gain is exactly zero at all six frequencies $k/12$ — the note verifies this to twelve decimals. Between the zeros the gain rises into small **side lobes**, which is why the filter leaks a little power at non-seasonal frequencies and why X-11 needs more than one pass.

**3.** The sine vanishes (the filter's zero sits exactly on its frequency) and the straight line survives untouched (gain 1 at frequency 0, and the weights sum to 1). A period-**11** cycle does *not* vanish, because 11 is not one of the filter's zeros — it is merely attenuated. Seasonal filters are tuned to exact frequencies, and near-seasonal cycles pass through.

## 20-03-henderson-filters

**1.** The closed form in `R/_x11.R` reproduces the published weights; note they go **negative** near the ends, which is what sharpens the filter relative to a plain average.

**2.** Applying it to $t^0$ through $t^3$ returns them unchanged to machine precision; $t^4$ is not reproduced. That is the design criterion — Henderson filters are chosen to pass cubics exactly while minimising the roughness of the output.

**3.** They differ most at **low** frequencies: H9 passes the annual cycle at gain 0.95, H13 at 0.85, H23 at 0.35. Longer means smoother but slower to react — precisely the trade-off the I/C ratio automates when it picks the length.

**4.** Gain 0.846 at the annual frequency for H13. Applying a Henderson directly to raw data therefore leaves most of the seasonality intact: **it is a low-pass smoother, not a seasonal filter**, and confusing the two is a common error.

## 20-04-seasonal-moving-averages

**1.** Convolving $\tfrac13(1,1,1)$ with $\tfrac15(1,1,1,1,1)$ gives the seven weights $(1,2,3,3,3,2,1)/15$. The snippet prints them.

**2.** The $3\times3$ tracks changes faster; the $3\times5$ is smoother but lags an evolving seasonal pattern. X-11 chooses between them using the moving seasonality ratio, which is exactly this trade-off measured rather than guessed.

**3.** Skipping the centring leaves the seasonal factors with a nonzero mean, so a slow drift leaks from the seasonal into the trend and accumulates. Over ten years it is clearly visible — the same failure as skipping `center = "calendar"` on a holiday regressor ([[50-10-calendar-effects]]).

## 20-05-the-x11-iteration

**1.** About **0.52%** mean through the interior, but up to **4.6%** at the ends. Quote both: a single whole-series number will either flatter or libel the implementation depending on which you pick. The gap *is* the end-filter problem ([[20-07-end-filters]]).

**2.** Yes to both — the recovered composite weights sum to 1 and are symmetric in the interior. Symmetric weights mean zero phase ([[derivations#D11. Why a symmetric filter has zero phase, and an end filter does not|D11]]), which is why X-11 does not displace turning points *in the middle* of a series.

**3.** The notches at the seasonal frequencies are deep but **not infinitely narrow**. Their width is what lets X-11 track evolving seasonality — an infinitely narrow notch would only remove a perfectly fixed seasonal.

**4.** Most of the movement happens between passes 1 and 2; pass 3 changes little and a fourth is not worth it. That is why X-11 stops where it does.

## 20-06-extreme-values

**1.** The seasonal factors for *other* Januaries move, because they are estimated from the same calendar-month series. Down-weighting the spike limits the damage substantially — that is the entire purpose of the step.

**2.** Yes. Extreme values are down-weighted **for estimating the factors**, then the original value is divided by those factors. The spike survives in D11 where it belongs, in the irregular. Down-weighting is not deletion.

**3.** On a clean series, widening the limits changes D11 very little. On a contaminated one it changes it a lot — which is the point: the sigma limits are insurance, cheap when unneeded and valuable when needed.

**4.** An AO regressor removes the spike *before* the ARIMA is fitted, so the model parameters are protected too. Extreme-value replacement only protects the filters. For a known one-off event the AO is the better tool ([[50-07-outliers-and-breaks]]).

## 20-07-end-filters

**1.** The end filter has **zero weight on the future** — it cannot have any, there is no future — so it redistributes that weight onto the past. It is a different filter, not a truncated one.

**2.** The revision path falls sharply over the first year and then flattens. It is the same experiment as the forecasting exercise in [[10-14-forecasting]], seen from the filter side rather than the model side.

**3.** On `AirPassengers`, revisions from concurrent to twelve-months-later average around 1%. On US unemployment they average 0.62% in normal times and 1.11% near recessions ([[50-06-turning-points]]).

**4.** The symmetric filter's phase is exactly 0; the one-sided filter's is not, and it varies with frequency. Frequency-dependent phase means different cycles are displaced by different amounts, which is how end filters move apparent turning points.

## 20-08-x11-arima

**1.** The last twelve months differ visibly; the interior does not. Forecast extension only changes what happens where the symmetric filter runs out.

**2.** Mean absolute revision falls from **1.137% to 0.670%** — a **41% reduction**. Note this only appears once revisions are measured against a *common* target; measure them against different targets and the improvement vanishes into the definition.

**3.** The forecast misses systematically, in the direction of the old regime. This is mechanism 1 of the turning-point problem in isolation, and no amount of model improvement removes it: the information about the turn does not exist yet.

**4.** Higher $\Theta$ means more stable seasonality, better-pinned forecasts, and smaller revisions. The relationship holds across the catalogue, though it is a tendency rather than a law — sample length and outliers matter too.

---

# Module 3 — Spectra and signal extraction

## 30-01-frequency-domain-basics

**1.** The pure sine needs one frequency; the second series needs a harmonic at period 3 as well. Any repeating shape that is not a pure sine requires harmonics, which is why a seasonal has $\lfloor s/2\rfloor$ frequencies and not one.

**2.** A period-1.5 cycle sampled monthly is **aliased** — it appears as a period-3 cycle. Nothing faster than period 2 (the Nyquist frequency) is observable, which is why every spectral plot stops at 0.5 cycles per month.

**3.** $|w|^2 = w\bar w$ is real by construction: the imaginary parts cancel. This identity is where the $\theta(B)\theta(F)$ pairing throughout SEATS comes from — it is a squared modulus, nothing more exotic.

## 30-02-spectral-density

**1.** The raw periodogram is wildly noisy and **does not settle** as $n$ grows — it is an inconsistent estimator. Smoothing with `spans` averages neighbouring ordinates and reveals the flat truth. This is the single most important practical fact about periodograms.

**2.** Summing the periodogram recovers $\gamma_0$; the note verifies it for an AR(1) against $1/(1-\phi^2)$. The spectrum genuinely decomposes the variance across frequencies.

**3.** Peaks at the seasonal frequencies remain after $\nabla\nabla_{12}$ only if the differencing has not fully removed them; what you mainly see is the airline model's characteristic shape. The peaks correspond one-to-one with the ACF spikes at 1 and 12 — same information, different coordinates.

**4.** The seasonal peaks should be **gone** from the adjusted series. If they are not, you have residual seasonality, which is exactly what QS formalises ([[50-02-residual-seasonality]]).

## 30-03-spectrum-of-an-arma

**1.** $\phi = 0.5$ and $0.9$ give power concentrated at **low** frequencies (slow wandering); $\phi = -0.9$ concentrates it at **high** frequencies (rapid alternation). The spectrum shape and the sample path are the same fact.

**2.** The peak sits *near* $2\pi/12$ but not exactly on it: measured peaks are at $f = 0.0760, 0.0825, 0.0835$ for moduli $0.80, 0.92, 0.98$. It converges onto the root frequency only as the modulus approaches 1 — a broad peak is a **biased** estimate of a cycle's period.

**3.** $\theta = 0.5$ gives $f(0) = (1-\theta)^2/2\pi = 0.0398$; $\theta = 1$ gives exactly **0**. Near the circle is not on it.

**4.** The theoretical spectrum reproduces the broad shape of the smoothed periodogram. That agreement *is* what "the model fits" means in the frequency domain.

**5.** They agree to machine precision — the closed form is just a cheaper route to the same function ([[derivations#D6. The spectral density, and the ARMA formula|D6]]).

## 30-04-pseudo-spectrum

**1.** Seven peaks: frequency 0 plus the six seasonal frequencies. On a log axis they are visibly unbounded rather than merely large.

**2.** Higher $\Theta$ gives **narrower** peaks — more stable seasonality, more sharply defined in frequency, and smaller revisions. Same parameter, three descriptions.

**3.** $\theta$ shapes the trend peak the same way $\Theta$ shapes the seasonal ones.

**4.** $(1-B)$ alone has one infinite peak at $\omega=0$; $(1-B^{12})$ has seven, at 0 and the six seasonal frequencies. Compare the root table in [[10-06-differencing]] — same roots, viewed as frequencies.

**5.** A periodogram of finite data cannot show an infinity, but its peaks line up with the pseudo-spectrum's. The infinities are a property of the *model*, not of any dataset.

## 30-05-filters-in-the-frequency-domain

**1.** The gain of $(1-B)$ is $2|\sin(\omega/2)|$, rising from 0 at $\omega=0$ to **2** at $\omega=\pi$. Differencing does not just remove the trend — it **amplifies** high frequencies by up to a factor of two.

**2.** Seven zeros: frequency 0 and the six seasonal frequencies ([[derivations#D7. Why differencing is a filter with zeros where the seasonal lives|D7]]).

**3.** The differenced periodogram is tilted upward — high frequencies amplified, low ones removed. This is why over-differencing makes a series look noisier than it is.

**4.** The real composite filter has notches that are deep but finite in width, and small ripples between them. The ideal notch is unrealisable with finitely many weights; X-11 is a practical approximation to it.

**5.** Symmetric filter: phase exactly 0. One-sided: nonzero and frequency-dependent. The note prints both.

## 30-06-wiener-kolmogorov

**1.** The gain is near 1 at low frequencies (where the random walk dominates) and falls toward 0 at high frequencies (where the noise does). The filter keeps the share of the power that is the signal's.

**2.** More noise pushes the cutoff toward lower frequencies — the filter grows more conservative because less of the data is trustworthy signal.

**3.** The weights are symmetric by construction and decay, but **slowly**: for the airline seasonal filter they are still nonzero at lag 60. That slow decay is the entire problem [[30-07-finite-samples]] exists to solve.

**4.** $\nu_s + \nu_n = 1$ at every frequency, verified to about $10^{-12}$ in the note. Every bit of power is assigned somewhere.

**5.** Add a constant $c$ to $f_n$ and subtract it from $f_s$: the sum is unchanged, so $f_z$ is identical and the data cannot tell the two apart. That is the non-identification the canonical decomposition resolves **by convention** ([[derivations#D9. The canonical decomposition, and why it is a convention|D9]]).

## 30-07-finite-samples

**1.** Far more terms than intuition suggests. For the airline model at $\Theta = 0.557$ the filter needs **331 lags — 27.6 years** — to converge to $10^{-7}$, on a series only 12 years long.

**2.** Renormalising the truncated filter restores gain 1 at $\omega=0$; without it the trend is systematically mis-scaled.

**3.** Truncation produces a **constant offset**, not noise. That is what makes it dangerous: the series looks fine, correlates at 0.999 with the correct answer, and is uniformly wrong.

**4.** The final-observation estimate converges as the extension lengthens, with most of the movement in the first year or two.

**5.** All three coincide, which is the reassuring result: forecast extension, tight truncation and Burman's exact algorithm are three routes to the same filter.

---

## Links

- Back to [[00-Start-Here]] · derivations: [[derivations]] · figures: [[figure-index]]
