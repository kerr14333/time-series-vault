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


**Going further.**

**GF1.** $(1-B)(1+B) = 1 - B^2$, so it takes $z_t - z_{t-2}$. On an alternating series $z_t = z_{t-2}$ exactly, so the result is **identically zero** — the operator annihilates period-2 cycles. Its zero sits at the Nyquist frequency.

**GF2.** It does **not** vanish. $(1-B^{12})$ has zeros only at frequencies $k/12$, and a period-11 cycle is not one of them — it is attenuated, not removed. Differencing operators are tuned to *exact* frequencies, which is why a series whose period drifts (a moving holiday, say) is not fixed by seasonal differencing ([[50-10-calendar-effects]]).

**GF3.** $(1-B)^3 = 1 - 3B + 3B^2 - B^3$, killing any quadratic. It annihilates $t^2$ exactly and leaves a constant from $t^3$. In general $(1-B)^d$ kills polynomials of degree $d-1$.

**Practice set.**

**P1.** $(1-B)(1-B^4) = 1 - B - B^4 + B^5$ (4 terms); $(1-B)^2(1-B^{12}) = 1 - 2B + B^2 - B^{12} + 2B^{13} - B^{14}$ (6); $(1-B^{12})^2 = 1 - 2B^{12} + B^{24}$ (3).

**P2.** $1, 0.5, 0.25, 0.125, 0.0625, 0.03125$ — it drops below 0.05 at lag **5**.

**P3.** $(1-B)(1-B^{12})$ — the airline differencing. The four-term left side is its signature.

**P4.** $(1-B)(1-B^7)$. Nothing about the algebra is monthly; only the period changes.
## 10-02-stationarity-and-roots

**1.** The discriminant is $1.44 - 4(0.5) = -0.56$, so the roots are complex: $z = (1.2 \pm i\sqrt{0.56})/1.0 \cdot \tfrac{1}{2\cdot0.5}$ — do it with `polyroot(c(1, -1.2, 0.5))` rather than by hand. Both roots have modulus $\sqrt{1/0.5} = \sqrt2 \approx 1.414 > 1$, so **yes, stationary**. The general shortcut for AR(2): the roots' modulus is $1/\sqrt{\phi_2}$ when they are complex.

**2.** The roots of $1-B^{12}=0$ are the twelve 12th roots of unity, $e^{2\pi i k/12}$ for $k = 0,\dots,11$, evenly spaced around the circle at 30° intervals. Their frequencies are $k/12$ cycles per month, i.e. periods $\infty, 12, 6, 4, 3, 2.4, 2$ months (with conjugate pairs sharing a period). The $k=0$ root at $B=1$ is the trend; the rest are seasonal.

**3.** Because subtracting a fitted line removes a *deterministic* trend, and a unit root is a *stochastic* one. A random walk has no fixed line to subtract — its "trend" is the accumulated history of shocks and it changes direction permanently at random. Detrending leaves the residual still nonstationary (and, worse, gives it a spurious cycle); only differencing removes it.


**Going further.**

**GF1.** Roots at $B = 1$ and $B = 1/0.9 = 1.111$: it factors as $(1-B)(1-0.9B)$. So there is an exact **unit root** and it is **not** stationary — the near-1 coefficient sum ($1.9 - 0.9 = 1$) is the giveaway. Whenever the AR coefficients sum to 1, $B=1$ is a root.

**GF2.** Four roots, at frequencies $0, 1/4, 1/4, 1/2$ cycles per quarter — the trend root plus a complex pair at the annual cycle plus one at Nyquist. Two seasonal frequencies rather than six ([[30-01-frequency-domain-basics]]).

**GF3.** It looks like a random walk, and no plot can separate $\phi = 0.999$ from $\phi = 1$ at $n = 500$. Unit-root tests have **low power** near the boundary, which is why $d$ is usually chosen by a mix of testing, variance comparison and judgement rather than by a test alone.

**Practice set.**

**P1.** Roots $1/\phi$: $2, 1.25, 1.053, 1.010, 1.000$. Moduli the same (all real). Stationary for the first four, not the last.

**P2.** `polyroot(c(1,-0.6,-0.3))` gives real roots at $1.0817$ and $-3.0817$. Both moduli exceed 1, so **stationary** — but the first only just, so expect slow decay. Real roots rather than complex means decay without a cycle.

**P3.** **Not stationary** — modulus below 1 means the root is inside the circle. The series will wander without returning to a mean.

**P4.** Stationary but only just, so it shows a long, slowly damping 30-period cycle. Just outside the circle is where cycles look most persistent.

**P5.** $\phi$ is two standard errors from 1, so you cannot reject a unit root. **Difference** — and note this is exactly the low-power situation where tests are weakest.

