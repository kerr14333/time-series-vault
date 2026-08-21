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

## 30-08-filter-theory

**1.** Linearity and time-invariance both hold to machine precision ($10^{-14}$ and exactly 0). Clipping the input first **breaks linearity** immediately, because clipping is not a linear operation — and that is not a contrived example: X-11's extreme-value replacement clips, which is exactly why X-11 as a whole is not an LTI filter ([[20-06-extreme-values]]).

**2.** The output/input ratio is constant along the entire series (standard deviation around $10^{-15}$) and equals $H(f)$ exactly. That constancy *is* the eigenfunction property — it is what makes frequency the natural coordinate system for filters.

**3.** The one-sided Henderson delays by $2.24$ months at period 60 and $1.98$ at period 18. **No single constant correction works**, because a real series mixes frequencies and each is displaced differently. That is the precise reason a concurrent trend estimate lags in a way you cannot simply subtract off.

**4.** Gain of the cascade equals the product of the gains, to six decimals. The cascade is exactly zero wherever *either* filter is zero — so a 3-term and 5-term average in series annihilates periods 3 **and** 5.

**5.** The transition width halves each time $L$ doubles ($0.0357 \to 0.0178 \to 0.0091 \to 0.0047 \to 0.0023 \to 0.0012$), a clean $1/L$. The overshoot does **not** shrink: it settles near **9%** and stays there. Length buys sharpness, never a clean edge.

> [!warning] A measurement trap worth repeating
> Measure the overshoot over the **whole** passband. My first attempt excluded a fixed window around the cutoff, which measures the wrong thing — as $L$ grows the ripple narrows *into* that window, so the overshoot appears to shrink when it does not. The numbers looked like $11, 6.4, 9.9, 3.2, 1.9$ and flatly contradicted the claim beside them.

**6.** X-11's composite gain has shallower, wider notches than a truncated ideal filter, and less ripple. Its designers chose **robustness over sharpness** — a filter that tracks evolving seasonality and does not ring, at the cost of not removing a fixed seasonal perfectly.

