---
aliases: [Derivations, Appendix B, Algebra appendix]
tags: [meta, appendix, reference]
---

# Appendix: derivations

The notes state results and show that they hold numerically. This appendix does the algebra, once, in one place, so a note can say *why* without a two-page detour. Every entry is linked from the note that uses it.

Read it when a result feels like it arrived by decree. Skip it otherwise — nothing downstream depends on having read it.

Notation throughout: $B$ is the backshift operator, $F = B^{-1}$, $a_t$ is white noise with variance $\sigma_a^2$, and the MA sign convention is Census/Box–Jenkins, $\theta(B) = 1 - \theta_1 B - \cdots$ ([[10-11-sign-conventions]]).

---

## D1. Stationarity means roots outside the unit circle

For AR(1), $(1-\phi B)z_t = a_t$. Invert the operator as a geometric series:

$$z_t = \frac{1}{1-\phi B}a_t = \sum_{j\ge 0}\phi^j a_{t-j}$$

The variance of that sum is $\sigma_a^2\sum_j \phi^{2j}$, which converges **iff** $|\phi| < 1$. So the process has finite variance exactly when the series converges.

Now write it as a root condition. The polynomial $1-\phi B$ has its root at $B = 1/\phi$, so

$$|\phi| < 1 \iff |1/\phi| > 1 \iff \text{the root lies outside the unit circle.}$$

The general case is the same argument after factoring $\phi(B) = \prod_i (1 - \alpha_i B)$: each factor must be invertible, so every root must sit outside. The convergence condition and the stationarity condition are one statement.

Used by [[10-02-stationarity-and-roots]], [[10-01-lag-operator]].

---

## D2. The MA(1) autocorrelation, and why it cannot exceed one half

With $z_t = a_t - \theta a_{t-1}$ and $E[a_t a_s] = 0$ for $t \ne s$:

$$\gamma_0 = E[z_t^2] = (1+\theta^2)\sigma_a^2, \qquad
\gamma_1 = E[z_t z_{t-1}] = -\theta\sigma_a^2, \qquad \gamma_k = 0 \ (k \ge 2)$$

The $\gamma_k = 0$ for $k \ge 2$ is immediate: $z_t$ and $z_{t-k}$ share no shock. That is the **cut-off** that identifies an MA. Dividing,

$$\rho_1 = \frac{-\theta}{1+\theta^2}$$

Now maximise. $\frac{d}{d\theta}\frac{\theta}{1+\theta^2} = \frac{1-\theta^2}{(1+\theta^2)^2}$, zero at $\theta = \pm 1$, giving $|\rho_1| = 1/2$. So

$$|\rho_1| \le \tfrac12 \quad\text{for every MA(1), whatever } \theta.$$

If a sample first autocorrelation is 0.8, no MA(1) can have produced it — that is a genuine falsification, not a rule of thumb.

Used by [[10-04-ma-processes]], [[10-07-acf-and-pacf]].

---

## D3. Why $\theta$ and $1/\theta$ are indistinguishable

Substitute $\theta \to 1/\theta$ into D2:

$$\rho_1(1/\theta) = \frac{-1/\theta}{1+1/\theta^2} = \frac{-1/\theta}{\frac{\theta^2+1}{\theta^2}} = \frac{-\theta}{1+\theta^2} = \rho_1(\theta)$$

Identical. Since an MA(1) is fully described by $\rho_1$, the two models are observationally equivalent — the data cannot choose, and neither can the likelihood.

Something must break the tie. Write the model as an infinite AR by inverting the MA polynomial:

$$\frac{1}{1-\theta B}z_t = a_t \implies z_t = \sum_{j\ge1}\theta^j z_{t-j} + a_t$$

For $|\theta| < 1$ the $\pi$-weights $\theta^j$ decay; for $|\theta| > 1$ they explode, which says the distant past matters *more* than the recent past. **Invertibility** is the convention that picks the first. It is a choice of representation, not an empirical finding — the same kind of choice as the canonical decomposition in D9.

Used by [[10-05-invertibility]].

---

## D4. The seasonal difference contains the trend difference