**P6.** The root at $B = 1$, frequency zero. The SEATS AR split depends on it: $(1-B)(1-B^{12}) = (1-B)^2 S(B)$, which is why the trend gets differenced twice ([[derivations#D4. The seasonal difference contains the trend difference|D4]]).
## 10-03-ar-processes

**1.** $\phi = 0.9$ wanders slowly, staying on one side of the mean for long stretches — the ACF decays gently. $\phi = -0.9$ **alternates**, flipping sign almost every period, and its ACF alternates too: $\rho_k = (-0.9)^k$. Same persistence in magnitude, opposite character. See the figure in [[10-03-ar-processes]].

**2.** `polyroot(c(1, -1.6, 0.9))` gives a complex pair of modulus $1/\sqrt{0.9} = 1.054$ and argument $\approx 0.5675$ radians, so the period is $2\pi/0.5675 \approx 11.07$ periods. Just outside the unit circle means a long, slowly damping cycle — the snippet in that note prints exactly this.

**3.** Yule–Walker at lags 1 and 2: $\rho_1 = \phi_1 + \phi_2\rho_1$ (using $\rho_{-1}=\rho_1$), which rearranges to $\boxed{\rho_1 = \phi_1/(1-\phi_2)}$; and $\rho_2 = \phi_1\rho_1 + \phi_2$.


**Going further.**

**GF1.** The ACF is zero at all **odd** lags and decays like $0.8^{k/2}$ at even lags. The process links $z_t$ to $z_{t-2}$ only, so odd lags carry no direct dependence — it behaves like two interleaved AR(1) series.

**GF2.** It **explodes** — values grow without bound. Stationarity is not a technicality but the condition under which the process has a finite variance at all ([[derivations#D1. Stationarity means roots outside the unit circle|D1]]).

**GF3.** The fitted $\phi$ lands near $\rho_1 = \phi_1/(1-\phi_2)$, not near $\phi_1$. The **residual ACF still shows structure** at lag 2 — that is the diagnostic, and it is why you check residuals rather than trusting a good-looking fit.

**Practice set.**

**P1.** $\rho_k = \phi^k$. For 0.3: $0.3, 0.09, 0.027, 0.008, 0.002$. For 0.9: $0.9, 0.81, 0.73, 0.66, 0.59$ — still substantial at lag 5.

**P2.** $\rho_1 = \phi_1/(1-\phi_2) = 0.5/0.7 = 0.714$; $\rho_2 = \phi_1\rho_1 + \phi_2 = 0.357 + 0.3 = 0.657$.

**P3.** **AR(2)** — the PACF cutting off names both the order and the type.

**P4.** Add a **seasonal** term ($P$ or $Q$ at lag 12). A bigger $p$ would need twelve AR coefficients to reach lag 12; the seasonal parameterisation needs one.
## 10-04-ma-processes

**1.** $\rho_1(\theta) = -\theta/(1+\theta^2)$ — the figure in [[10-05-invertibility]] plots it. Both $\theta=0.5$ and $\theta=2$ give $\rho_1 = -0.4$, which is the whole point: they are indistinguishable from the data.

**2.** The MA(2) ACF is nonzero at lags 1 and 2 and **exactly zero** from lag 3 on, because $z_t$ and $z_{t-3}$ share no shock. The PACF decays instead of cutting off — the mirror image of the AR case ([[derivations#D2. The MA(1) autocorrelation, and why it cannot exceed one half|D2]]).

**3.** Differencing a random walk plus noise gives an **MA(1)** with $\rho_1$ **negative** (bounded below by $-0.5$). Negative because differencing over-corrects: the noise term enters two consecutive differences with opposite signs. This is the canonical example of differencing inducing an MA structure, and it is why $d=1$ so often comes with $q=1$.


**Going further.**

**GF1.** $\rho_1$ is **negative** in Census sign: $\rho_1 = (-\theta_1 + \theta_1\theta_2)/(1+\theta_1^2+\theta_2^2) = (-0.5+0.25)/1.5 = -0.167$, and $\rho_2 = -\theta_2/(1+\theta_1^2+\theta_2^2) = -0.333$. Everything past lag 2 is zero.

**GF2.** Impossible: $|\rho_1| \le 1/2$ for every MA(1), maximised at $\theta = \pm1$ ([[derivations#D2. The MA(1) autocorrelation, and why it cannot exceed one half|D2]]). A sample $\rho_1$ of 0.8 **falsifies** the MA(1) class outright.

**GF3.** Differencing twice gives an MA(2) with $\theta$-structure $(1-B)^2$, i.e. an exactly non-invertible model with $\rho_1 = -2/3$ and $\rho_2 = 1/6$. The strong negative $\rho_1$ is the classic over-differencing signature.

**Practice set.**

**P1.** $-\theta/(1+\theta^2)$: $-0.099, -0.4, -0.5, -0.4$. The maximum magnitude is at $\theta = 1$ and equals exactly $0.5$.

**P2.** Denominator $1 + 0.16 + 0.04 = 1.2$. $\rho_1 = (-0.4 + 0.08)/1.2 = -0.267$; $\rho_2 = -0.2/1.2 = -0.167$; $\rho_3 = 0$.

**P3.** MA(1) with a **negative** Census $\theta$ (positive $\rho_1$), around $-0.6$: solve $-\theta/(1+\theta^2) = 0.45$.

**P4.** It rules out **MA(1) entirely** — $|\rho_1| \le 0.5$ for every MA(1). Look at AR or mixed models instead.
## 10-05-invertibility

**1.** $\pi_j = \theta^j$. For $\theta=0.5$: $0.5, 0.25, 0.125, \dots$ — dead by lag 8. For $\theta=0.95$: $0.95, 0.90, 0.86, \dots, 0.66$ — still substantial at lag 8. Near the boundary the model has very long memory, which is why estimation there is delicate.

**2.** You get $\theta \approx 1$, pinned at the invertibility boundary, because differencing white noise creates an exactly non-invertible MA(1). Repeating it, the estimate lands at or near 1 nearly every time. **That pinning is the diagnostic for over-differencing** — when you see $\hat\theta \approx 1$, suspect an unnecessary $d$.

**3.** Over-differencing multiplies the model's MA polynomial by $(1-B)$, which puts a root exactly *on* the unit circle — and a root on the circle is precisely what non-invertibility means.


**Going further.**

**GF1.** `arima()` reports $\theta = 0.3$, the **invertible** root. Both give identical likelihoods, so the optimiser is not choosing on fit — the convention is built into the parameterisation.

**GF2.** Without the extra difference $\hat\theta \approx 0$; with it, $\hat\theta \approx 1$, pinned at the boundary. That pinning is the standard diagnostic for an unnecessary $d$.

**GF3.** The data cannot distinguish $\theta$ from $1/\theta$ — they produce identical autocorrelations and identical likelihoods. Invertibility is the rule we adopt to pick one, chosen because it makes the distant past matter less than the recent past.

**Practice set.**

**P1.** $\pi_j = \theta^j$. For 0.2: $0.2, 0.04, 0.008, \dots$ (dead by lag 3). For 0.9: $0.9, 0.81, 0.73, 0.66, 0.59$ — still large.

**P2.** Roots $1/0.4 = 2.5$ (outside, **invertible**) and $1/2.5 = 0.4$ (inside, **not**). The pair $\{0.4, 2.5\}$ is the classic reciprocal pair.

**P3.** Over-differencing. Check whether $d$ or $D$ is one too many by comparing variances at each differencing stage ([[10-06-differencing]]).

**P4.** They are reciprocals ($0.6 \times 1.667 = 1$) and give identical autocorrelations, so identical likelihoods. Only the invertible one is reported by convention.

**P5.** **Just stable seasonality.** $\Theta$ near 1 means the pattern barely evolves. It becomes a problem only at exactly 1, and it does mean a very long SEATS filter.

**P6.** The **WK filter derivation**: $\nu_T = A\,D_S/N$ has $N = \theta(B)\theta(F)$ in the denominator, and a non-invertible $\theta$ puts a root on the unit circle, giving the filter a genuine pole ([[derivations#D10. Why the WK filters have no poles|D10]]).
## 10-06-differencing

**1.** After $\nabla$ alone the trend is gone but a strong annual wave remains; after $\nabla_{12}$ as well it looks stationary. The four-panel figure in [[10-06-differencing]] is exactly this experiment.

**2.** Variance falls at each useful stage and **rises** when you go too far. On `log(ldeaths)` the seasonal difference helps (0.081 → 0.019) and the regular difference then hurts (→ 0.035) — the series wanted $d=0, D=1$, which is what X-13 picks unaided.

**3.** Periods 12, 6, 4, 3, 2.4 and 2 months, plus the infinite-period trend root. `poly_roots(diff_poly(D = 1))` prints all twelve with their periods.


**Going further.**

**GF1.** `co2` has a strong trend and stable seasonality, so $d = 1, D = 1$ is the natural guess and is what X-13 picks. Its $\Theta = 0.912$ is very high — nearly fixed seasonality — which is also why its SEATS filter needs so many lags ([[30-07-finite-samples]]).

**GF2.** Variance **rises** with each excess difference, and the ACF develops a large negative spike at lag 1 approaching $-0.5$. Those two symptoms together are the over-differencing signature.

**GF3.** For `UKgas` the same $d=1, D=1$ wins, but for `ldeaths` it does not — that series wants $d=0, D=1$. The rule is not universal, which is the point of checking rather than assuming.

**Practice set.**

**P1.** On `log(AirPassengers)`: none $0.1949$, $(1-B)$ $0.0114$, $(1-B^{12})$ $0.0038$, both $0.0021$. Every difference reduces it here, and note the **seasonal** difference alone achieves more than the regular one — the seasonal swing is the larger share of this series' variance.

**P2.** $1 - 2B + B^2 - B^{12} + 2B^{13} - B^{14}$: lags 0, 1, 2, 12, 13, 14.

**P3.** You have **over-differenced**. Back off, and expect an MA root pinned near 1 if you do not.

**P4.** Difference. That combination is the standard visual signature of a unit root.

**P5.** Compare the variance at each stage and check whether the MA coefficient pins at 1. On `ldeaths` the variance rises with the regular difference, which is X-13 being right.

**P6.** **Two** — $(1-B)$ from the regular difference and one more from inside $(1-B^{12})$. Module 4 needs that count, because the trend component is ARIMA(0,**2**,2) as a direct consequence.
## 10-07-acf-and-pacf

**1.** At $n=300$ the patterns are unmistakable; at $n=60$ they are often not, and honest people misidentify them. **That is the lesson** — identification by eye is a starting point, not a decision procedure, which is why [[10-13-model-selection]] leans on AICC.

**2.** After $\nabla\nabla_{12}$ on log `AirPassengers`, lags **1** and **12** stand out, with a smaller satellite at 13 or 11. Lag 1 comes from $(1-\theta B)$, lag 12 from $(1-\Theta B^{12})$, and the satellite from their product's cross term $\theta\Theta B^{13}$. The picture *is* the airline model's specification.

**3.** Because for a nonstationary series the best single-lag predictor of $z_t$ is essentially $z_{t-1}$ itself: the first partial autocorrelation approaches 1 as the root approaches the unit circle. A PACF starting near 1 and an ACF decaying very slowly are the standard visual cue to difference.


**Going further.**

**GF1.** **Neither cuts off.** An ARMA(1,1) has both an AR and an MA part, so the ACF and PACF both decay. That is precisely why identification by eye fails for mixed models, and why AICC does the work in practice.

**GF2.** A level shift produces a slowly decaying ACF that mimics a **unit root**. You would very likely difference a series that did not need it — the correct fix is to model the shift as an LS regressor first ([[50-07-outliers-and-breaks]]).

**GF3.** At lags 4, 8, 12 rather than 12, 24, 36. The seasonal lag is the *period*, not the number 12.

**Practice set.**

**P1.** $0.289, 0.204, 0.167, 0.115$. Longer series flag smaller correlations as significant.

**P2.** **MA(1).** Whichever function cuts off names the type; here it is the ACF.

**P3.** **ARMA(p,q)** — mixed. Neither cuts off, which is why you need AICC rather than eyes.

**P4.** The **airline model**. Lag 1 from $(1-\theta B)$, lag 12 from $(1-\Theta B^{12})$, and lag 13 from the cross term $\theta\Theta B^{13}$ that the multiplication produces.
## 10-08-arma-duality

**1.** Equating coefficients in $\phi(B)\psi(B) = \theta(B)$: $\psi_0 = 1$, $\psi_1 = \phi - \theta = 0.3$, and $\psi_j = \phi\psi_{j-1}$ thereafter, so $\psi_j = 0.3 \cdot 0.7^{j-1}$. Check with `ARMAtoMA(ar = 0.7, ma = -0.4, lag.max = 12)` — remembering R's opposite MA sign.

**2.** Symmetrically, $\pi_j$ solves $\theta(B)\pi(B) = \phi(B)$, giving $\pi_1 = \phi - \theta$ and $\pi_j = \theta\pi_{j-1}$. The AR and MA sides swap roles — that is the duality.

**3.** The fitted ARMA(2,2) will show an AR root and an MA root at nearly the same place. That shared factor cancels, the likelihood goes flat along a ridge, and the standard errors inflate. The snippet in that note constructs the case explicitly.


**Going further.**

**GF1.** $\psi_1 = \phi - \theta = 0$, and every subsequent weight is $\phi\psi_{j-1} = 0$. So $\psi = (1, 0, 0, \dots)$ — the AR and MA cancel exactly and the process **is white noise**. A shared factor in disguise.

**GF2.** Standard errors inflate dramatically and the optimiser may not converge, because the likelihood has a ridge rather than a peak ([[derivations#D13. What the likelihood actually is|D13]]).

**GF3.** **Not unique** — the $\psi$-weights determine the *ratio* $\theta(B)/\phi(B)$, and any common factor can be inserted or removed without changing it. Recovering $(\phi, \theta)$ requires the additional assumption that they share no root.

**Practice set.**

**P1.** $\psi_1 = \phi - \theta = 0.4$, then $\psi_j = \phi\psi_{j-1}$: $1, 0.4, 0.24, 0.144, 0.086, 0.052$.

**P2.** $\pi_1 = \phi - \theta = 0.4$, then $\pi_j = \theta\pi_{j-1}$: $0.4, 0.08, 0.016, 0.0032, \dots$ — much faster decay, since $\theta < \phi$.

**P3.** A **common factor**. The model is over-ordered; drop one AR and one MA order.

**P4.** **ARMA(1,1)** — two parameters instead of three, and the mixed decay is exactly what an ARMA(1,1) produces. Parsimony, and AICC will usually agree.
## 10-09-seasonal-arima

**1.** $(1-\phi B)(1-\Phi B^{12}) = 1 - \phi B - \Phi B^{12} + \phi\Phi B^{13}$. Nonzero at lags **1, 12 and 13** — the lag-13 cross term is the one people forget.

**2.** $(0,1,1)(1,0,0)_{12}$ is $(1 - \Phi B^{12})(1-B)z_t = (1-\theta B)a_t$, i.e. $z_t - z_{t-1} = \Phi(z_{t-12} - z_{t-13}) + a_t - \theta a_{t-1}$.

**3.** The ACF after $\nabla\nabla_{12}$ shows spikes at 1 and 12 with satellites at 11 and 13 — the satellites are the signature of the *multiplicative* seasonal structure, and they are what distinguishes it from an additive model with terms at 1 and 12 only.


**Going further.**

**GF1.** Lags 0, 1, 2, 12, 13, 14 — the products $\phi\theta$ at lag 2 and $\Phi\theta$ at 13 and $\phi\Phi\theta$ at 14. Multiplicative seasonal models spread across many more lags than the parameter count suggests.

**GF2.** $(1-B)(1-B^4)z_t = (1-\theta B)(1-\Theta B^4)a_t$, i.e. $z_t - z_{t-1} - z_{t-4} + z_{t-5} = a_t - \theta a_{t-1} - \Theta a_{t-4} + \theta\Theta a_{t-5}$. Six terms rather than eight.

**GF3.** The fit is worse, and it shows in the **residual ACF at the satellite lags** (11 and 13). The cross term is not decoration — it is what makes the model multiplicative.

**Practice set.**

**P1.** $1 - 0.3B - 0.7B^{12} + 0.21B^{13}$: lags 1 ($-0.3$), 12 ($-0.7$), 13 ($+0.21$).

**P2.** $1 - 0.3B - 0.7B^4 + 0.21B^5$: lags 1, 4, 5. Same structure, shorter reach.

**P3.** A **seasonal MA** term, $\Theta$ at lag 12.

**P4.** Rarely, and only if the residual ACF shows a clean lag-12 spike with **no** satellites at 11 and 13. The satellites are the evidence for multiplicative structure.
## 10-10-airline-model

**1.** `arima()` reports roughly $-0.402$ and $-0.557$; flipping sign gives Census $\theta = 0.402$, $\Theta = 0.557$. $\Theta$ near 0.6 says the seasonal pattern **evolves moderately** — high $\Theta$ means a nearly fixed seasonal, low means a rapidly changing one. $\Theta$ is the single most consequential number for how much your published factors will revise.

**2.** $(0.9, 0.95)$ looks more like real economic data: smoother, with a seasonal pattern that holds its shape. $(0.4, 0.6)$ is noisier and its seasonality wanders more visibly.

**3.** With $\Theta = 1$ the seasonal MA root sits on the unit circle and the seasonal pattern becomes **deterministic** — it stops evolving entirely and every January is the same. That limiting case is exactly why $\Theta \to 1$ means "fixed seasonality".


**Going further.**

**GF1.** Stable seasonality means $\Theta$ **near 1**. `co2` at $0.912$ is the catalogue's clearest example; `UKgas` and `JohnsonJohnson`, whose seasonality evolves, are much lower and are exactly the two that fail sliding spans ([[50-04-sliding-spans]]).

**GF2.** `co2` has the highest $\Theta$ and the most stable seasonality; the quarterly series the least. See [[series-catalogue]].

**GF3.** It has two parameters, one controlling how fast the trend moves and one how fast the seasonal evolves — which is the minimum needed to describe most economic series. It fits an enormous range of data adequately, and when it does not, the diagnostics say so.

**Practice set.**

**P1.** See [[series-catalogue]]. `AirPassengers` gives $(0.402, 0.557)$; `co2` has the highest $\Theta$ at $0.912$.

**P2.** Very stable seasonality that barely evolves; **small revisions**, because the forecast extension is well pinned.

**P3.** Fast-evolving seasonality; **large revisions**, and a candidate to fail sliding spans.

**P4.** Add an MA or AR term at lag 2, or reconsider the differencing. A spike at lag 2 is a non-seasonal structure the airline model has no parameter for.
## 10-12-estimation

**1.** ML gives $\Theta = 0.5569$, CSS $0.5724$ — here CSS is *closer* to 1, and CSS's $\theta$ is *lower*. There is no direction to memorise; the point is that the two methods disagree, and they disagree most near the invertibility boundary where seasonal parameters live. Use ML.

**2.** An unmodelled level shift distorts the ARIMA parameters, typically inflating $d$'s apparent need and dragging the MA terms. Adding it as a regressor restores them nearly to their original values. **This is why regARIMA exists**: outliers are removed *before* the ARIMA is estimated, not after ([[50-07-outliers-and-breaks]]).

**3.** Standard errors balloon and may exceed the estimates themselves, because the likelihood surface has a ridge rather than a peak ([[derivations#D13. What the likelihood actually is|D13]]).


**Going further.**

**GF1.** The log-likelihood **must** rise (or stay equal) — adding a parameter cannot fit worse. AICC usually **falls in quality**, i.e. gets worse, because the improvement does not cover the penalty. Distinguishing the two is the whole point of using a criterion rather than the likelihood.

**GF2.** Standard errors become enormous and $\Theta$ is essentially unidentified — two years of data cannot pin down how a seasonal pattern evolves. No, do not trust it.

**GF3.** A grid search finds the same optimum, more slowly. Worth doing once: it makes concrete that `optim` is a convenience, not part of the method.

**Practice set.**

**P1.** They differ by a few hundredths, most visibly near the invertibility boundary. Use ML.

**P2.** $\mathrm{AIC} = -2\log L + 2k$; $\mathrm{AICC} = \mathrm{AIC} + 2k(k+1)/(n-k-1)$. Both match the built-ins exactly.

**P3.** For the airline model on `AirPassengers` both $|t|$ exceed 4. A $|t|$ below 2 means the data does not support that term.

**P4.** $t \approx 1.02$: **not supported**. Drop the term unless theory demands it.

**P5.** The optimiser hit its iteration limit without converging. Try better starting values, a simpler model, or check for a common factor.

**P6.** Differencing consumed $d + D\cdot s = 1 + 12 = 13$ observations. This is why likelihoods are **not comparable** across models with different differencing.

**P7.** Either — 0.4 is well inside the noise. Prefer the simpler one, and let residual diagnostics break the tie.

**P8.** An **outlier or level shift near the end**. One observation should not move a seasonal parameter that far ([[50-07-outliers-and-breaks]]).

**P9.** $\sigma_a^2$, which has a closed form given the other parameters and is *concentrated out*. That is why the airline search is two-dimensional and can simply be plotted.
## 10-13-model-selection

**1.** The airline model wins or ties on AICC. The extra parameter usually does *not* earn its place — AICC's penalty is stricter than AIC's at these sample sizes, which is the reason to prefer it here.

**2.** Without `fitdf=`, the degrees of freedom are wrong and the p-value is **too large** — the test looks more forgiving than it is. Always pass the number of estimated ARMA parameters.

**3.** Dropping the seasonal MA leaves an obvious spike at $1/12$ in the residual spectrum. That is residual seasonality caught in the frequency domain, and it is the same signal QS formalises ([[50-02-residual-seasonality]]).


**Going further.**

**GF1.** The airline model wins, typically by a few AICC units. The extra MA term buys very little log-likelihood and costs a full penalty.

**GF2.** AIC's penalty is $2k$; AICC adds $2k(k+1)/(n-k-1)$, which at $n=60$ is substantial. AIC will tend to pick the **bigger** model, which is the over-fitting AICC was designed to prevent.

**GF3.** On quarterly data the ranking can change, because there are fewer observations per seasonal parameter. Model choice is not portable across frequencies.

**Practice set.**

**P1.** The airline model typically wins or ties. Extra parameters rarely earn their penalty on these series.

**P2.** Without `fitdf` the p-values are **too large** — the test looks more forgiving than it is. Always pass the number of estimated ARMA parameters.

**P3.** Prefer the **simpler** model. AICC differences of a few units are weak evidence, and clean residuals in both means the extra parameter buys nothing you can point to.

**P4.** **B.** A model whose residuals are not white has structure left in them, which will show up in the adjustment; a small AICC edge does not compensate. Change your mind if the AICC gap is large and B's residual failure is marginal.
## 10-14-forecasting

**1.** The 95% band is already about ±7% at twelve months and keeps widening. The figure in [[10-14-forecasting]] plots it.

**2.** After expanding to ARMA(0,13), `ARMAtoMA` gives $\psi_0 = 1$ then a **constant** $1-\theta = 0.598$ for every horizon inside the first year. They do not decay because $d=1$; with no decay, $\sigma_a^2\sum\psi_j^2$ grows without bound ([[derivations#D14. Forecasting, from the difference equation|D14]]).

**3.** Forecast errors over a smooth stretch are modest; over a turning point they are large and **systematically signed** — the model extrapolates the regime it has seen. That asymmetry is the seed of the entire turning-point problem ([[50-06-turning-points]]).

**4.** The January-1958 factor moves as later data arrives and then settles. You have measured a revision path by hand — which is what [[50-05-revision-history]] automates and what [[20-07-end-filters]] explains.

---


**Going further.**

**GF1.** On `log(AirPassengers)` the 95% interval reaches roughly $\pm10\%$ within about 15–18 months. Precision degrades faster than most people expect.

**GF2.** Both the trend extrapolation and the seasonal amplitude degrade, but the **seasonal** holds up better — 3 years is enough to see the pattern three times. It is the trend direction that fails first, which is exactly the turning-point problem in miniature ([[50-06-turning-points]]).

**GF3.** Same structure with $B^4$: $\hat z_{n+1} = z_n + z_{n-3} - z_{n-4} - \theta\hat a_n - \Theta\hat a_{n-3} + \theta\Theta\hat a_{n-4}$. It matches `predict()` to the same precision as the monthly case.

**Practice set.**

**P1.** Standard error grows monotonically: roughly $0.037, 0.061, 0.082$ and larger at 24. It is a cumulative sum of squares and can never fall.

**P2.** After $\psi_0 = 1$ they sit at $1-\theta = 0.598$ and stay there. Non-decay is a consequence of $d = 1$.

**P3.** About $\pm 16\%$ at twelve months ($1.96 \times 0.082$ in logs). Wider than most people expect.

**P4.** **Yes.** $\mathrm{Var}(e_h) = \sigma_a^2\sum_{j<h}\psi_j^2$ with non-decaying $\psi$, so the standard error grows like $\sqrt{h}$ and the width roughly doubles when $h$ quadruples.

**P5.** **Bias.** Noise would change sign; a systematic direction means the model is extrapolating a regime that has ended. Test by checking the sign of the errors, exactly as 50-06 does for revisions.

**P6.** A year is defensible; beyond that quote the interval, not the point. And say plainly that the interval assumes the model stays true — which is what fails at a turn.

**P7.** Forecast extension in [[20-08-x11-arima]], which needs about a year so the symmetric filter has data to work with at the end.

**P8.** Because non-decaying $\psi$-weights mean the *filter* weights also decay slowly, so the WK filter needs hundreds of lags and the truncation question becomes serious.
# Module 2 — X-11

## 20-01-moving-averages-as-filters

**1.** The gain is $|1 + 2\cos\omega|/3$, which is **exactly zero** at $\omega = 2\pi/3$ — period 3. Exactly, not approximately: a 3-term average of a period-3 cycle sums one whole cycle, and a full cycle of a sine sums to zero. Every $k$-term average annihilates period $k$ for the same reason.

**2.** An uncentred 12-term average has its effective centre half a step off the observation, so its transfer function is complex and the phase is nonzero — cycles come out shifted in time. Averaging two adjacent 12-term averages (the $2\times12$) recentres it, the weights become symmetric, and the phase collapses to zero ([[derivations#D12. Why a centred $2\times s$ moving average is needed for even $s$|D12]]).

**3.** Convolving filters multiplies their transfer functions, so $|\nu_1\nu_2| = |\nu_1|\,|\nu_2|$ — gains multiply. This is why a cascade of simple filters can be analysed one stage at a time, and it is the fact that makes the X-11 composite filter tractable at all.


**Going further.**

**GF1.** Zeros at $f = 1/5$ and $2/5$ — a $k$-term average annihilates period $k$ and its harmonics, because it sums whole cycles. Its gain is $|\sin(5\pi f)/(5\sin(\pi f))|$.

**GF2.** A flat series comes out multiplied by 1.1. You have violated **gain(0) = 1**, which is the same statement as $\sum w_j = 1$ ([[30-08-filter-theory]]). The filter now changes the level of the data.

**GF3.** A 4-term average, with zeros at $f = 1/4$ and $1/2$ — the two quarterly seasonal frequencies. Being even, it also needs the centring correction.

**Practice set.**

**P1.** Gains fall as the filter lengthens and as frequency rises. At $f=1/3$ the 3-term average is exactly **0** (it spans one whole cycle).

**P2.** A $k$-term average is zero at $f = j/k$ for $j = 1, \dots, k-1$ — that is $k-1$ zeros spread across the range.

**P3.** A **seasonal** filter, or at least one designed to kill the annual cycle: gain 1 at frequency zero preserves the level, near-zero at $1/12$ removes the annual.

**P4.** A **5-term** average, which is exactly zero at $f = 1/5$. It attenuates the annual cycle only mildly, which is what you want.
## 20-02-the-12-term-ma

**1.** Multiplying $\tfrac12(1+B)$ by $\tfrac1{12}(1+B+\cdots+B^{11})$ gives 13 terms: the interior eleven each get $1/12$ and the two ends get $1/24$. The halved endpoints are the recentring correction, not a rounding artefact — the snippet in that note prints them.

**2.** The gain is exactly zero at all six frequencies $k/12$ — the note verifies this to twelve decimals. Between the zeros the gain rises into small **side lobes**, which is why the filter leaks a little power at non-seasonal frequencies and why X-11 needs more than one pass.

**3.** The sine vanishes (the filter's zero sits exactly on its frequency) and the straight line survives untouched (gain 1 at frequency 0, and the weights sum to 1). A period-**11** cycle does *not* vanish, because 11 is not one of the filter's zeros — it is merely attenuated. Seasonal filters are tuned to exact frequencies, and near-seasonal cycles pass through.


**Going further.**

**GF1.** **No.** The filter removes a cycle of *constant* amplitude; a growing one leaves a residue, because within any 13-month window the amplitudes no longer cancel. This is exactly why X-11 iterates rather than filtering once, and why evolving seasonality is the hard case.

**GF2.** A plain 12-term average has its centre half a step off, giving a phase shift of $\pi f$ radians — half a month at every frequency. The centring is what removes it ([[derivations#D12. Why a centred $2\times s$ moving average is needed for even $s$|D12]]).

**GF3.** $(1/8, 1/4, 1/4, 1/4, 1/8)$ — five weights, halved at the ends, with zeros at $f = 1/4$ and $1/2$.

**Practice set.**

**P1.** $1/24$ at each end and $1/12$ for the eleven interior weights: $2(1/24) + 11(1/12) = 1$.

**P2.** **Exactly zero** at all six seasonal frequencies (to twelve decimals) and small but nonzero at $f=0.1$ — the side lobe.

**P3.** The **$2\times12$**. The halves are the recentring correction that even-length filters need so the output sits on an observation ([[derivations#D12. Why a centred $2\times s$ moving average is needed for even $s$|D12]]).

**P4.** A **plain 7-term** average. Seven is odd, so it already centres on an observation and needs no correction.
## 20-03-henderson-filters

**1.** The closed form in `R/_x11.R` reproduces the published weights; note they go **negative** near the ends, which is what sharpens the filter relative to a plain average.

**2.** Applying it to $t^0$ through $t^3$ returns them unchanged to machine precision; $t^4$ is not reproduced. That is the design criterion — Henderson filters are chosen to pass cubics exactly while minimising the roughness of the output.

**3.** They differ most at **low** frequencies: H9 passes the annual cycle at gain 0.95, H13 at 0.85, H23 at 0.35. Longer means smoother but slower to react — precisely the trade-off the I/C ratio automates when it picks the length.

**4.** Gain 0.846 at the annual frequency for H13. Applying a Henderson directly to raw data therefore leaves most of the seasonality intact: **it is a low-pass smoother, not a seasonal filter**, and confusing the two is a common error.


**Going further.**

**GF1.** The **9-term** passes far more: gain 0.952 at the annual frequency against 0.348 for the 23-term. Longer filters are lower-pass, so they suppress more — but they also react more slowly.

**GF2.** The seasonality is **not** gone — gain 0.846 at the annual frequency leaves most of it. And it should not be: a Henderson is a trend smoother, and removing seasonality is the seasonal filter's job. Confusing the two is a common error.

**GF3.** 5-term $(-0.073, 0.294, 0.559, 0.294, -0.073)$ and 7-term as printed by the script. Both reproduce cubics exactly — the design criterion is independent of frequency.

**Practice set.**

**P1.** All sum to 1 — that is gain(0) = 1, the condition that a constant passes untouched.

**P2.** $0.952$ (H9), $0.846$ (H13), $0.348$ (H23). Longer means more suppression.

**P3.** H9 and H13 have 2 negative weights at each end; H23 more. The negatives are what sharpen the filter relative to a plain average.

**P4.** A **high** I/C ratio — a noisy series relative to how fast its trend moves — so X-11 chooses a long, heavy smoother.

**P5.** **Longer.** You give up responsiveness: a longer filter is slower to turn, which matters most exactly where it matters most, at the end of the sample.
## 20-04-seasonal-moving-averages

**1.** Convolving $\tfrac13(1,1,1)$ with $\tfrac15(1,1,1,1,1)$ gives the seven weights $(1,2,3,3,3,2,1)/15$. The snippet prints them.

**2.** The $3\times3$ tracks changes faster; the $3\times5$ is smoother but lags an evolving seasonal pattern. X-11 chooses between them using the moving seasonality ratio, which is exactly this trade-off measured rather than guessed.

**3.** Skipping the centring leaves the seasonal factors with a nonzero mean, so a slow drift leaks from the seasonal into the trend and accumulates. Over ten years it is clearly visible — the same failure as skipping `center = "calendar"` on a holiday regressor ([[50-10-calendar-effects]]).


**Going further.**

**GF1.** A **$3\times3$** — shorter, so it tracks change faster. The moving seasonality ratio measures exactly this trade-off, comparing how fast the seasonal moves against how noisy it is.

**GF2.** Residual seasonality appears, because a long filter averages away the very evolution you needed to track. This is one of the standard causes of a failed QS test ([[50-02-residual-seasonality]]).

**GF3.** It operates on **quarters** — all the Q1s together, all the Q2s, and so on. Nothing about the method is monthly; only the period changes.

**Practice set.**

**P1.** $3\times3$: $(1,2,3,2,1)/9$. $3\times5$: $(1,2,3,3,3,2,1)/15$. $3\times9$ correspondingly longer. All sum to 1.

**P2.** The longer the filter, the lower the gain — it tracks slow change and suppresses fast change, which is the whole trade-off.

**P3.** Very **stable** seasonality: a long filter is appropriate only when the pattern barely evolves.

**P4.** A **shorter** filter — but first check whether it is really a seasonal break, in which case model it rather than filter it ([[50-07-outliers-and-breaks]]).
## 20-05-the-x11-iteration

**1.** About **0.52%** mean through the interior, but up to **4.6%** at the ends. Quote both: a single whole-series number will either flatter or libel the implementation depending on which you pick. The gap *is* the end-filter problem ([[20-07-end-filters]]).

**2.** Yes to both — the recovered composite weights sum to 1 and are symmetric in the interior. Symmetric weights mean zero phase ([[derivations#D11. Why a symmetric filter has zero phase, and an end filter does not|D11]]), which is why X-11 does not displace turning points *in the middle* of a series.

**3.** The notches at the seasonal frequencies are deep but **not infinitely narrow**. Their width is what lets X-11 track evolving seasonality — an infinitely narrow notch would only remove a perfectly fixed seasonal.

**4.** Most of the movement happens between passes 1 and 2; pass 3 changes little and a fourth is not worth it. That is why X-11 stops where it does.


**Going further.**

**GF1.** Much better in the **interior**: 0.52% mean against up to 4.6% at the ends, roughly a factor of nine. Two implementations agree where the symmetric filter applies and diverge where each must improvise.

**GF2.** The trend drifts, because the seasonal factors no longer average to 1 and the residue accumulates into the trend. Over ten years it is clearly visible.

**GF3.** `UKgas` gives 0.75%/0.75%/1.03% for d10/d11/d12 and `JohnsonJohnson` 0.76/0.75/0.92 — as good as monthly, confirming the code is genuinely frequency-general.

**Practice set.**

**P1.** Around 0.5% interior mean for monthly, 0.75% for quarterly. Report interior and ends separately.

**P2.** The loop is in the note's pseudocode block; the checkable part is that steps 4 and 10 both **centre** the seasonal factors, and forgetting either causes drift.

**P3.** You almost certainly compared against the **extreme-value-replaced** series rather than the original. The identity holds against the original $z$.

**P4.** **Ship it.** That is the expected pattern — implementations agree in the interior and diverge at the ends, because each improvises differently where the symmetric filter runs out.

**P5.** The **ratios become differences**: $Z/T$ becomes $Z-T$, and the final combination changes correspondingly. Taking logs converts one to the other.
## 20-06-extreme-values

**1.** The seasonal factors for *other* Januaries move, because they are estimated from the same calendar-month series. Down-weighting the spike limits the damage substantially — that is the entire purpose of the step.

**2.** Yes. Extreme values are down-weighted **for estimating the factors**, then the original value is divided by those factors. The spike survives in D11 where it belongs, in the irregular. Down-weighting is not deletion.

**3.** On a clean series, widening the limits changes D11 very little. On a contaminated one it changes it a lot — which is the point: the sigma limits are insurance, cheap when unneeded and valuable when needed.

**4.** An AO regressor removes the spike *before* the ARIMA is fitted, so the model parameters are protected too. Extreme-value replacement only protects the filters. For a known one-off event the AO is the better tool ([[50-07-outliers-and-breaks]]).


**Going further.**

**GF1.** **Yes, a little.** The Januaries feed the trend, the trend feeds the SI ratios, and the SI ratios feed every month's factor. The effect on July is small but not zero — nothing in X-11 is fully local.

**GF2.** The factors move substantially, and for *other* years' Januaries too. That measured difference is what the extreme-value step buys you.

**GF3.** The weights depend on the data, so scaling the input does not scale the output and the filter is not fixed. Analytically it means you cannot write X-11 as a single transfer function — the 'composite filter' is only its linear part.

**Practice set.**

**P1.** Only observations beyond 1.5 sigma get weight below 1; beyond 2.5 sigma the weight is 0. A single 3-sigma point is fully excluded and its neighbours untouched.

**P2.** Wider limits exclude fewer points. On a clean series this barely matters; on a contaminated one it matters a great deal.

**P3.** It contributes 40% of its value when the seasonal factors are estimated — but the **original value is still divided by those factors**, so it survives in D11. Down-weighting is not deletion.

**P4.** **Model it as an AO.** That removes it before the ARIMA is fitted, protecting the model parameters too; extreme-value replacement protects only the filters ([[50-07-outliers-and-breaks]]).
## 20-07-end-filters

**1.** The end filter has **zero weight on the future** — it cannot have any, there is no future — so it redistributes that weight onto the past. It is a different filter, not a truncated one.

**2.** The revision path falls sharply over the first year and then flattens. It is the same experiment as the forecasting exercise in [[10-14-forecasting]], seen from the filter side rather than the model side.

**3.** On `AirPassengers`, revisions from concurrent to twelve-months-later average around 1%. On US unemployment they average 0.62% in normal times and 1.11% near recessions ([[50-06-turning-points]]).

**4.** The symmetric filter's phase is exactly 0; the one-sided filter's is not, and it varies with frequency. Frequency-dependent phase means different cycles are displaced by different amounts, which is how end filters move apparent turning points.


**Going further.**

**GF1.** **Larger** for the last observation, and it falls sharply moving inward — the last point uses the most asymmetric filter. The revision path flattens after about a year.

**GF2.** Padding with zeros drags the trend violently toward zero in the final year — far worse than an end filter. It shows why X-11 needs *proper* asymmetric weights rather than a truncation.

**GF3.** Worse per observation, because a quarterly year is four points rather than twelve, so the end filter reaches proportionally further into the unknown.

**Practice set.**

**P1.** The gap is largest at the final point and shrinks moving inward, flattening after about a year.

**P2.** The symmetric filter puts about 0.24 on the current observation; the one-sided version must put much more, since it has no future to spread weight over.

**P3.** **Yes, entirely normal.** The last point uses the most asymmetric filter; a point a year back is already using something close to the symmetric one.

**P4.** Last month's figure was an estimate made without knowing what came next. Now that another month exists, the estimate has been updated — that is expected, not an error, and the change gets smaller each month.
## 20-08-x11-arima

**1.** The last twelve months differ visibly; the interior does not. Forecast extension only changes what happens where the symmetric filter runs out.

**2.** Mean absolute revision falls from **1.137% to 0.670%** — a **41% reduction**. Note this only appears once revisions are measured against a *common* target; measure them against different targets and the improvement vanishes into the definition.

**3.** The forecast misses systematically, in the direction of the old regime. This is mechanism 1 of the turning-point problem in isolation, and no amount of model improvement removes it: the information about the turn does not exist yet.

**4.** Higher $\Theta$ means more stable seasonality, better-pinned forecasts, and smaller revisions. The relationship holds across the catalogue, though it is a tendency rather than a law — sample length and outliers matter too.

---


**Going further.**

**GF1.** More on **high-$\Theta$** series: stable seasonality means well-pinned forecasts, so the extension is accurate and the revision it saves is real. Low $\Theta$ means the forecast is itself uncertain.

**GF2.** A wrong model makes things **worse than no extension** — you have replaced missing data with confidently wrong data. Extension is only as good as the model behind it.

**GF3.** In normal times the model's forecast is close to what happens, so the extension supplies nearly the right values. At a turn the model has only seen the old regime, so the extension is wrong in a *systematic direction* — and averaging in systematically wrong values does not help.

**Practice set.**

**P1.** Only the last twelve values differ; the interior is untouched. Extension changes only what the symmetric filter could not reach.

**P2.** 1.137% → 0.670%, a 41% reduction — **measured against a common target**. Against separate targets the improvement vanishes into the definition.

**P3.** Check whether the revisions are measured against a **shared** reference. That definition error is the single most common way this experiment goes wrong.

**P4.** About a year, which is what the symmetric filter needs. More does not help, because the extra values are forecasts of forecasts and carry no new information.
# Module 3 — Spectra and signal extraction

## 30-01-frequency-domain-basics

**1.** The pure sine needs one frequency; the second series needs a harmonic at period 3 as well. Any repeating shape that is not a pure sine requires harmonics, which is why a seasonal has $\lfloor s/2\rfloor$ frequencies and not one.

**2.** A period-1.5 cycle sampled monthly is **aliased** — it appears as a period-3 cycle. Nothing faster than period 2 (the Nyquist frequency) is observable, which is why every spectral plot stops at 0.5 cycles per month.

**3.** $|w|^2 = w\bar w$ is real by construction: the imaginary parts cancel. This identity is where the $\theta(B)\theta(F)$ pairing throughout SEATS comes from — it is a squared modulus, nothing more exotic.


**Going further.**

**GF1.** Weekly $s=52$ gives **26** seasonal frequencies; daily-with-weekly-cycle $s=7$ gives **3**. The rule $\lfloor s/2 \rfloor$ is the whole answer, and it explains why weekly data is so much harder: 26 frequencies to estimate from the same amount of data.

**GF2.** $f = 0.25$ means four months for monthly data and a **full year** for quarterly. Reading 'period 4' off a quarterly spectrum and calling it four months is the error, and it is easy to make.

**GF3.** $k/7$ for $k = 1, 2, 3$: periods 7, 3.5 and $2.33$ days. Note 7 is odd, so the highest is not the Nyquist frequency and no centring correction is needed.

**Practice set.**

**P1.** $\omega = 2\pi f$: $0.314, 0.524, 1.571, 3.142$; periods $20, 12, 4, 2$ time units.

**P2.** $s=4$: two ($0.25, 0.5$). $s=7$: three ($1/7, 2/7, 3/7$). $s=12$: six. The rule is $\lfloor s/2 \rfloor$.

**P3.** **Radians per period** — the giveaway is that the maximum is $\pi \approx 3.14$ rather than 0.5.

**P4.** The **annual** cycle: $1/0.0833 = 12$ months.

**P5.** **Not quite.** $0.09$ is not $k/12$, so it is not seasonal — it is a roughly 11-month cycle, which a seasonal filter will not remove and which may indicate a moving holiday.

**P6.** Because $s=12$ is **even**, so $k = s/2 = 6$ gives $f = 0.5$, the Nyquist frequency, and it is genuinely seasonal. For odd $s$ there is no $k$ with $k/s = 0.5$, so Nyquist is not a seasonal frequency.
## 30-02-spectral-density

**1.** The raw periodogram is wildly noisy and **does not settle** as $n$ grows — it is an inconsistent estimator. Smoothing with `spans` averages neighbouring ordinates and reveals the flat truth. This is the single most important practical fact about periodograms.

**2.** Summing the periodogram recovers $\gamma_0$; the note verifies it for an AR(1) against $1/(1-\phi^2)$. The spectrum genuinely decomposes the variance across frequencies.

**3.** Peaks at the seasonal frequencies remain after $\nabla\nabla_{12}$ only if the differencing has not fully removed them; what you mainly see is the airline model's characteristic shape. The peaks correspond one-to-one with the ACF spikes at 1 and 12 — same information, different coordinates.

**4.** The seasonal peaks should be **gone** from the adjusted series. If they are not, you have residual seasonality, which is exactly what QS formalises ([[50-02-residual-seasonality]]).


**Going further.**

**GF1.** **No** — and this is the key fact about periodograms. More data gives *more* ordinates, each just as noisy; the estimator is **inconsistent**. Only smoothing helps.

**GF2.** The raw periodogram is so noisy that spurious peaks appear everywhere and you will identify structure that is not there. Always smooth, and be honest that the bandwidth is a choice.

**GF3.** A deterministic seasonal gives a spike of essentially **zero width** (infinite in the limit); a stochastic one gives a peak of finite width. Peak *width* is the visual signature of how fast seasonality evolves — the same thing $\Theta$ measures.

**Practice set.**

**P1.** No smoothing is unusable noise; `c(3,3)` is a reasonable compromise; `c(7,7)` is smoother but blurs adjacent peaks.

**P2.** It does, to machine precision — for AR(1) the integral equals $1/(1-\phi^2)$.

**P3.** **White noise.** Flat means every frequency contributes equally, which is the definition.

**P4.** Something like `c(3,3)`. Too much smoothing **merges adjacent seasonal peaks** and can hide residual seasonality — the exact thing you are usually looking for.
## 30-03-spectrum-of-an-arma

**1.** $\phi = 0.5$ and $0.9$ give power concentrated at **low** frequencies (slow wandering); $\phi = -0.9$ concentrates it at **high** frequencies (rapid alternation). The spectrum shape and the sample path are the same fact.

**2.** The peak sits *near* $2\pi/12$ but not exactly on it: measured peaks are at $f = 0.0760, 0.0825, 0.0835$ for moduli $0.80, 0.92, 0.98$. It converges onto the root frequency only as the modulus approaches 1 — a broad peak is a **biased** estimate of a cycle's period.

**3.** $\theta = 0.5$ gives $f(0) = (1-\theta)^2/2\pi = 0.0398$; $\theta = 1$ gives exactly **0**. Near the circle is not on it.

**4.** The theoretical spectrum reproduces the broad shape of the smoothed periodogram. That agreement *is* what "the model fits" means in the frequency domain.

**5.** They agree to machine precision — the closed form is just a cheaper route to the same function ([[derivations#D6. The spectral density, and the ARMA formula|D6]]).


**Going further.**

**GF1.** **High** frequency. $\phi = -0.9$ makes the series alternate, and alternation is high-frequency behaviour. The AR(1) spectrum peaks at $\omega = \pi$ when $\phi < 0$ and at $\omega = 0$ when $\phi > 0$.

**GF2.** Substantially different, and **no, you would not notice**: a flipped-sign spectrum is a perfectly plausible-looking spectrum for a different model. That is exactly why sign conventions are dangerous — the failure is silent ([[10-11-sign-conventions]]).

**GF3.** Three peaks: frequency 0 plus $k/4$ for $k = 1, 2$. Two seasonal frequencies, not six.

**Practice set.**

**P1.** Positive $\phi$ peaks at $\omega = 0$; negative $\phi$ peaks at $\omega = \pi$. Larger $|\phi|$ makes the peak taller and narrower.

**P2.** $f(0) = (1-\theta)^2/2\pi$: $0.159, 0.0398, 0.0016, 0$. Only $\theta = 1$ gives an exact zero.

**P3.** An **AR(2) with complex roots** near the unit circle at the annual frequency — a stochastic annual cycle rather than a differencing operator.

**P4.** Add the term whose spectrum has a peak there — usually a seasonal AR or MA at the relevant lag. A missing peak in the model's spectrum is the frequency-domain version of a residual ACF spike.
## 30-04-pseudo-spectrum

**1.** Seven peaks: frequency 0 plus the six seasonal frequencies. On a log axis they are visibly unbounded rather than merely large.

**2.** Higher $\Theta$ gives **narrower** peaks — more stable seasonality, more sharply defined in frequency, and smaller revisions. Same parameter, three descriptions.

**3.** $\theta$ shapes the trend peak the same way $\Theta$ shapes the seasonal ones.

**4.** $(1-B)$ alone has one infinite peak at $\omega=0$; $(1-B^{12})$ has seven, at 0 and the six seasonal frequencies. Compare the root table in [[10-06-differencing]] — same roots, viewed as frequencies.

**5.** A periodogram of finite data cannot show an infinity, but its peaks line up with the pseudo-spectrum's. The infinities are a property of the *model*, not of any dataset.


**Going further.**

**GF1.** **Three**: frequency 0 and the two seasonal frequencies $1/4$ and $1/2$. Monthly has seven; the rule is $1 + \lfloor s/2 \rfloor$.

**GF2.** R returns `Inf`, and that is correct rather than a failure — the pseudo-spectrum genuinely is unbounded there. The point of 40-06 is that the *filters* derived from it are still finite, because the infinities cancel ([[derivations#D10. Why the WK filters have no poles|D10]]).

**GF3.** A unit root is a statement about the model, and no finite dataset can exhibit an infinite spectrum. The periodogram of real data shows large peaks in the same places; the infinity is what the model says those peaks are approaching.

**Practice set.**

**P1.** **Exactly zero** at all seven — frequency 0 and the six seasonal frequencies. That is why the pseudo-spectrum is infinite there.

**P2.** Much larger for $\Theta = 0.9$: high $\Theta$ means a narrow, tall peak, so just off-centre the value is still enormous.

**P3.** $\Theta$ — it sets the peak **width**, not the peak locations. Same model family, different seasonal stability.

**P4.** Use a **log axis**. On a linear axis an unbounded peak dwarfs everything and the plot carries no information.
## 30-05-filters-in-the-frequency-domain

**1.** The gain of $(1-B)$ is $2|\sin(\omega/2)|$, rising from 0 at $\omega=0$ to **2** at $\omega=\pi$. Differencing does not just remove the trend — it **amplifies** high frequencies by up to a factor of two.

**2.** Seven zeros: frequency 0 and the six seasonal frequencies ([[derivations#D7. Why differencing is a filter with zeros where the seasonal lives|D7]]).

**3.** The differenced periodogram is tilted upward — high frequencies amplified, low ones removed. This is why over-differencing makes a series look noisier than it is.

**4.** The real composite filter has notches that are deep but finite in width, and small ripples between them. The ideal notch is unrealisable with finitely many weights; X-11 is a practical approximation to it.

**5.** Symmetric filter: phase exactly 0. One-sided: nonzero and frequency-dependent. The note prints both.


**Going further.**

**GF1.** **Amplifies**, by a factor of **2** at $\omega=\pi$: the gain is $2|\sin(\omega/2)|$. Differencing is not a neutral operation — it is a high-pass filter that doubles the fastest cycle.

**GF2.** The measured shift matches the group delay in months, which is what the group delay is *for* ([[30-08-filter-theory]]).

**GF3.** $(1-B^4)$ has three zeros — at $0, 1/4, 1/2$ — against seven for $(1-B^{12})$. In both cases: frequency zero plus every seasonal frequency.

**Practice set.**

**P1.** $2|\sin(\pi f)|$: $0, 0.618, 1.414, 2$. Note it **exceeds 1** — differencing amplifies high frequencies.

**P2.** Zeros at $f = 0$ and $k/12$ for $k=1..6$: seven in all.

**P3.** It **amplifies** cycles at that frequency. Differencing does exactly this at high frequencies, which is why over-differencing makes a series look noisier than it is.

**P4.** **No.** Differencing removes the trend but doubles the highest frequencies. If you want to keep detail, use a trend filter and subtract, or model the trend rather than differencing it away.
## 30-06-wiener-kolmogorov

**1.** The gain is near 1 at low frequencies (where the random walk dominates) and falls toward 0 at high frequencies (where the noise does). The filter keeps the share of the power that is the signal's.

**2.** More noise pushes the cutoff toward lower frequencies — the filter grows more conservative because less of the data is trustworthy signal.

**3.** The weights are symmetric by construction and decay, but **slowly**: for the airline seasonal filter they are still nonzero at lag 60. That slow decay is the entire problem [[30-07-finite-samples]] exists to solve.

**4.** $\nu_s + \nu_n = 1$ at every frequency, verified to about $10^{-12}$ in the note. Every bit of power is assigned somewhere.

**5.** Add a constant $c$ to $f_n$ and subtract it from $f_s$: the sum is unchanged, so $f_z$ is identical and the data cannot tell the two apart. That is the non-identification the canonical decomposition resolves **by convention** ([[derivations#D9. The canonical decomposition, and why it is a convention|D9]]).


**Going further.**

**GF1.** $\nu_s \to 1$ everywhere: with no noise, the signal owns all the power at every frequency and the filter should keep everything. Verified by shrinking $f_n$ numerically.

**GF2.** **You cannot.** $\nu_s = f_s/(f_s+f_n)$ with both non-negative is bounded in $[0,1]$ by construction. The WK gain can never exceed 1 — a filter that amplified would not be minimum-MSE.

**GF3.** A double random walk has more low-frequency power, so the cutoff moves **higher** — the filter keeps more, because more of the variation is credibly signal. That is the same trade-off as choosing a longer Henderson.

**Practice set.**

**P1.** They sum to 1 at every frequency, to about $10^{-12}$. Trend owns $\omega=0$ entirely; seasonal owns each seasonal frequency entirely.

**P2.** Spikes at multiples of 12 with an envelope decaying roughly like $\Theta$ per year — still visibly nonzero at lag 36.

**P3.** **All** of the power at that frequency. Gain 1 means everything there is assigned to that component and nothing to the others.

**P4.** The **model** decides, via the relative heights of the component spectra — and yes, the split of the flat part is a **convention** (the canonical choice), not something the data determines ([[derivations#D9. The canonical decomposition, and why it is a convention|D9]]).
## 30-07-finite-samples

**1.** Far more terms than intuition suggests. For the airline model at $\Theta = 0.557$ the filter needs **331 lags — 27.6 years** — to converge to $10^{-7}$, on a series only 12 years long.

**2.** Renormalising the truncated filter restores gain 1 at $\omega=0$; without it the trend is systematically mis-scaled.

**3.** Truncation produces a **constant offset**, not noise. That is what makes it dangerous: the series looks fine, correlates at 0.999 with the correct answer, and is uniformly wrong.

**4.** The final-observation estimate converges as the extension lengthens, with most of the movement in the first year or two.

**5.** All three coincide, which is the reassuring result: forecast extension, tight truncation and Burman's exact algorithm are three routes to the same filter.


**Going further.**

**GF1.** At $\Theta = 0.99$ the requirement blows past the 600-lag cap — **50 years and more**. The envelope decays like $\Theta$ per *year*, so $0.99$ barely decays at all. Most people guess a few years.

**GF2.** A **constant offset**, not noise. Without normalisation on both sides you can see it plainly; normalise either side and it is absorbed, which is how this bug hid in the vault until it was looked for deliberately.

**GF3.** Fewer **lags** but a similar number of **years**, because the decay is per year in both cases. Quoting the requirement in lags rather than years makes quarterly look cheap when it is not.

**Practice set.**

**P1.** The requirement rises steeply with $\Theta$: 60 lags at 0.3, 331 at 0.557, 600+ at 0.9. In years: 5, 27.6, 50+.

**P2.** The error falls by orders of magnitude with each increase, and is a **constant offset** rather than noise at every truncation length.

**P3.** **Truncation.** A near-perfect correlation with a constant offset is the signature — it is a bias, not noise, and normalising would hide it.

**P4.** Forecast-extend (which is what `seats_decompose` does), or use **Burman's algorithm**, which needs no long filter at all ([[40-09-burman-algorithm]]). Truncating and hoping is the option to avoid.
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


**Going further.**

**GF1.** **Yes.** Cascading multiplies transfer functions; both are real, so the product is real, so the phase is 0 or $\pi$. Zero phase is preserved under composition — which is why X-11's whole chain of symmetric filters has zero phase in the interior.

**GF2.** A pure delay $w = (0,0,0,1)$ has $H = e^{-3i\omega}$, phase $-3\omega$, and group delay exactly 3 at every frequency. It is the one case where the delay *is* a constant and could be subtracted off.

**GF3.** **Linearity** fails, and it fails as soon as an observation crosses the sigma limit — which for a large outlier is immediate. Time-invariance survives. So X-11 is time-invariant but non-linear, and only its linear part has a transfer function.

**Practice set.**

**P1.** The symmetric filter's phase is 0 or $\pi$ at every frequency; the one-sided filter's varies continuously.

**P2.** All four agree to ten decimals. $\sum w_j$ and $H(0)$ are the same quantity.

**P3.** **Inverting** it — multiplying by $-1$. A phase of $\pi$ is a sign flip, not a time shift, which is why symmetric filters still count as zero-phase.

**P4.** Because the shift is **frequency-dependent**, so there is no single constant to subtract. A series mixes frequencies, and each is displaced differently.

**P5.** 'Ideal at what?' — an ideal low-pass cannot be built with finitely many weights (Gibbs), so either the filter is infinite, or 'ideal' means 'good enough for our purposes', which is a judgement worth seeing stated.
# Module 4 — SEATS

## 40-01-unobserved-components-and-reduced-form

**1.** The fitted airline model recovers the reduced form of the structural model — the two are different parameterisations of the same process, which is the whole point of "reduced form". Simulating from components and fitting an ARIMA is the cleanest way to convince yourself.

**2.** Roughly: $\sigma_\eta^2$ (trend innovation) drives $\theta$, $\sigma_\omega^2$ (seasonal innovation) drives $\Theta$, and $\sigma_\varepsilon^2$ (irregular) pushes both toward 1. More noise means more smoothing is optimal, which shows up as MA roots nearer the unit circle.

**3.** With $\sigma_\omega^2 = 0$ the seasonal is **fixed**, and $\Theta \to 1$ — the seasonal MA root lands on the unit circle. That is the same limiting case as [[10-10-airline-model]] exercise 3: $\Theta$ near 1 means seasonality that does not evolve.

**4.** The decomposition recovers the simulated components closely but **not exactly**, and the gap is not estimation error — it is the canonical convention. The truth used whatever variances you chose; SEATS returns the *canonical* split, which makes each component as smooth as possible. Two different admissible decompositions of the same reduced form ([[derivations#D9. The canonical decomposition, and why it is a convention|D9]]).


**Going further.**

**GF1.** **Nothing** — $(\theta,\Theta)$ are unchanged. The MA parameters depend on the *ratios* of the variances, not their scale; doubling everything doubles $\sigma_a^2$ alone. Signal-to-noise is what determines how much smoothing is optimal.

**GF2.** **Something else.** The gap is the canonical convention: your simulation used whatever variances you chose, while SEATS returns the canonical split. Both are admissible decompositions of the same reduced form ([[derivations#D9. The canonical decomposition, and why it is a convention|D9]]).

**GF3.** Yes — a quarterly structural model reduces to a quarterly airline model, with $S(B) = 1+B+B^2+B^3$. The argument is frequency-general.

**Practice set.**

**P1.** Trend, seasonal and irregular each get their own innovation: $\sigma_\eta^2$ the trend, $\sigma_\omega^2$ the seasonal, $\sigma_\varepsilon^2$ the irregular.

**P2.** $(1-B)^2 \times S(B)$, and the product returns $(1-B)(1-B^{12})$ exactly.

**P3.** $\sigma_\omega^2 \approx 0$ — the seasonal barely evolves, so it is nearly deterministic.
## 40-02-admissible-decompositions

**1.** On a coarse grid, **25%** admissible; on a fine grid, 27.4%. `AirPassengers` at $(0.402, 0.557)$ sits comfortably inside, in the positive quadrant.

**2.** Moving $\theta$ negative along $\Theta = 0.5$, the **trend** spectrum is the first to go negative. Negative $\theta$ means the model wants a trend rougher than white noise at high frequencies, which no non-negative spectrum can supply.

**3.** Confirmed — `cpi` is the only catalogue failure, and it is the only series with a negative $\theta$ ($-0.086$). Three independent facts agreeing: negative $\theta$, inadmissible, and the only series where X-13 substitutes the model.

**4.** `udg(m, "seatsmdl")` reports a **different** model from the one fitted. X-13 silently replaces an inadmissible model with a nearby admissible one and carries on — worth knowing, because your published factors then come from a model you did not choose.

**5.** With `seats.noadmiss = "no"` you get an error instead of a substitution. Preferable when you want to know, which is most of the time.

**6.** The quarterly region is the same *shape* — positive quadrant admissible, elsewhere not — but the boundary sits differently because there are two seasonal frequencies rather than six ([[30-01-frequency-domain-basics]]).


**Going further.**

**GF1.** **Not admissible.** Any negative $\theta$ leaves the positive quadrant, and the region map shows essentially nothing admissible outside it. `cpi` is the catalogue's real example.

**GF2.** The **trend** spectrum goes negative first. A negative $\theta$ asks for a trend rougher than white noise at high frequencies, which no non-negative spectrum can supply.

**GF3.** The same shape — positive quadrant admissible, elsewhere not — but the boundary sits differently because there are two seasonal frequencies rather than six.

**Practice set.**

**P1.** Everything in the positive quadrant passes; essentially nothing elsewhere does.

**P2.** $\theta = -0.086$ — negative, hence outside the admissible quadrant.

**P3.** X-13 found your model **inadmissible** and silently substituted a nearby admissible one. Use `seats.noadmiss = 'no'` to get an error instead.
## 40-03-canonical-decomposition

**1.** $m_T = 0.0514$ and $m_S = 0.0225$ for `AirPassengers`; both are handed to the irregular, whose constant term rises accordingly.

**2.** Each component's spectrum has its minimum shifted to exactly zero. That is the definition of the canonical choice.

**3.** For the trend, the minimum is at $\omega = \pi$ — the highest frequency, where a trend should have least power. **Yes, it is $\pi$**, and that is not an accident: subtracting the minimum makes the trend as smooth as it can be while remaining a valid spectrum.

**4.** The canonical trend is **smoother** — it has had a flat white-noise floor removed. The variance of its second difference is correspondingly lower. Whether that is desirable is a judgement, not a theorem.

**5.** They must, and they do: the canonical shift moves power *between* components without changing the total, so $\nu_T + \nu_S + \nu_I = 1$ still holds at every frequency.

**6.** The largest $m_T + m_S$ belongs to the series with the most white noise in it — the more irregular the series, the more the canonical rule has to move.


**Going further.**

**GF1.** The **trend**: $m_T = 0.0514$ against $m_S = 0.0225$, roughly twice. The trend spectrum has more white-noise floor to give away.

**GF2.** **No** — without the canonical step the irregular is not white; it retains whatever floor the other components kept. Making the irregular exactly white is precisely what the step buys.

**GF3.** It maximises smoothness of the trend and seasonal at the cost of a larger irregular. To prefer a different split you would have to believe the components genuinely contain some white noise of their own — perfectly defensible, and unfalsifiable from the data.

**Practice set.**

**P1.** $m_T = 0.0514$, $m_S = 0.0225$, and the irregular's constant rises by their sum.

**P2.** They do, to about $10^{-12}$ — moving power between components cannot change the total.

**P3.** **Canonical.** Touching zero somewhere is exactly what subtracting the minimum achieves.
## 40-04-partial-fractions-in-b-and-f

**1.** $\theta(B) = 1 - 0.4B$. Its autocovariance sequence is $c_0 = 1 + 0.4^2 = 1.16$ and $c_1 = -0.4$. Hence $(1.16, -0.4)$.

**2.** For $s = 4$: $\deg N = 5$ (the MA is $(1-\theta B)(1-\Theta B^4)$, degree 5), $\deg D_T = 2$, $\deg D_S = 3$. Fewer unknowns than the monthly case, and the linear system is correspondingly smaller.

**3.** The QR solve returns a residual around $6\times10^{-14}$ — the system is exactly determined and well conditioned.

**4.** With $\deg C$ wrong the system is **over- or under-determined** and the residual jumps by many orders of magnitude. This is the useful failure: the residual is a genuine check on your degree bookkeeping, so watch it rather than assuming.

**5.** They sum to 1 and each is finite at $\omega=0$ even though $f_z$ is infinite there, because the filters are **ratios** and the infinity cancels top and bottom ([[derivations#D10. Why the WK filters have no poles|D10]]).


**Going further.**

**GF1.** Far fewer: $\deg N = 5$, $\deg D_T = 2$, $\deg D_S = 3$ for quarterly, against 13, 2 and 11 for monthly. The system shrinks roughly in proportion to $s$.

**GF2.** By **many** orders of magnitude — from $10^{-14}$ to something visible. That is what makes the residual a genuine check on your degree bookkeeping rather than a formality.

**GF3.** It does, using `_seats_general.R`: residuals stay near $10^{-12}$ for `unemp` and `ukgas`. The least-squares formulation does not care how the denominators arose.

**Practice set.**

**P1.** For $(1, -0.4)$: $c_0 = 1.16$, $c_1 = -0.4$. It is the autocovariance sequence of the coefficient vector.

**P2.** Around $10^{-14}$ monthly and similar quarterly — the system is exactly determined and well conditioned.

**P3.** A **degree is wrong** — the system is over- or under-determined. Recount $\deg A$, $\deg C$ and $\deg D$.

**P4.** Check the residual, and independently verify that $\nu_T + \nu_S + \nu_I = 1$ at every frequency. Two independent internal checks are strong evidence without any external reference.
## 40-05-component-models

**1.** Differencing the canonical trend twice gives autocovariances that vanish beyond lag 2 — confirming ARIMA(0,2,2), the local linear trend.

**2.** Applying $S(B)$ to the seasonal leaves autocovariances vanishing beyond lag 11, confirming the 11 MA terms.

**3.** The irregular's autocovariances vanish beyond lag 0 — it is **exactly white**, which is what the canonical convention was designed to produce.

**4.** The trend takes the largest share; the irregular's share is $m_T + m_S$ plus whatever was already there. The exact split depends on $(\theta,\Theta)$.

**5.** Without the canonical step the trend numerator has degree **1** rather than 2 — the canonical subtraction is what raises it, and that is what makes the trend an ARIMA(0,2,2) rather than an ARIMA(0,2,1).


**Going further.**

**GF1.** $S(B) = 1+B+B^2+B^3$ has degree 3, so the seasonal is ARIMA(0,0,3) — three MA terms rather than eleven. The trend remains ARIMA(0,2,2), which is frequency-independent.

**GF2.** **No** — without the canonical step the irregular carries residual autocorrelation. Whiteness is a consequence of the convention, not of the model.

**GF3.** Trend unchanged at (0,2,2); seasonal drops from 11 MA terms to 3. Everything scales with $s$ except the trend.

**Practice set.**

**P1.** Nonzero at lags 0, 1, 2 and **zero beyond** — confirming ARIMA(0,2,2).

**P2.** Nonzero up to lag 11, zero beyond — confirming the 11 MA terms.

**P3.** That the irregular is **exactly white**, which is what the canonical convention was designed to produce.

**P4.** The **canonical step**. Without it the trend numerator has degree 1 rather than 2, giving (0,2,1).
## 40-06-wk-filters-for-the-airline-model

**1.** They sum to 1 at every frequency, verified to about $10^{-12}$.

**2.** $\nu_T(0) = 1.00000$, $\nu_S(2\pi/12) = 0.99993$, $\nu_S(\pi) = 1.00000$. Ownership at the poles is total.

**3.** Higher $\Theta$ gives **narrower** notches. X-11's composite gain is fixed and cannot adapt — that is the deepest difference between the two methods: SEATS tunes the filter to the series, X-11 uses the same one for everybody.

**4.** The seasonal weights have spikes every 12 lags with an envelope decaying roughly like $\Theta^{j/12}$ — one factor of $\Theta$ per year. That is why a high $\Theta$ needs such a long filter.

**5.** 60 lags at $\Theta = 0.3$, **331** at $0.557$, 600+ at $0.9$. The run time of the brute-force implementation is governed entirely by this ([[30-07-finite-samples]]), and it is exactly the cost [[40-09-burman-algorithm]] removes.

**6.** $\nu_S(\pi) = 1$ because for even $s$ the Nyquist frequency **is** a seasonal frequency ($k = s/2$) — it is genuinely seasonal, not a boundary artefact.


**Going further.**

**GF1.** Most of it. Between the notches neither trend nor seasonal has much claim, so the irregular takes the bulk — which is why the irregular is the noisiest component and why it should be.

**GF2.** $\Theta = 1.05$ puts an MA root **inside** the unit circle, so $N$ has a zero on or inside the circle and the filters acquire a genuine pole. The 'no poles' result depends on invertibility ([[derivations#D10. Why the WK filters have no poles|D10]]) — it is not automatic.

**GF3.** Two notches rather than six, and correspondingly wider relative to the frequency range.

**Practice set.**

**P1.** Trend owns $\omega=0$; seasonal owns each $2\pi k/12$; the irregular takes the gaps. Sum is 1 to $10^{-12}$.

**P2.** Because for even $s$, $k = s/2$ gives exactly $\omega = \pi$ — it is a genuine seasonal frequency, not the edge of the axis.
## 40-07-implementing-seats-in-r

**1.** s10 0.000%, s11 0.001%, s12 0.012%, s13 0.010% against the Census binary.

**2.** With `max_lag = 60` a constant offset appears. Compare with `normalize = FALSE` on **both** sides — normalisation re-centres the seasonal and therefore *absorbs the very constant you are trying to demonstrate*. Comparing normalised runs makes the bug invisible.

**3.** `co2` has $\Theta = 0.912$, so the rule demands far more lags — and it still matches X-13 once given them. The adaptive rule exists precisely so this works without hand-tuning.

**4.** For $s=4$ the degree bookkeeping shrinks: two seasonal frequencies, shorter polynomials, smaller linear system. The algorithm is unchanged.

**5.** `cpi` fires the admissibility check, as [[40-02-admissible-decompositions]] predicts.

**6.** The cost is in the **filter**, not the forecasting: it is $O(n \times \text{max\_lag})$, and `max_lag` is in the hundreds. Burman replaces that with two $O(n)$ passes ([[40-09-burman-algorithm]]).


**Going further.**

**GF1.** Far more than for `AirPassengers` — the envelope decays like $\Theta$ per year, so $0.912$ needs many decades. Most people guess low.

**GF2.** `stopifnot(extend >= max_lag)` fires. It is there because the silent version returns **all NA** or, worse, a plausible-looking but wrong answer — this exact bug cost a debugging session and is why the guard is explicit.

**GF3.** They do: `UKgas` and `JohnsonJohnson` both decompose correctly with $s=4$, which is what confirmed the code was genuinely frequency-general rather than accidentally monthly.

**Practice set.**

**P1.** s10 0.000%, s11 0.001%, s12 0.012%, s13 0.010% on `AirPassengers`; comparable on quarterly series.

**P2.** 331 lags (27.6 years) at $\Theta = 0.557$; far more for `co2` at 0.912.

**P3.** Whether `extend >= max_lag`. If the extension is shorter than the filter, every value is `NA` — which is why that guard is an explicit `stopifnot`.
## 40-08-validating-against-x13

**1.** See the table in the note.

**2.** `transform.function = "none"` runs X-13 **additive** while our code is multiplicative, producing a ~100% discrepancy that has nothing to do with the algorithm. The lesson generalises: **when a comparison fails by a lot, suspect the harness before the algorithm.**

**3.** With outliers on, the months near detected outliers move. Note `coef()` returns ARIMA terms too, so filter with `grep("^(AO|LS|TC)", ...)` or you will report `MA-Nonseasonal-01` as an outlier.

**4.** The identity holds against the **linearized** series, not the raw one, once regressors are active. Getting this wrong looks like a broken identity when it is a changed definition.

**5.** SEATS vs X-11 differ by **0.760%**; our SEATS vs the Census binary by **0.001%**. The method choice matters roughly **660 times** more than the implementation choice.


**Going further.**

**GF1.** **s12** (the trend) moves more. An outlier is a high-frequency event, so it is mostly absorbed by the irregular and the trend near it; the seasonal factors are estimated across years and are more insulated.

**GF2.** About 100%, because X-13 runs **additive** while your code is multiplicative. The lesson: *when a comparison fails by a lot, suspect the harness before the algorithm* — a 100% error is almost never a subtle bug.

**GF3.** Same four numbers, same order of magnitude. See the quarterly section of 40-07.

**Practice set.**

**P1.** See the table in the note.

**P2.** `transform.function = 'log'` (multiplicative), `arima.model` (no automatic selection), `regression.aictest = NULL` (no calendar tests), `outlier = NULL` (no outlier detection). Each removes a source of difference that is not the algorithm.

**P3.** **The harness.** A 100% discrepancy is almost never a subtle algorithm bug — here it is X-13 running additive against multiplicative code.

**P4.** Better than about 0.01% on the interior, with the identity holding exactly. Anything much worse means a real difference in method, not just arithmetic.
## 40-09-burman-algorithm

**1.** With $W = 1$ and $\theta(B) = 1-\theta B$: matching $B^0$ gives $g_0 + \theta^2 g_0 \cdots$ — do it carefully and you get two equations, $2(g_0 - \theta g_1) = 1$ at lag 0 and $-\theta g_0 + g_1 = 0$ at lag 1, so $g_1 = \theta g_0$ and $g_0 = 1/[2(1-\theta^2)]$.

**2.** The identity holds to about $7\times10^{-15}$. Perturb any $g_j$ and it fails immediately — which is why this check is worth running before trusting anything downstream.

**3.** Amplitude 1 at $\omega = 2\pi/12$, amplitude 0 at $\omega=0$. The recursions reproduce $\nu_S$ exactly.

**4.** Without extension the first and last few dozen observations are visibly wrong — far more than the length of $g$, because the error comes from the **recursion's zero start**, not from the filter's reach. That is precisely the gap Burman's exact starting values close.

**5.** Trend and seasonal from the same machinery sum to the series minus the irregular, by construction.

**6.** The brute-force cost is in applying hundreds of filter weights at every time point, not in the forecasting. Burman avoids it by replacing the convolution with two recursions.


**Going further.**

**GF1.** $\theta(B) = (1-\theta B)(1-\Theta B^4)$ has degree 5, so $g$ has **6** coefficients — against 14 monthly. The saving over brute force is proportionally even larger.

**GF2.** The **unit-circle identity** detects it immediately and unambiguously; the decomposition detects it too, but as a small distortion you might rationalise. Check the identity first — it is a sharp test, and the decomposition is a blunt one.

**GF3.** It does not care. The method needs only that $\theta(B)$ is invertible; the AR side lives in the numerator $W$ and changes nothing structural.

**Practice set.**

**P1.** $\deg\theta = 13$ and $|g| = 14$ monthly; $\deg\theta = 5$ and $|g| = 6$ quarterly.

**P2.** About $7\times10^{-15}$ — the split is exact to machine precision.

**P3.** The **recursions or the run-up**, not the algebra. A correct $g$ with a wrong answer means the implementation of the loops, or insufficient warm-up from the zero start.

**P4.** **Burman**, because it has no truncation tolerance to choose and runs in $O(n)$. Truncation is easier to write and easier to get subtly wrong.

**P5.** **Invertibility** — all roots of $\theta(B)$ outside the unit circle, so the feedback coefficients shrink what they act on ([[10-05-invertibility]]).

**P6.** Because it is exact rather than approximate. A tolerance is a knob, and a badly set knob produces a *constant offset* that correlates 0.999 with the truth and is uniformly wrong ([[30-07-finite-samples]]).
## 40-10-general-seats

**1.** The trend matches **exactly**; the seasonal to about $10^{-14}$. Exactness is not luck: $(1-B)^2$ has a double root at $B=1$, and `polyroot` on the expanded polynomial returns it as a cluster of two roots $10^{-7}$ apart — root-finding at a repeated root loses roughly half the available precision, $\sqrt{\varepsilon}$ rather than $\varepsilon$. So the roots are never taken from the expanded polynomial: $(1-B)^d$ contributes $d$ roots at exactly 1, $(1-B^s)^D$ the $s$-th roots of unity from $\cos$ and $\sin$, and only $\phi(B)$ needs `polyroot`. The seasonal's residual $10^{-14}$ is ordinary floating-point in the trigonometry.

**2.** A 6-month period is exactly the second seasonal frequency ($k=2$), so with a modulus above `rmod` the pair is **seasonal** — correctly. Both gates bite here: at $1/|z| = 0.83$ it is seasonal, and at $1/|z| = 0.33$ the same root at the same frequency becomes **transitory**. A root at period 6.5 is $2.3°$ away and falls outside `epsphi`, so it is transitory too.

**3.** A root slightly off a seasonal frequency is transitory at small `epsphi` and seasonal at large. X-13's value is **2 degrees**, tight enough that only a root essentially *on* a seasonal frequency qualifies. That is the right default, because seasonal unit roots sit exactly there — a wide window buys nothing and captures cycles that merely happen to be nearby.

**4.** For `unemp` with $(1,1,1)(0,1,1)$: 12 seasonal roots and 2 trend. Note the AR(1) coefficient is $-0.50$, giving a real **negative** root, whose frequency is $\pi$ — the Nyquist frequency, which for even $s$ *is* a seasonal frequency. So it is correctly seasonal, and if you had classified by "stationary AR goes to the trend" you would have got it wrong.

**5.** Yes. The partial fraction is solved as a least-squares system with one numerator block per denominator, so additional components just add blocks. Residuals stay around $10^{-12}$.

**6.** It lands in the **trend**, and predicting from the period is how you know before running it: an 11-year cycle is 132 months, or $2.7°$, well inside the $15°$ trend window. Far from any $k/12$, yes — but that only rules out the seasonal. This is the case that used to be quoted in this vault as the clearest transitory example, and it is not one. (`sunspots` is also a series with *no seasonality at all* — [[50-01-is-there-seasonality]].)

**7.** Most of it. The trend gap between the general and hard-coded routes is $1.3\times10^{-5}$, while the hard-coded route matches X-13 to $3\times10^{-6}$ — so the general implementation's error is a few times the total error of the special-case one, and it enters at the root-finding step. This is the gap that *remains* after the conjugate-pair averaging.

**8.** It still goes to **transitory**. `rmod` is not the only gate: at $134°$ the pair is $14°$ from the nearest seasonal frequency, which `epsphi = 2` already rules out. Removing both gates is what makes it seasonal — and then the seasonal factors carry a transient that decays by half every two and a half months, subtracted from the same month of every future year.

---


**Going further.**

**GF1.** **Not all seasonal.** Eleven go to the seasonal and **one to the trend** — the root at frequency zero. $(1-\Phi B^{12})$ is not a purely seasonal operator, and sorting by which factor a root came from would get this wrong.

**GF2.** Nothing changes — which is the interesting part. `imp`'s pair has inverse modulus $0.4614$, so the **modulus gate alone** keeps it out of the seasonal even with a $15°$ window; and setting `rmod = 0` alone does not move it either, because $134°$ is $14°$ from a seasonal frequency. Only removing **both** gates makes it seasonal, which is exactly what the original buggy rule did. Two independent tests, either one sufficient here.

**GF3.** Both land in transitory **provided both cycles are shorter than 24 months** — try 20 and 9 months, which gives 4 transitory roots, 11 seasonal and 2 trend. Make one of them 40 months and it joins the trend instead. The $N$-way partial fraction handles the extra denominator without modification, which is what makes it $N$-way rather than four-way.

**Practice set.**

**P1.** `unemp` gives trend=2, seasonal=12 and no transitory; `cpi` gives trend=2, seasonal=11, **transitory=2**; `ukgas` gives trend=2, seasonal=3, **transitory=1**. Two of the three do produce a fourth component.

**P2.** Eleven seasonal and **one trend** — the root at frequency zero. $(1-\Phi B^{12})$ is not a purely seasonal operator.

**P3.** **Seasonal**, at $2\pi/12$ — the annual cycle, period 12.

## 40-11-validating-general-seats

**1.** The 24-month cycle. It sits exactly on the $15°$ trend cutoff, and the test is a strict inequality, so the answer is decided by whatever noise the computed angle carries. From the AR(2) alone the angle is $15° - 1.8\times10^{-14}$; from the expanded degree-14 AR polynomial the same root comes out at $15° + 7.1\times10^{-13}$. Factoring each factor separately, where the roots are analytic or come from a small polynomial, removes the noise and the strict inequality then means what it says.

**2.** Nothing moves: `epsphi = 2` still keeps the pair out of the seasonal, because $134°$ is $14°$ off. You need `rmod = 0` **and** `epsphi = 15` together before the AR(2) is called seasonal, and then the seasonal factors carry a transient that halves every two and a half months.

**3.** Same answer from the other side — `epsphi = 15` alone leaves it transitory, because the modulus gate stops it. The original bug needed both defects at once, which is a useful thing to know about it: either gate alone would have caught it.

**4.** No. The 40-month cycle stays in the trend all the way down to `rmod`, and below it goes transitory — but the test is `> rmod` for the trend and $\ge$ for the seasonal, so at exactly $1/|z| = 0.5$ the pair is transitory. The asymmetry is X-13's, not a typo.

**5.** The offset is $+0.012691$ in logs, 1.28% in levels. Plotted against X-13's you will not see it: two curves 1% apart on a seasonal factor that swings from 0.56 to 1.80 are visually identical. That is the whole point of the error — it is invisible in exactly the check a reader would apply.

**6.** Before the fix: mean $+0.012691$, standard deviation $1.9\times10^{-7}$. A difference that is constant to six decimal places is a **convention**, not an implementation error, and splitting a comparison into level and shape is the fastest diagnostic there is. After it, the mean is zero and only the $1.9\times10^{-7}$ remains.

**7.** Because the transitory is **not normalised** — only the seasonal and the irregular are, and the trend absorbs both constants. So the transitory comparison shows pure filter agreement from the start, which is $10^{-6}$; the seasonal showed the same $10^{-6}$ all along, sitting underneath a constant a hundred times larger. That is the point of looking at the standard deviation separately from the mean.

**8.** The model choice moves the seasonal factors far more than the implementation does — the same relationship 40-08 found between SEATS and X-11. Which model you fit is a real decision; whether your code agrees with Census to 4 or 6 decimals is not.

**9.** Any series whose fitted model has a stationary AR root that is either short-cycled or low-modulus. `cpi` at $(2,1,2)(1,0,1)$ and `ukgas` at $(1,1,1)(0,1,1)$ both qualify — and `ukgas`'s transitory component is not small, at $\mathrm{sd} = 0.0106$ in logs.

**10.** Make the absence of a parse an error rather than a silent `NULL`. `x13_ar_split()` returns `NULL` both when X-13 rejects the model and when the format changes, and a comparison loop that treats `NULL` as "skip" will report zero mismatches out of zero cases and look like a pass. The check is to assert that a known case — the airline model, whose factorization you can write down — still parses to $(1-B)^2$ and $S(B)$.

**11.** **None of them.** $\Phi$ is $-0.2966$, and a negative seasonal AR coefficient puts the roots of $(1 - \Phi B^{12})$ at *odd* multiples of $15°$ — so there is no root at frequency zero and none at any multiple of $30°$. All twelve go to the transitory, along with the AR(1). The surprise is that the operator which looks most seasonal contributes nothing at all to the seasonal component, and that this depends entirely on the sign of $\Phi$: at $\Phi = +0.8$ the same operator gives eleven seasonal roots and one trend root.

**12.** No. Both trends are smooth, both track the series, both have a plausible annual shape — and at `max_lag = 150` the trend is a full degree Fahrenheit out. Truncation error in a Wiener–Kolmogorov filter looks like a slightly different smoothing choice, not like a bug, which is why it needs a convergence check rather than an eyeball.

**13.** `s10` is exactly 1 over the **first 360**, `s13` is exactly 1 over the **full 366**, `s14` is not 1 over either. An exact 1.000000000 is an imposed rule and nothing else is, so those three lines say: the seasonal is normalised over whole years, the irregular over everything, and the transitory not at all. Reading the invariants out of the other program's output is far quicker than guessing conventions and testing them one at a time.

**14.** Because a seasonal factor is *periodic* and an irregular is not. `imp`'s partial final year holds July to December only, so averaging the seasonal over it counts those six months twice and drags the constant toward whatever they happen to be — the mean is then contaminated by *which* months are left over. The irregular has no month-of-year structure for a partial year to bias, so truncating the span would just discard six observations for nothing.

**15.** The error *grows*: about 0.0009% at 250 lags, 0.0039% at 1200. The trend filter has gain **one** at frequency zero, so it responds to the level, and a longer filter reaches further into an ever-longer ARIMA forecast whose drift it then integrates. The seasonal and irregular filters have gain **zero** at frequency zero, are blind to the level, and converge normally. The fix is structural rather than numerical: X-13's tables satisfy the identity to $9\times10^{-15}$, so it takes one component by subtraction, and it must be the trend.

**16.** Its length is a multiple of 12, so the seasonal's whole-year window and the full span are the same thing and error 6 could not appear. And the irregular normalisation was worth only 0.01% there, which sat comfortably inside what the note was already writing off as "truncation and optimiser differences". A validated special case is worth exactly as much as the cases it exercises.

**Going further.**

**GF1.** 26 months is $13.8°$, inside the $15°$ window, and $0.6$ clears `rmod`. **Trend.** The near miss is instructive: 22 months at the same modulus is transitory.

**GF2.** The 24-month row flips from trend to transitory, on an angle difference of about $7\times10^{-13}$ degrees. That is the whole margin: a discrepancy twelve orders of magnitude below anything you would call meaningful, changing which component a root belongs to and moving `nottem`'s trend by 2.6 °F.

**GF3.** Anywhere a result is checked only against something derived the same way. The Burman implementation in [[40-09-burman-algorithm]] was originally "verified" with an identity that used the same intermediate on both sides, which is no test at all; it was closed by checking against an independently written cosine-polynomial multiply. The current open one is the general decomposition in the **additive** case, which nothing in the vault exercises.

**Practice set.**

**P1.** `rmod` $= 0.5$ gates whether a root is persistent enough to join the trend or the seasonal at all; `epsphi` $= 2°$ gates how close to a seasonal frequency a root must be; and $360/2s = 15°$ is the half-width of the trend window around frequency zero.

**P2.** **Transitory.** $60°$ is a seasonal frequency, but $0.48$ is below `rmod`, so the modulus gate rules it out.

**P3.** The shape is right and the level is wrong — a normalisation convention, not a filter error.

**P4.** There is **no transitory component**: the polynomial is empty, so every AR root went to the trend or the seasonal. That is the normal case, and it is what the airline model always gives.

**P5.** No. A uniform 1% error on one series is a *systematic* disagreement, which is the kind most likely to be a convention you have not matched — and conventions apply to every series, so the nine that agree are evidence that something specific to the tenth is triggering it. Find it before shipping.

**P6.** Almost nothing. The airline case is precisely where the general machinery does nothing: every root is a unit root at a frequency the split already knows. Reproducing it establishes that the code does not crash and that the plumbing is connected. It cannot test the classification, which is the only part that is new.
# Module 5 — Diagnostics and practice

## 50-01-is-there-seasonality

**1.** `sunspots` fails every seasonality test the others pass. Its 11-year cycle is real but is **not seasonal** — it does not sit at $k/12$.

**2.** SEATS mode refuses; X-11 mode **produces factors anyway**. That asymmetry matters: X-11 will happily "adjust" a series with no seasonality, and nothing in its output says so. Test first.

**3.** The sunspot spectrum has a large peak at about $1/132$ cycles per month (11 years) and nothing at $k/12$. Being cyclical is not being seasonal.

**4.** Adjusting noise makes it **worse** — the adjusted series has *higher* variance than the original, because you have subtracted an estimated pattern that was not there. This is the cleanest argument for testing before adjusting.

**5.** Detection degrades sharply below about 5 years. Short series are exactly where you most want a diagnostic and least able to run one.


**Going further.**

**GF1.** **Yes, easily** — a fixed sine is the strongest possible seasonality. It also gives $\Theta \to 1$ and a spectral peak of near-zero width. Deterministic seasonality is the limiting case, not an exception.

**GF2.** The adjusted series has **higher** variance. It happens by accident whenever adjustment is applied as a routine pipeline step without testing first — which is common, and is why 50-01 comes before everything else in Module 5.

**GF3.** The concepts transfer exactly with $s = 7$; the *tools* mostly do not, because X-13 is built around monthly and quarterly. You would need $\lfloor 7/2 \rfloor = 3$ seasonal frequencies and software that supports weekly periodicity.

**Practice set.**

**P1.** Most catalogue series exceed 9 comfortably; `sunspots` does not.

**P2.** The adjusted series has **higher** variance — you removed a pattern that was not there.

**P3.** **Not seasonal** — below the 9 threshold for $\chi^2_2$ at 1%.

**P4.** Show them the spectrum. A peak away from $k/12$ means a real cycle that is not seasonal, and adjusting for it would be wrong — the distinction is visible rather than a matter of opinion.
## 50-02-residual-seasonality

**1.** Low-$\Theta$ series are least clean — fast-evolving seasonality is hardest to remove completely.

**2.** The spectrum of the adjusted series should have no peaks at $k/12$. QS is a formal version of exactly that visual check.

**3.** A long, slow filter (`s3x9`) on fast-evolving seasonality leaves residual seasonality behind. This is the filter-choice failure made deliberate.

**4.** A seasonal **break** is caught by sliding spans and often missed by QS, because QS asks whether seasonality remains *on average* over the whole span, not whether it changed partway through.

**5.** Adjusting components separately and summing does **not** generally equal adjusting the sum — the "indirect versus direct" problem. Neither is universally right; agencies choose and document.


**Going further.**

**GF1.** Low-$\Theta$ series: fast-evolving seasonality is hardest to remove completely, and a fixed-length filter always lags it slightly.

**GF2.** QS detects it clearly — the statistic is sensitive to a residue well below what the eye picks up in a plot, which is the argument for running it rather than looking.

**GF3.** Direct and indirect adjustment differ, sometimes materially. Neither is universally correct; agencies pick one and document the choice.

**Practice set.**

**P1.** Original high, adjusted near zero, residual near zero is the healthy pattern.

**P2.** An unmodelled **calendar effect**, a seasonal filter too long for how fast the pattern evolves, or a **seasonal break** partway through.

**P3.** Find the cause rather than re-running with different options. Most often it is a calendar effect, which is cheap to test and cheap to fix ([[50-10-calendar-effects]]).
## 50-03-m-and-q-statistics

**1.** `sunspots` fails badly on the M statistics that measure the seasonal's contribution to variance — there is no seasonal to contribute.

**2.** Q below 1 with significant QS on the adjusted series means **the adjustment looks well-behaved but left seasonality behind**. Q is a composite of eleven things and can average away a specific failure. Never rely on Q alone.

**3.** M8–M11 (the seasonal-stability group) move most, because they are precisely what the seasonal filter choice affects.

**4.** SEATS mode produces **no M or Q statistics at all** — they are X-11 diagnostics, defined in terms of X-11's tables. Comparing methods on Q is therefore impossible by construction.

**5.** M7 crosses 1 as a series shortens, typically within a few years of data. Short series fail diagnostics that longer versions of the same series pass.


**Going further.**

**GF1.** **M7** typically, since it compares the stable-seasonality F against the moving-seasonality F and both degrade with less data. It crosses 1 within a few years of shortening.

**GF2.** Take a series with strong residual seasonality but otherwise tidy behaviour: Q averages eleven statistics and can stay below 1 while QS on the adjusted series is significant. Composite statistics hide specific failures — always read the components.

**GF3.** The M and Q statistics are defined in terms of X-11's own tables (D-series ratios), which SEATS never computes. To compare methods, use something both produce: revisions, residual seasonality, or sliding spans.

**Practice set.**

**P1.** On `AirPassengers` all pass; on a non-seasonal series the seasonal-contribution statistics fail badly.

**P2.** M7 compares stable against moving seasonality — a value above 1 says the seasonal is **evolving fast** relative to how identifiable it is. Often a short-series symptom.

**P3.** **No.** Q averages eleven things and can pass while a specific failure hides inside it. Always check QS on the adjusted series alongside.
## 50-04-sliding-spans

**1.** **2.08%** of months flagged (2 of 96) for `AirPassengers` — comfortably passing the 15% threshold.

**2.** `UKgas` **40.62%** and `JohnsonJohnson` **18.75%** — both fail. Both are quarterly, so each span holds a quarter as many observations, and both have genuinely evolving seasonality. The flag rate does track $\Theta$, but sample size per span matters at least as much.

**3.** An outlier near a span boundary makes the flag rate jump, because it is in some spans and not others. Modelling it as an AO settles it — which is the argument for outlier detection *before* stability diagnostics.

**4.** X-13 reports `sspans = "failed"` when the series is too short — `accdeaths` and `ldeaths` at 6 years both fail. The diagnostic needs enough data for four overlapping spans of 8–11 years.

**5.** A series can pass Q (the adjustment looks tidy) yet fail sliding spans (the answer is not robust to which window you use). Q measures the quality of one adjustment; sliding spans measure whether that adjustment is stable.


**Going further.**

**GF1.** A trick question, and the interesting kind. Reasoning from $\Theta$ and length says **yes, comfortably** — high $\Theta$, 39 years, the catalogue's most stable series — and the hand-rolled version agrees: a mean maximum difference of $0.02$%, nothing flagged. But X-13 **reports no percentage at all**. `co2`'s seasonal factors range over 1.97 across all spans, and X-13 refuses to compute the summary when that range is below 10, because the entire seasonal swing is then smaller than two of the 3% flags it would be counting. The prediction was right and the diagnostic is still unavailable. See "When X-13 emits no percentage at all" in the note.

**GF2.** The cliff is at about 5 years, below which X-13 reports `sspans = "failed"` — you cannot build four overlapping 8-11 year spans. `accdeaths` and `ldeaths` at 6 years both fail.

**GF3.** **All three, but sample size dominates.** Quarterly means a quarter as many observations per span, and both series also have genuinely evolving seasonality. The frequency itself is not the problem; the data per span is.

**Practice set.**

**P1.** `AirPassengers` 2.08%, `imp` 5.56%, `iip` 0.00% pass; `UKgas` 40.62% and `JohnsonJohnson` 18.75% fail.

**P2.** The series is **too short** to build four overlapping spans — about five years is the floor. Only more data fixes it.

**P3.** Investigate before publishing. Sliding spans failing means the answer is not robust to which window you use, which is a different and more serious complaint than an untidy adjustment.

**P4.** Gate 1: the adjustment is **additive**, so X-13 compares spans by differences and never computes a percentage summary. `slidingspans.additivesa = "percent"` reopens it — but the numbers then arrive as `s2.c.per`, the implied adjustment factors, not `s2.a.per`.

**P5.** Gate 2: multiplicative, so percentages are meaningful in principle, but the **range of the seasonal factors is below 10**. Look at the third field of `ssran.all`. For `co2` it is 1.97 and for `cpi` 1.15.

**P6.** Your number is arithmetically fine and nearly useless. The hand-rolled version reports `co2` as stable — a mean maximum difference of $0.02$% — which is true but says nothing, because the whole seasonal swing is smaller than the 3% flagging threshold, so the flag rate could only ever have been zero. A diagnostic that cannot return a bad answer is not testing anything. For an additive series it is worse than useless: a percentage of a factor measured in persons is not a quantity.

**P7.** It conflates four distinct states — too short, additive, flat seasonal, and genuinely unstable — and only the last is a failure. Two of the other three are X-13 correctly declining to compute a meaningless number, and treating them as failures buries the real ones in noise. The script should read `sspans`, `ssdiff` and `s2.pct`, report which gate closed, and reserve "failed" for a run that produced a percentage above threshold.
## 50-05-revision-history

**1.** The difference between concurrent and full-sample estimates, month by month, is the revision history.

**2.** The **tail is much bigger than the mean** — the 95th percentile is several times the average. Quoting a mean revision understates what a user will occasionally experience.

**3.** 1.137% → 0.670%, a **41% reduction**, measured against a shared reference. Measure against different references and the improvement disappears into the definition.

**4.** Revision size decays with extra data, most of it in the first year or two.

**5.** SEATS usually revises slightly less when the model fits well, and the advantage disappears when it does not. The model-based method is only as good as the model.


**Going further.**

**GF1.** **Low-$\Theta$** series revise more: unstable seasonality means each new observation changes the estimate more. The relationship is a tendency rather than a law — sample length and outliers matter too.

**GF2.** Measured against each method's *own* final estimate, the improvement vanishes — you have changed the question. This is the mistake that made forecast extension look worthless in an early draft of 20-08.

**GF3.** Larger per observation, because each quarterly point carries four times the information and the end filters reach proportionally further.

**Practice set.**

**P1.** The 95th percentile is several times the mean — the tail is what users notice.

**P2.** Revisions are **unbiased but noisy** — they go both ways and cancel on average. That is the good case; a systematic sign would mean bias.

**P3.** Quote a typical size and a tail: 'usually under 1%, occasionally 3%, and largest around turning points.' Avoid a single average, which understates what they will occasionally see.
## 50-06-turning-points

**1.** 1.112% within a year of a recession versus 0.620% elsewhere, a ratio of **1.79×**.

**2.** The revisions are **systematically signed** during 2008–10 (mean $-0.313\%$ versus $+0.071\%$ elsewhere). A systematic sign means the concurrent estimate is **biased**, not merely noisy — the forecast extrapolated the old regime. That is mechanism 1, visible directly.

**3.** SEATS does not rescue you at a turn. Both methods need future data they do not have.

**4.** Trend curvature gives 1.42× with correlation 0.083 — much weaker than the 1.79× from actual recession dates. **A weak result can mean the effect is absent, or that your operationalisation is bad.** Check which before concluding "no effect".

**5.** The false-signal rate — concurrent month-to-month change having the opposite sign to the final one — is substantial, and worse near turns. It is the practical reason not to read single months.


**Going further.**

**GF1.** **Yes, opposite in sign.** At a peak the model under-predicts the downturn; at a trough it over-predicts continued decline. The bias direction follows the regime the model has seen, so it flips with the direction of the turn.

**GF2.** The ratio moves a lot — 1.42 for curvature, 1.79 for recession dates, 2.53 for the 2008-10 window. **The spread is the finding**: quote 'roughly 1.5-2.5x', never three digits.

**GF3.** The information about the turn does not exist yet — the filter needs future data and the model can only extrapolate the past. So the number will be revised, and by more than usual. Read three-month averages or year-on-year changes instead of single months.

**Practice set.**

**P1.** 1.112% within a year of a recession versus 0.620% elsewhere, ratio 1.79×.

**P2.** $-0.313\%$ inside 2008–2010 against $+0.071\%$ elsewhere.

**P3.** **Better.** A systematic sign means the concurrent estimate is *biased*; mean-zero means merely noisy. Bias is the harder failure because it cannot be averaged away.

**P4.** The latest figure is a real estimate, but it is the least settled one in the series, and it is least settled precisely when the economy is turning. It will be revised, probably by more than usual. Read the three-month average rather than the single month.
## 50-07-outliers-and-breaks

**1.** A **level shift** does most damage to the seasonal factors, because it is a permanent change that the filters try to absorb into the seasonal and trend. An AO is a single point and much easier to contain.

**2.** Modelling an LS as an AO leaves the break in the trend — the level genuinely changed and a one-point correction cannot represent that. The trend after the break is wrong by roughly the size of the shift.

**3.** Lowering `outlier.critical` finds more outliers; each one removed changes D11 a little. There is no free lunch: a low threshold risks removing genuine movement, a high one leaves contamination.

**4.** Detection near the **end** of a series is unreliable, because there is no future data to establish that the level stayed shifted. And you may not want it to fire: an LS detected in the final months is indistinguishable from the start of a genuine turn.

**5.** Sliding spans catch a seasonal break; QS does not, for the reason in 50-02 exercise 4.


**Going further.**

**GF1.** The **LS**, by a wide margin. An AO is one point and is largely absorbed by the irregular; a level shift is permanent and the filters try to spread it across trend and seasonal, contaminating years either side.

**GF2.** Detection is unreliable there, and arguably **should not** fire: an LS in the final months is statistically indistinguishable from the beginning of a genuine turn. Treating a real turn as an outlier would erase exactly the signal you most need.

**GF3.** Similar in **years**, which means fewer observations affected — the filters are the same length in years regardless of frequency.

**Practice set.**

**P1.** The **LS** does the most damage by a wide margin; the AO the least.

**P2.** A lower threshold finds more; each removal changes D11 a little. There is no free setting.

**P3.** A **level shift** detected in September 2008. Keep it if the level genuinely changed permanently — which in that case it did.

**P4.** **Wait**, if you can. Detection at the end is unreliable, and an LS in the final months is indistinguishable from the start of a genuine turn.
## 50-08-covid

**1.** Untreated, a COVID-scale shock contaminates the seasonal factors for **years** in both directions — the filters are two-sided, so damage propagates backwards as well as forwards.

**2.** Treating the shock as AOs removes most of the contamination. This is what statistical agencies actually did in 2020.

**3.** An LS is wrong if the level recovered, and right if it did not — which was genuinely unclear in 2020 and is the reason different agencies made different choices.

**4.** Excluding the shock from the estimation span while still publishing those months is often the cleanest option: the model never sees the anomaly, but the data is not hidden.

**5.** The reach is measured in **years**, not months. That is the practical consequence of a symmetric filter: a single extreme point is smeared across its whole width.


**Going further.**

**GF1.** **Years**, in both directions — the symmetric filter smears a single extreme point across its whole width, so history is contaminated too.

**GF2.** A great deal survives. A single AO cannot represent a six-month disruption; you need one per affected month, or a span exclusion.

**GF3.** For an LS: the level genuinely may not have returned to trend. Against: much of the 2020 drop did recover, and an LS would permanently displace the trend. What settles it is *later data* — which is precisely what was unavailable when the decision had to be made, and is the turning-point problem in its sharpest form.

**Practice set.**

**P1.** Untreated, seasonal factors move by well over 1% for **years** either side.

**P2.** Because the filters are **two-sided**. An event in 2020 enters the estimation of factors before 2020 as well — the contamination runs backwards.

**P3.** 'Figures from 2020 onward are affected by pandemic-related disruption; outlier terms have been included so that the seasonal pattern is estimated from unaffected periods. Seasonal factors for earlier years may also have changed as a result.'
## 50-09-x11-vs-seats

**1.** The methods differ most on **low-$\Theta$** series — fast-evolving seasonality, where SEATS adapts its filter and X-11 cannot.

**2.** `imp`'s worst month is Chinese New Year: a moving holiday, not an outlier or a break ([[50-10-calendar-effects]]).

**3.** For `UKgas` the difference is visible in the statistics but hard to see by eye. Most of the time the two methods agree far more than the debate between them suggests.

**4.** Neither method wins on revisions in general; it depends on model fit.

**5.** Fitting the correct $d=0$ model to `ldeaths` brings the methods closer. Much of the apparent method difference is really a model-specification difference wearing a disguise.


**Going further.**

**GF1.** They differ **less** on high-$\Theta$ series. Stable seasonality is easy and both methods find nearly the same answer; the disagreement grows as the seasonal evolves, because SEATS adapts its filter and X-11 cannot.

**GF2.** **SEATS**, because it derives its filter from the model — a bad model gives a bad filter. X-11's fixed filters are more robust to misspecification, which is a real argument in its favour.

**GF3.** The ranking holds, but both are noisier on quarterly data for the sample-size reason.

**Practice set.**

**P1.** Mean around 0.53% and max around 2.63% on `AirPassengers`; larger on low-$\Theta$ series.

**P2.** That **one month**. A single large difference usually means an outlier, a moving holiday, or a break — on `imp` it is Chinese New Year.

**P3.** Either is defensible. What matters far more is the **model and the outlier treatment**: the method difference is 0.5%, and a misspecified model or an untreated level shift will cost you more than that. Pick one, document it, and stay consistent.
## 50-10-calendar-effects

**1.** Easter[1] is significant for `AirPassengers` ($+0.0234$, $t = 2.63$, $p = 0.0086$) and absent for `unemp` ($p = 0.60$).

**2.** The CNY coefficient is $-0.1230$ with $t = -7.52$ — imports fall about **12%** in the run-up as factories close.

**3.** AICC is best at $-3\ldots0$ (3062.97) and degrades monotonically to $-28\ldots0$ (3093.96), while the coefficient barely moves. A longer window **dilutes the same effect over more months** rather than finding a different one.

**4.** Skipping `center = "calendar"` changes the published seasonal factors by up to **6.06%**. The uncentred regressor has mean $1/12$ instead of 0, overlaps the seasonal pattern, and the split between them becomes arbitrary.

**5.** Diwali on `iip` is $-0.0333$, $t = -4.03$ — real, and about a quarter the size of CNY's.

**6.** February and March move most, since that is where Chinese New Year lands. **Every economy has its own moving holidays** — use the one that belongs to the series, not the one you happen to know.

---


**Going further.**

**GF1.** **Retail**, decisively — sales depend on how many Saturdays a month contains. Unemployment is measured on a reference week and is largely insulated. The mechanism tells you where to look before any test does.

**GF2.** It does: on `unemp` the Easter coefficient has $p = 0.60$, and `regression.aictest` drops it. Fitting a term that is not there is cheap to test and easy to over-believe.

**GF3.** Nothing changes structurally — `genhol()` takes any vector of dates. What changes is that you must **know the calendar**: Ramadan moves through the solar year rather than oscillating within a season, so the window and the centring need more care.

**Practice set.**

**P1.** Trading day matters most where activity depends on the day of the week; on `imp` it is not significant at all (max $|t| = 1.27$).

**P2.** CNY on `imp`: $-0.1230$, $t = -7.52$. Diwali on `iip`: $-0.0333$, $t = -4.03$.

**P3.** Activity falls about **12%** in the window before the holiday, and the effect is far too large to be chance.

**P4.** **Trading day first** (retail depends on weekend counts), then **Easter**, then check for anything local. Test trading day before holidays — analysts usually do it the other way round and it is usually the wrong order.
## Links

- Back to [[00-Start-Here]] · derivations: [[derivations]] · figures: [[figure-index]]