**7.** A symmetric filter has zero phase because the sine terms cancel in conjugate pairs, leaving $H$ real. An end filter cannot, because it has no future weights to pair with the past ones — and the cancellation was the whole source of the realness ([[derivations#D11. Why a symmetric filter has zero phase, and an end filter does not|D11]]).

---

# Module 4 — SEATS

## 40-01-unobserved-components-and-reduced-form

**1.** The fitted airline model recovers the reduced form of the structural model — the two are different parameterisations of the same process, which is the whole point of "reduced form". Simulating from components and fitting an ARIMA is the cleanest way to convince yourself.

**2.** Roughly: $\sigma_\eta^2$ (trend innovation) drives $\theta$, $\sigma_\omega^2$ (seasonal innovation) drives $\Theta$, and $\sigma_\varepsilon^2$ (irregular) pushes both toward 1. More noise means more smoothing is optimal, which shows up as MA roots nearer the unit circle.

**3.** With $\sigma_\omega^2 = 0$ the seasonal is **fixed**, and $\Theta \to 1$ — the seasonal MA root lands on the unit circle. That is the same limiting case as [[10-10-airline-model]] exercise 3: $\Theta$ near 1 means seasonality that does not evolve.

**4.** The decomposition recovers the simulated components closely but **not exactly**, and the gap is not estimation error — it is the canonical convention. The truth used whatever variances you chose; SEATS returns the *canonical* split, which makes each component as smooth as possible. Two different admissible decompositions of the same reduced form ([[derivations#D9. The canonical decomposition, and why it is a convention|D9]]).

## 40-02-admissible-decompositions

**1.** On a coarse grid, **25%** admissible; on a fine grid, 27.4%. `AirPassengers` at $(0.402, 0.557)$ sits comfortably inside, in the positive quadrant.

**2.** Moving $\theta$ negative along $\Theta = 0.5$, the **trend** spectrum is the first to go negative. Negative $\theta$ means the model wants a trend rougher than white noise at high frequencies, which no non-negative spectrum can supply.

**3.** Confirmed — `cpi` is the only catalogue failure, and it is the only series with a negative $\theta$ ($-0.086$). Three independent facts agreeing: negative $\theta$, inadmissible, and the only series where X-13 substitutes the model.

**4.** `udg(m, "seatsmdl")` reports a **different** model from the one fitted. X-13 silently replaces an inadmissible model with a nearby admissible one and carries on — worth knowing, because your published factors then come from a model you did not choose.

**5.** With `seats.noadmiss = "no"` you get an error instead of a substitution. Preferable when you want to know, which is most of the time.

**6.** The quarterly region is the same *shape* — positive quadrant admissible, elsewhere not — but the boundary sits differently because there are two seasonal frequencies rather than six ([[30-01-frequency-domain-basics]]).

## 40-03-canonical-decomposition

**1.** $m_T = 0.0514$ and $m_S = 0.0225$ for `AirPassengers`; both are handed to the irregular, whose constant term rises accordingly.

**2.** Each component's spectrum has its minimum shifted to exactly zero. That is the definition of the canonical choice.

**3.** For the trend, the minimum is at $\omega = \pi$ — the highest frequency, where a trend should have least power. **Yes, it is $\pi$**, and that is not an accident: subtracting the minimum makes the trend as smooth as it can be while remaining a valid spectrum.

**4.** The canonical trend is **smoother** — it has had a flat white-noise floor removed. The variance of its second difference is correspondingly lower. Whether that is desirable is a judgement, not a theorem.

**5.** They must, and they do: the canonical shift moves power *between* components without changing the total, so $\nu_T + \nu_S + \nu_I = 1$ still holds at every frequency.

**6.** The largest $m_T + m_S$ belongs to the series with the most white noise in it — the more irregular the series, the more the canonical rule has to move.

## 40-04-partial-fractions-in-b-and-f

**1.** $\theta(B) = 1 - 0.4B$. Its autocovariance sequence is $c_0 = 1 + 0.4^2 = 1.16$ and $c_1 = -0.4$. Hence $(1.16, -0.4)$.

**2.** For $s = 4$: $\deg N = 5$ (the MA is $(1-\theta B)(1-\Theta B^4)$, degree 5), $\deg D_T = 2$, $\deg D_S = 3$. Fewer unknowns than the monthly case, and the linear system is correspondingly smaller.

**3.** The QR solve returns a residual around $6\times10^{-14}$ — the system is exactly determined and well conditioned.

**4.** With $\deg C$ wrong the system is **over- or under-determined** and the residual jumps by many orders of magnitude. This is the useful failure: the residual is a genuine check on your degree bookkeeping, so watch it rather than assuming.

**5.** They sum to 1 and each is finite at $\omega=0$ even though $f_z$ is infinite there, because the filters are **ratios** and the infinity cancels top and bottom ([[derivations#D10. Why the WK filters have no poles|D10]]).

## 40-05-component-models

**1.** Differencing the canonical trend twice gives autocovariances that vanish beyond lag 2 — confirming ARIMA(0,2,2), the local linear trend.

**2.** Applying $S(B)$ to the seasonal leaves autocovariances vanishing beyond lag 11, confirming the 11 MA terms.

**3.** The irregular's autocovariances vanish beyond lag 0 — it is **exactly white**, which is what the canonical convention was designed to produce.

**4.** The trend takes the largest share; the irregular's share is $m_T + m_S$ plus whatever was already there. The exact split depends on $(\theta,\Theta)$.

**5.** Without the canonical step the trend numerator has degree **1** rather than 2 — the canonical subtraction is what raises it, and that is what makes the trend an ARIMA(0,2,2) rather than an ARIMA(0,2,1).

## 40-06-wk-filters-for-the-airline-model

**1.** They sum to 1 at every frequency, verified to about $10^{-12}$.

**2.** $\nu_T(0) = 1.00000$, $\nu_S(2\pi/12) = 0.99993$, $\nu_S(\pi) = 1.00000$. Ownership at the poles is total.

**3.** Higher $\Theta$ gives **narrower** notches. X-11's composite gain is fixed and cannot adapt — that is the deepest difference between the two methods: SEATS tunes the filter to the series, X-11 uses the same one for everybody.

**4.** The seasonal weights have spikes every 12 lags with an envelope decaying roughly like $\Theta^{j/12}$ — one factor of $\Theta$ per year. That is why a high $\Theta$ needs such a long filter.

**5.** 60 lags at $\Theta = 0.3$, **331** at $0.557$, 600+ at $0.9$. The run time of the brute-force implementation is governed entirely by this ([[30-07-finite-samples]]), and it is exactly the cost [[40-09-burman-algorithm]] removes.

**6.** $\nu_S(\pi) = 1$ because for even $s$ the Nyquist frequency **is** a seasonal frequency ($k = s/2$) — it is genuinely seasonal, not a boundary artefact.

## 40-07-implementing-seats-in-r

**1.** s10 0.000%, s11 0.001%, s12 0.012%, s13 0.010% against the Census binary.

**2.** With `max_lag = 60` a constant offset appears. Compare with `normalize = FALSE` on **both** sides — normalisation re-centres the seasonal and therefore *absorbs the very constant you are trying to demonstrate*. Comparing normalised runs makes the bug invisible.

**3.** `co2` has $\Theta = 0.912$, so the rule demands far more lags — and it still matches X-13 once given them. The adaptive rule exists precisely so this works without hand-tuning.

**4.** For $s=4$ the degree bookkeeping shrinks: two seasonal frequencies, shorter polynomials, smaller linear system. The algorithm is unchanged.

**5.** `cpi` fires the admissibility check, as [[40-02-admissible-decompositions]] predicts.

**6.** The cost is in the **filter**, not the forecasting: it is $O(n \times \text{max\_lag})$, and `max_lag` is in the hundreds. Burman replaces that with two $O(n)$ passes ([[40-09-burman-algorithm]]).

## 40-08-validating-against-x13

**1.** See the table in the note.

**2.** `transform.function = "none"` runs X-13 **additive** while our code is multiplicative, producing a ~100% discrepancy that has nothing to do with the algorithm. The lesson generalises: **when a comparison fails by a lot, suspect the harness before the algorithm.**

**3.** With outliers on, the months near detected outliers move. Note `coef()` returns ARIMA terms too, so filter with `grep("^(AO|LS|TC)", ...)` or you will report `MA-Nonseasonal-01` as an outlier.

**4.** The identity holds against the **linearized** series, not the raw one, once regressors are active. Getting this wrong looks like a broken identity when it is a changed definition.

**5.** SEATS vs X-11 differ by **0.760%**; our SEATS vs the Census binary by **0.001%**. The method choice matters roughly **660 times** more than the implementation choice.

## 40-09-burman-algorithm

**1.** With $W = 1$ and $\theta(B) = 1-\theta B$: matching $B^0$ gives $g_0 + \theta^2 g_0 \cdots$ — do it carefully and you get two equations, $2(g_0 - \theta g_1) = 1$ at lag 0 and $-\theta g_0 + g_1 = 0$ at lag 1, so $g_1 = \theta g_0$ and $g_0 = 1/[2(1-\theta^2)]$.

**2.** The identity holds to about $7\times10^{-15}$. Perturb any $g_j$ and it fails immediately — which is why this check is worth running before trusting anything downstream.

**3.** Amplitude 1 at $\omega = 2\pi/12$, amplitude 0 at $\omega=0$. The recursions reproduce $\nu_S$ exactly.

**4.** Without extension the first and last few dozen observations are visibly wrong — far more than the length of $g$, because the error comes from the **recursion's zero start**, not from the filter's reach. That is precisely the gap Burman's exact starting values close.

**5.** Trend and seasonal from the same machinery sum to the series minus the irregular, by construction.

**6.** The brute-force cost is in applying hundreds of filter weights at every time point, not in the forecasting. Burman avoids it by replacing the convolution with two recursions.

## 40-10-general-seats

**1.** The seasonal polynomial matches to $2\times10^{-14}$; the trend to only $2\times10^{-8}$. Not a bug: $(1-B)^2$ has a **double root** at $B=1$, and root-finding at a repeated root loses about half the available precision — you get $\sqrt{\varepsilon}$ rather than $\varepsilon$. The hard-coded split knows the answer algebraically; the general one has to find it numerically and cannot match that.

**2.** A 6-month period is exactly the second seasonal frequency ($k=2$), so those roots are classified **seasonal** — correctly. This is the case where the tolerance matters: a root at period 6.5 would fall outside `tol_frac` and become transitory instead.

**3.** With `tol_frac` small, a root slightly off a seasonal frequency is called transitory; widen it and the same root becomes seasonal. There is no natural cutoff — this is a **modelling choice**, and the honest response is to look at the classification table rather than trusting a default.

**4.** For `unemp` with $(1,1,1)(0,1,1)$: 12 seasonal roots and 2 trend. Note the AR(1) coefficient is $-0.50$, giving a real **negative** root, whose frequency is $\pi$ — the Nyquist frequency, which for even $s$ *is* a seasonal frequency. So it is correctly seasonal, and if you had classified by "stationary AR goes to the trend" you would have got it wrong.

**5.** Yes. The partial fraction is solved as a least-squares system with one numerator block per denominator, so additional components just add blocks. Residuals stay around $10^{-12}$.

**6.** `sunspots` has an 11-year cycle at about $1/132$ cycles per month — far from zero and far from any $k/12$ — so with a model that captures it, it lands in the **transitory** component. It is the clearest real example, and note it is also a series with *no seasonality at all* ([[50-01-is-there-seasonality]]).

**7.** Most of it. The trend gap between the general and hard-coded routes is $1.3\times10^{-5}$, while the hard-coded route matches X-13 to $3\times10^{-6}$ — so the general implementation's error is roughly four times the total error of the special-case one, and it enters at the root-finding step.

---

# Module 5 — Diagnostics and practice

## 50-01-is-there-seasonality

**1.** `sunspots` fails every seasonality test the others pass. Its 11-year cycle is real but is **not seasonal** — it does not sit at $k/12$.

**2.** SEATS mode refuses; X-11 mode **produces factors anyway**. That asymmetry matters: X-11 will happily "adjust" a series with no seasonality, and nothing in its output says so. Test first.

**3.** The sunspot spectrum has a large peak at about $1/132$ cycles per month (11 years) and nothing at $k/12$. Being cyclical is not being seasonal.

**4.** Adjusting noise makes it **worse** — the adjusted series has *higher* variance than the original, because you have subtracted an estimated pattern that was not there. This is the cleanest argument for testing before adjusting.

**5.** Detection degrades sharply below about 5 years. Short series are exactly where you most want a diagnostic and least able to run one.

## 50-02-residual-seasonality

**1.** Low-$\Theta$ series are least clean — fast-evolving seasonality is hardest to remove completely.

**2.** The spectrum of the adjusted series should have no peaks at $k/12$. QS is a formal version of exactly that visual check.

**3.** A long, slow filter (`s3x9`) on fast-evolving seasonality leaves residual seasonality behind. This is the filter-choice failure made deliberate.

**4.** A seasonal **break** is caught by sliding spans and often missed by QS, because QS asks whether seasonality remains *on average* over the whole span, not whether it changed partway through.

**5.** Adjusting components separately and summing does **not** generally equal adjusting the sum — the "indirect versus direct" problem. Neither is universally right; agencies choose and document.

## 50-03-m-and-q-statistics

**1.** `sunspots` fails badly on the M statistics that measure the seasonal's contribution to variance — there is no seasonal to contribute.

**2.** Q below 1 with significant QS on the adjusted series means **the adjustment looks well-behaved but left seasonality behind**. Q is a composite of eleven things and can average away a specific failure. Never rely on Q alone.

**3.** M8–M11 (the seasonal-stability group) move most, because they are precisely what the seasonal filter choice affects.

**4.** SEATS mode produces **no M or Q statistics at all** — they are X-11 diagnostics, defined in terms of X-11's tables. Comparing methods on Q is therefore impossible by construction.

**5.** M7 crosses 1 as a series shortens, typically within a few years of data. Short series fail diagnostics that longer versions of the same series pass.

## 50-04-sliding-spans

**1.** **2.08%** of months flagged (2 of 96) for `AirPassengers` — comfortably passing the 15% threshold.

**2.** `UKgas` **40.62%** and `JohnsonJohnson` **18.75%** — both fail. Both are quarterly, so each span holds a quarter as many observations, and both have genuinely evolving seasonality. The flag rate does track $\Theta$, but sample size per span matters at least as much.

**3.** An outlier near a span boundary makes the flag rate jump, because it is in some spans and not others. Modelling it as an AO settles it — which is the argument for outlier detection *before* stability diagnostics.

**4.** X-13 reports `sspans = "failed"` when the series is too short — `accdeaths` and `ldeaths` at 6 years both fail. The diagnostic needs enough data for four overlapping spans of 8–11 years.

**5.** A series can pass Q (the adjustment looks tidy) yet fail sliding spans (the answer is not robust to which window you use). Q measures the quality of one adjustment; sliding spans measure whether that adjustment is stable.

## 50-05-revision-history

**1.** The difference between concurrent and full-sample estimates, month by month, is the revision history.

**2.** The **tail is much bigger than the mean** — the 95th percentile is several times the average. Quoting a mean revision understates what a user will occasionally experience.

**3.** 1.137% → 0.670%, a **41% reduction**, measured against a shared reference. Measure against different references and the improvement disappears into the definition.

**4.** Revision size decays with extra data, most of it in the first year or two.

**5.** SEATS usually revises slightly less when the model fits well, and the advantage disappears when it does not. The model-based method is only as good as the model.

## 50-06-turning-points

**1.** 1.112% within a year of a recession versus 0.620% elsewhere, a ratio of **1.79×**.

**2.** The revisions are **systematically signed** during 2008–10 (mean $-0.313\%$ versus $+0.071\%$ elsewhere). A systematic sign means the concurrent estimate is **biased**, not merely noisy — the forecast extrapolated the old regime. That is mechanism 1, visible directly.

**3.** SEATS does not rescue you at a turn. Both methods need future data they do not have.

**4.** Trend curvature gives 1.42× with correlation 0.083 — much weaker than the 1.79× from actual recession dates. **A weak result can mean the effect is absent, or that your operationalisation is bad.** Check which before concluding "no effect".

**5.** The false-signal rate — concurrent month-to-month change having the opposite sign to the final one — is substantial, and worse near turns. It is the practical reason not to read single months.

## 50-07-outliers-and-breaks

**1.** A **level shift** does most damage to the seasonal factors, because it is a permanent change that the filters try to absorb into the seasonal and trend. An AO is a single point and much easier to contain.

**2.** Modelling an LS as an AO leaves the break in the trend — the level genuinely changed and a one-point correction cannot represent that. The trend after the break is wrong by roughly the size of the shift.

**3.** Lowering `outlier.critical` finds more outliers; each one removed changes D11 a little. There is no free lunch: a low threshold risks removing genuine movement, a high one leaves contamination.

**4.** Detection near the **end** of a series is unreliable, because there is no future data to establish that the level stayed shifted. And you may not want it to fire: an LS detected in the final months is indistinguishable from the start of a genuine turn.

**5.** Sliding spans catch a seasonal break; QS does not, for the reason in 50-02 exercise 4.

## 50-08-covid

**1.** Untreated, a COVID-scale shock contaminates the seasonal factors for **years** in both directions — the filters are two-sided, so damage propagates backwards as well as forwards.

**2.** Treating the shock as AOs removes most of the contamination. This is what statistical agencies actually did in 2020.

**3.** An LS is wrong if the level recovered, and right if it did not — which was genuinely unclear in 2020 and is the reason different agencies made different choices.

**4.** Excluding the shock from the estimation span while still publishing those months is often the cleanest option: the model never sees the anomaly, but the data is not hidden.

**5.** The reach is measured in **years**, not months. That is the practical consequence of a symmetric filter: a single extreme point is smeared across its whole width.

## 50-09-x11-vs-seats

**1.** The methods differ most on **low-$\Theta$** series — fast-evolving seasonality, where SEATS adapts its filter and X-11 cannot.

**2.** `imp`'s worst month is Chinese New Year: a moving holiday, not an outlier or a break ([[50-10-calendar-effects]]).

**3.** For `UKgas` the difference is visible in the statistics but hard to see by eye. Most of the time the two methods agree far more than the debate between them suggests.

**4.** Neither method wins on revisions in general; it depends on model fit.

**5.** Fitting the correct $d=0$ model to `ldeaths` brings the methods closer. Much of the apparent method difference is really a model-specification difference wearing a disguise.

## 50-10-calendar-effects

**1.** Easter[1] is significant for `AirPassengers` ($+0.0234$, $t = 2.63$, $p = 0.0086$) and absent for `unemp` ($p = 0.60$).

**2.** The CNY coefficient is $-0.1230$ with $t = -7.52$ — imports fall about **12%** in the run-up as factories close.

**3.** AICC is best at $-3\ldots0$ (3062.97) and degrades monotonically to $-28\ldots0$ (3093.96), while the coefficient barely moves. A longer window **dilutes the same effect over more months** rather than finding a different one.

**4.** Skipping `center = "calendar"` changes the published seasonal factors by up to **6.06%**. The uncentred regressor has mean $1/12$ instead of 0, overlaps the seasonal pattern, and the split between them becomes arbitrary.

**5.** Diwali on `iip` is $-0.0333$, $t = -4.03$ — real, and about a quarter the size of CNY's.

**6.** February and March move most, since that is where Chinese New Year lands. **Every economy has its own moving holidays** — use the one that belongs to the series, not the one you happen to know.

---

## Links

- Back to [[00-Start-Here]] · derivations: [[derivations]] · figures: [[figure-index]]