$$1 - B^s = (1-B)\left(1 + B + B^2 + \cdots + B^{s-1}\right)$$

Verify by expanding: the product telescopes, every interior power cancelling against its neighbour, leaving $1 - B^s$.

This factorisation is the seed of the whole subject. The $s$ roots of $1-B^s$ are the $s$th roots of unity, $e^{2\pi i k/s}$ for $k = 0,\dots,s-1$. The $k=0$ root is $B=1$ — **the trend root**, the $(1-B)$ factor. The remaining $s-1$ roots are the seasonal ones, and they are what $S(B) = 1 + B + \cdots + B^{s-1}$ carries.

So a seasonal difference silently applies a regular difference too. Applying $(1-B)(1-B^s)$ therefore differences the trend *twice*:

$$(1-B)(1-B^s) = (1-B)^2 S(B)$$

That split — $(1-B)^2$ to the trend, $S(B)$ to the seasonal — is literally step one of the SEATS algorithm ([[40-01-unobserved-components-and-reduced-form]]).

Used by [[10-06-differencing]], [[10-09-seasonal-arima]], [[40-01-unobserved-components-and-reduced-form]].

---

## D5. A constant in a differenced model is a drift

Apply $(1-B)$ to a linear trend:

$$(1-B)(\alpha + \beta t) = (\alpha + \beta t) - (\alpha + \beta(t-1)) = \beta$$

The level $\alpha$ vanishes and the slope survives as a constant. Reading it backwards: a constant $\beta$ in a $d=1$ model integrates to $\alpha + \beta t$ in the original units. So the fitted "constant" is a **slope per period**, not a level.

For general $d$ the constant integrates to a degree-$d$ polynomial, which is why a constant with $d=2$ implies a quadratic trend and is almost never what anyone wants.

Used by [[10-06-differencing]].

---

## D6. The spectral density, and the ARMA formula

The spectral density is the Fourier transform of the autocovariances:

$$f(\omega) = \frac{1}{2\pi}\sum_{k=-\infty}^{\infty}\gamma_k e^{-i\omega k}$$

It is real and even because $\gamma_k = \gamma_{-k}$, so the imaginary parts cancel in pairs — which is why only $[0,\pi]$ is ever plotted.

For the filtering step, let $z_t = \nu(B)a_t$. Then

$$f_z(\omega) = |\nu(e^{-i\omega})|^2 f_a(\omega)$$

**the filtering theorem**: a filter multiplies the spectrum by its squared gain. Applying it to $\phi(B)z_t = \theta(B)a_t$, where white noise has the flat spectrum $f_a = \sigma_a^2/2\pi$:

$$f_z(\omega) = \frac{\sigma_a^2}{2\pi}\,\frac{|\theta(e^{-i\omega})|^2}{|\phi(e^{-i\omega})|^2}$$

The squared modulus is where the $B$-and-$F$ pairing comes from, since $|w|^2 = w\bar w$ gives

$$|\theta(e^{-i\omega})|^2 = \theta(e^{-i\omega})\theta(e^{i\omega}) \ \longleftrightarrow\ \theta(B)\theta(F)$$

Nothing more exotic than that. Roots of $\phi$ near the unit circle make the denominator small — **peaks**; roots of $\theta$ on it make the numerator zero — **exact zeros**.

Used by [[30-02-spectral-density]], [[30-03-spectrum-of-an-arma]], [[30-05-filters-in-the-frequency-domain]].

---

## D7. Why differencing is a filter with zeros where the seasonal lives

Take $\nu(B) = 1-B^s$ and evaluate its squared gain at $B \to e^{-i\omega}$:

$$|1-e^{-i\omega s}|^2 = (1-e^{-i\omega s})(1-e^{i\omega s}) = 2 - 2\cos(\omega s)$$

This is zero exactly when $\cos(\omega s) = 1$, i.e. $\omega = 2\pi k/s$ — frequency zero and every seasonal frequency. So seasonal differencing does not remove seasonality by magic: it applies a filter whose gain is **exactly zero** at the trend frequency and at all $\lfloor s/2 \rfloor$ seasonal frequencies.

The same computation with $\nu(B) = 1-B$ gives $2-2\cos\omega$, zero only at $\omega = 0$: the ordinary difference kills the trend and nothing else.

Used by [[10-06-differencing]], [[30-05-filters-in-the-frequency-domain]], [[30-04-pseudo-spectrum]].

---

## D8. The Wiener–Kolmogorov filter

Suppose $z_t = s_t + n_t$ with $s$ and $n$ uncorrelated, so $f_z = f_s + f_n$. Look for the linear filter $\nu(B)$ minimising $E[(\hat s_t - s_t)^2]$ with $\hat s_t = \nu(B)z_t$.

Orthogonality requires the error to be uncorrelated with every observation, which in the frequency domain reads

$$\nu(\omega)f_z(\omega) = f_s(\omega) \implies \boxed{\ \nu(\omega) = \frac{f_s(\omega)}{f_z(\omega)}\ }$$

**Keep the share of the power that is yours.** At a frequency where the signal owns all the power the gain is 1; where it owns none, 0; in between it is the ratio.

Two consequences the notes lean on. The filter is a ratio of spectra, each symmetric in $B$ and $F$, so $\nu$ is **real and symmetric** — hence **zero phase**, and no turning point is displaced ([[30-05-filters-in-the-frequency-domain]]). And it is generally an *infinite* two-sided filter, which is the entire problem that [[30-07-finite-samples]] exists to solve.

Used by [[30-06-wiener-kolmogorov]], [[40-06-wk-filters-for-the-airline-model]].

---

## D9. The canonical decomposition, and why it is a convention

Write the reduced form $\phi(B)z_t = \theta(B)a_t$ and split the AR side by frequency: $\phi = \phi_T\phi_S$, trend roots to $\phi_T$, seasonal roots to $\phi_S$ (D4 says how). Partial fractions in $B$ and $F$ then give

$$f_z(\omega) = f_T(\omega) + f_S(\omega) + f_I(\omega)$$

with $f_T$ carrying the $\phi_T$ poles and $f_S$ the $\phi_S$ poles.

That split is **not unique**. If $c \ge 0$, moving a constant from one component to another,

$$f_T' = f_T - c, \qquad f_I' = f_I + c$$

leaves the sum unchanged and both pieces are still valid spectra provided they stay non-negative. So there is a one-parameter family of admissible decompositions, and the data cannot choose among them — the same non-identification as D3, one level up.

The **canonical** choice (Hillmer–Bell) subtracts from each component its own minimum over $[0,\pi]$ and gives the total to the irregular:

$$f_T^{can} = f_T - \min_\omega f_T, \qquad\text{etc.}$$

This makes every component as smooth as it can be — each touches zero somewhere — and dumps all the remaining flat noise into the irregular, which is where noise belongs. It is a convention with a defensible motive, not a result.

**Admissibility** is the requirement that the leftover irregular variance is non-negative. It fails for some $(\theta,\Theta)$, which is exactly when X-13 substitutes a different model ([[40-02-admissible-decompositions]]).

Used by [[40-03-canonical-decomposition]], [[40-02-admissible-decompositions]].

---

## D10. Why the WK filters have no poles

This is the fact that makes the implementation tractable, and it is easy to miss.

The trend filter is $\nu_T = f_T/f_z$. Write $f_T = A(B,F)/[\phi_T\phi_T^{*}]$ and $f_z = N(B,F)/[\phi_T\phi_T^{*}\phi_S\phi_S^{*}]$, where $N = \theta\theta^*$. Then

$$\nu_T = \frac{A/[\phi_T\phi_T^{*}]}{N/[\phi_T\phi_T^{*}\phi_S\phi_S^{*}]} = \frac{A\,\phi_S\phi_S^{*}}{N}$$

The $\phi_T$ factors **cancel**. The denominator that survives is $N = \theta\theta^{*}$, whose roots are the *MA* roots — and those lie outside the unit circle for an invertible model.

So although the pseudo-spectrum has infinite peaks at the unit roots (D7, and [[30-04-pseudo-spectrum]]), the filter derived from it is a perfectly ordinary rational function with no poles on the circle. Infinite quantities appear in the intermediate algebra and cancel before anything is evaluated numerically. That is why [[40-07-implementing-seats-in-r]] never needs a special case for the seven infinite peaks.

Used by [[40-06-wk-filters-for-the-airline-model]], [[40-07-implementing-seats-in-r]].

---

## D11. Why a symmetric filter has zero phase, and an end filter does not

For a symmetric filter, $w_j = w_{-j}$, the transfer function is

$$\nu(e^{-i\omega}) = \sum_j w_j e^{-i\omega j} = w_0 + \sum_{j\ge1} w_j\left(e^{-i\omega j} + e^{i\omega j}\right) = w_0 + 2\sum_{j\ge1}w_j\cos(\omega j)$$

The sines cancel in pairs, so this is **real**. A real transfer function has phase 0 (or $\pi$ where it is negative), meaning no frequency is shifted in time.

Drop the future half — which is what you must do at the end of a sample — and the cancellation fails. The transfer function acquires an imaginary part, the phase becomes frequency-dependent, and different cycles are displaced by different amounts. In an adjusted series that means **turning points move**, and they move by an amount that changes as new data arrives.

That is the precise statement of what goes wrong at the end of a series, and the reason revisions concentrate there ([[20-07-end-filters]], [[50-06-turning-points]]).

Used by [[30-05-filters-in-the-frequency-domain]], [[20-07-end-filters]].

---

## D12. Why a centred $2\times s$ moving average is needed for even $s$

A simple $s$-term average kills seasonality — it averages one full cycle — but for even $s$ it does not sit on an observation. With $s=12$, averaging months $t-5.5$ to $t+5.5$ has its centre half a month off.

The fix is to average two adjacent $s$-term averages, which is the same as the weight vector

$$\left(\tfrac{1}{2s},\ \tfrac1s,\ \tfrac1s,\ \dots,\ \tfrac1s,\ \tfrac{1}{2s}\right)$$

with $s-1$ interior weights — the half-weights on the endpoints being exactly the correction that recentres it. The weights sum to 1, the filter is symmetric (so D11 applies: zero phase), and its gain is still zero at all seasonal frequencies.

For odd $s$ no correction is needed, which is why quarterly and monthly code paths differ ([[20-02-the-12-term-ma]]).

Used by [[20-02-the-12-term-ma]].

---

## D13. What the likelihood actually is

The phrase "exact maximum likelihood" hides a simple idea: **the likelihood is built out of one-step-ahead forecast errors.**

Factor the joint density of the sample by the chain rule:

$$L(\beta) = p(z_1,\dots,z_n) = \prod_{t=1}^{n} p(z_t \mid z_{t-1},\dots,z_1)$$

Under Gaussianity each conditional is normal with mean the one-step forecast $\hat z_{t|t-1}$ and variance $v_t$, so with $e_t = z_t - \hat z_{t|t-1}$,

$$-2\log L = \sum_{t=1}^{n}\left[\log(2\pi v_t) + \frac{e_t^2}{v_t}\right]$$

This is the **prediction-error decomposition**. The Kalman filter's only job is to produce $\hat z_{t|t-1}$ and $v_t$ for every $t$, including the awkward early ones where there is little history. That is the entire content of "state-space form plus Kalman filter".

**Concentrating out the variance.** Write $v_t = \sigma_a^2 r_t$, where $r_t$ depends on the ARIMA parameters but not on $\sigma_a^2$. Substituting and differentiating with respect to $\sigma_a^2$ gives a closed form:

$$\hat\sigma_a^2 = \frac1n\sum_{t=1}^n \frac{e_t^2}{r_t}$$

Put that back and the likelihood depends only on the remaining parameters:

$$-2\log L \propto n\log\hat\sigma_a^2 + \sum_t \log r_t$$

So the optimiser never searches over $\sigma_a^2$ — for the airline model it searches a **two-dimensional** surface in $(\theta,\Theta)$, which is why that surface can simply be plotted ([[10-12-estimation]]).

**Why "conditional" sum of squares is different.** CSS sets the pre-sample shocks to zero and minimises $\sum \hat a_t^2$, which amounts to dropping the $\log r_t$ term and pretending $r_t = 1$. The neglected part is an end effect that shrinks as $n$ grows — *unless* an MA root sits near the unit circle, where the pre-sample contribution stays material at any sample size. Seasonal MA parameters live near that boundary, so the approximation is worst exactly where seasonal adjustment operates.

**Standard errors** come from the curvature of this surface: the observed information is the Hessian of $-\log L$ at the optimum, and the covariance matrix is its inverse. A flat surface therefore *means* large standard errors — which is why a common AR/MA factor (D3's problem, one level up) produces both a ridge and unstable estimates.

Used by [[10-12-estimation]], [[10-13-model-selection]].

---

## D14. Forecasting, from the difference equation

Forecasting an ARIMA needs no new theory — just the model, written as a difference equation, plus two rules for taking expectations.

**Step 1: expand the model into a recipe.** For the airline model,

$$(1-B)(1-B^{12})z_t = (1-\theta B)(1-\Theta B^{12})a_t$$

Multiply out both sides (D4 for the left, and the same expansion for the right):

$$z_t - z_{t-1} - z_{t-12} + z_{t-13} = a_t - \theta a_{t-1} - \Theta a_{t-12} + \theta\Theta a_{t-13}$$

Rearranged so the current value is alone on the left:

$$z_t = z_{t-1} + z_{t-12} - z_{t-13} + a_t - \theta a_{t-1} - \Theta a_{t-12} + \theta\Theta a_{t-13}$$

Every ARIMA forecast comes from an equation of this shape. The $B^{13}$ terms that nobody writes by hand are the reason to trust the algebra over intuition.

**Step 2: take conditional expectations at time $n$.** Write $\hat z_{n+h} = E[z_{n+h}\mid z_n, z_{n-1},\dots]$. Two rules cover everything:

$$E[z_{n+j}] = \begin{cases} z_{n+j} & j \le 0 \ \text{(observed)} \\ \hat z_{n+j} & j > 0 \ \text{(already forecast)}\end{cases}
\qquad
E[a_{n+j}] = \begin{cases} \hat a_{n+j} & j \le 0 \ \text{(the residual)} \\ 0 & j > 0 \ \text{(unknowable)}\end{cases}$$

The second rule is the whole of forecasting: **future shocks have expectation zero.** A forecast is what the model says happens if nothing new occurs.

So the one-step forecast is

$$\hat z_{n+1} = z_n + z_{n-11} - z_{n-12} - \theta \hat a_n - \Theta \hat a_{n-11} + \theta\Theta \hat a_{n-12}$$

and for $h \ge 2$ you apply the same line again, substituting forecasts for the $z$'s you have not seen and zeros for the $a$'s. It is a recursion: each forecast feeds the next.

**Step 3: the uncertainty.** Write the model in $\psi$-weight form, $z_t = \sum_{j\ge0}\psi_j a_{t-j}$ ([[10-08-arma-duality]]). Then

$$z_{n+h} = \underbrace{\sum_{j\ge h}\psi_j a_{n+h-j}}_{\text{known at time } n} + \underbrace{\sum_{j=0}^{h-1}\psi_j a_{n+h-j}}_{\text{future shocks}}$$

The first part is $\hat z_{n+h}$; the second is the forecast error. Since the $a$'s are uncorrelated with variance $\sigma_a^2$,

$$\operatorname{Var}(e_h) = \sigma_a^2\sum_{j=0}^{h-1}\psi_j^2$$

This is a **sum of squares that only grows with $h$** — the interval can never narrow as you look further out. For a stationary model the $\psi_j$ decay and the variance approaches the process variance; for a differenced model they do not decay, and the interval widens without bound. That is the formal reason a forecast-extended filter helps less the further past the sample end you reach ([[30-07-finite-samples]], [[20-08-x11-arima]]).

Used by [[10-14-forecasting]], [[10-08-arma-duality]].

---

## D15. Exact ML for a general ARIMA: the state-space form

D13 said the likelihood is built from one-step errors. This says how to get them for *any* $(p,d,q)(P,D,Q)_s$, not just the airline model.

**Step 1: there is no such thing as a seasonal model.** Multiply the polynomials out:

$$\phi(B)\Phi(B^s) \quad\text{and}\quad \theta(B)\Theta(B^s)$$

The result is an ordinary ARMA whose coefficients are mostly zero. The airline model becomes ARMA$(0,13)$ with nonzero MA terms only at lags 1, 12 and 13. Difference the data first ($d$ regular, $D$ seasonal) and what remains is a stationary ARMA problem. Everything below is for ARMA$(p,q)$.

**Step 2: write it as a state-space model.** Let $r = \max(p,\,q+1)$ and take

$$T = \begin{pmatrix}\phi_1 & 1 & 0 & \cdots \\ \phi_2 & 0 & 1 & \cdots \\ \vdots & & & \\ \phi_r & 0 & 0 & \cdots\end{pmatrix},
\qquad
R = \begin{pmatrix}1 \\ \theta_1 \\ \vdots \\ \theta_{r-1}\end{pmatrix},
\qquad
Z = (1, 0, \dots, 0)$$

with $\phi_j = 0$ for $j>p$ and $\theta_j = 0$ for $j>q$, and

$$\alpha_t = T\alpha_{t-1} + Ra_t, \qquad z_t = Z\alpha_t$$

The dimension is $\max(p, q+1)$, not $p$: the state must carry the MA terms that have not yet worked their way out. For the differenced airline model $r = 14$ — large because the *MA* reaches back 13 periods, not because of any AR structure.

**Step 3: initialise.** For a stationary ARMA the state has a stationary distribution, so $P_0$ solves the discrete Lyapunov equation

$$P_0 = TP_0T' + RR' \qquad\Longrightarrow\qquad \operatorname{vec}(P_0) = (I - T\otimes T)^{-1}\operatorname{vec}(RR')$$

This is the "exact" in exact maximum likelihood. Getting it right is what distinguishes exact ML from CSS, which effectively starts from zero and pretends the transient does not exist.

**Step 4: filter.** For $t = 1,\dots,n$, with $a_{t|t-1}$ and $P_{t|t-1}$ the predicted state and its covariance:

$$\begin{aligned}
\text{predict:}\quad & a \leftarrow Ta, \qquad P \leftarrow TPT' + RR' \\
\text{error:}\quad & v_t = z_t - Za, \qquad F_t = ZPZ' \\
\text{gain:}\quad & K = PZ'/F_t \\
\text{update:}\quad & a \leftarrow a + Kv_t, \qquad P \leftarrow P - KZP
\end{aligned}$$

Because $Z = (1,0,\dots,0)$, every $Z$ here just means "take the first element", and $F_t = P_{11}$.

**Step 5: assemble the likelihood.** With $\sigma_a^2$ concentrated out as in D13,

$$\hat\sigma_a^2 = \frac1n\sum_t \frac{v_t^2}{F_t}, \qquad
\log L = -\tfrac12\left[n\log(2\pi\hat\sigma_a^2) + \sum_t \log F_t + n\right]$$

Then hand $-\log L$ to a numerical optimiser over $(\phi,\theta,\Phi,\Theta)$. That is the whole algorithm, and `R/10-12b-general-estimation.R` is 90 lines of it.

**A note on how R does it.** `stats::arima()` does *not* difference first. It keeps the differencing inside the state and gives those elements a diffuse prior of variance $\kappa$ (default $10^6$), which is an approximation of order $1/\kappa$. Differencing first and using the exact $P_0$ is the limit it converges to — measurably so ([[10-12-estimation]]).

Used by [[10-12-estimation]], [[10-13-model-selection]].

---

## Links

- Back to [[00-Start-Here]] · figure appendix: [[figure-index]]
- Sources for the fuller treatments: [[glossary]] and the references in the README — Hillmer & Bell (1982) for D9 and D10, Findley et al. (1998) for the X-13 side.
