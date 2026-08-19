---
aliases: [Quiz Module 4]
tags: [quiz, module-4]
---

# Quiz — Module 4 (SEATS)

#flashcards/module-4

The destination. If you can answer these you can implement the method.

---

## Reduced form

What is the reduced form of a structural model? ::: Apply the differencing operator to trend + seasonal + irregular. Each component's own operator cancels part of it, leaving a sum of independent MAs — which is itself an MA. For the basic structural model that reduced form is the airline model.

Why is the airline model not an arbitrary choice? ::: It is what "trend + seasonal + noise" *looks like* after $\nabla\nabla_{12}$. The structural model has three variances; the airline model has $\theta$, $\Theta$, $\sigma_a^2$ — also three.

What does SEATS do with the bridge? ::: Runs it backwards. Fit the reduced form to the data, then recover the structural components it must have come from.

Is the map between structural and reduced form a bijection? ::: No. Some $(\theta,\Theta)$ correspond to no valid non-negative variances (inadmissible), and where a decomposition exists it is generally not unique (needs a convention).

Structural modelling vs SEATS ::: Structural (Harvey/STAMP) specifies components up front and fits them by Kalman filter. SEATS fits the observed series and derives components by algebra. Neither dominates; SEATS's advantage is that fitting an ARIMA is routine and shares machinery with regARIMA preadjustment.

## Admissibility

What makes a decomposition inadmissible? ::: One of the component spectra goes negative somewhere. A negative spectrum means a negative variance, which does not exist.

How much of the airline parameter space is admissible? ::: About **27.4%**. But $\theta>0$ *and* $\Theta>0$ is **100%** admissible, while the other three quadrants are 0.5–2.8%.

Rule of thumb for airline-model admissibility ::: Both MA parameters positive in the Census convention. Since well-behaved economic series give positive Census MA parameters, real data is nearly always admissible — which is why you can adjust hundreds of series and never meet this.

Which component usually goes negative, and why? ::: The irregular. Its spectrum is the flat constant left over after the trend and seasonal take their share; a negative $\theta$ puts a peak rather than a trough at high frequency, so the leftover comes out negative.

What does SEATS do when the model is inadmissible? ::: Replaces it with a nearby admissible model and carries on, printing "Model used in SEATS is different". Controlled by `seats.noadmiss`.

Why does that matter to a user? ::: **The components did not come from the model you fitted.** Your model identification, AICC comparisons and residual diagnostics applied to a model that was then discarded. Check with `udg(m, "seatsmdl")`.

## The canonical decomposition

Why is a convention needed at all? ::: The decomposition is not identified. You can move white noise between any component and the irregular; every such split gives the same $f_z$, so the data cannot choose.

State the canonical rule ::: Give the irregular as much variance as possible — subtract from each component the minimum of its spectrum over frequency and add it all to the irregular.

Why is that the extreme point? ::: Subtracting more than the minimum would make a spectrum negative. So it is the boundary of the admissible family, which is what makes the answer unique.

The best argument for the canonical rule ::: It is conservative. Any variance that *might* be noise is called noise, so the signal you report is the part that cannot be anything else. Leaving noise in the trend asserts structure the data cannot support.

What does the canonical rule do to each component's spectrum? ::: Makes it touch zero somewhere — which is exactly a **unit MA root**, i.e. a non-invertible component. By construction, not by accident.

Where do the zeros land for the airline model? ::: The canonical trend's spectrum touches zero at $\omega=\pi$; the canonical seasonal touches zero between the seasonal frequencies (measured: $\omega \approx 2.88$).

How much variance does the rule move, on AirPassengers? ::: $m_T = 0.0514$ and $m_S = 0.0225$, together about **25%** of the final irregular's variance. Across the catalogue it ranges from ~0% (`nottem`, deterministic seasonality) to 90% (`unemp`).

## The algebra

Write the partial-fraction identity ::: $N = A\,D_S + C\,D_T + D\,D_TD_S$, where $N=|\theta|^2$, $D_T=|(1-B)^2|^2$, $D_S=|S(B)|^2$.

What is a cosine polynomial, and why use one? ::: A real even function written $c_0 + 2\sum_k c_k\cos(k\omega)$. For $|P(e^{-i\omega})|^2$ the coefficients are the autocovariances of $P$'s coefficients. Storing spectra this way turns the whole problem into real linear algebra — no complex arithmetic.

The degree bookkeeping for $s=12$ ::: $\deg N = 13$, $\deg D_T = 2$, $\deg D_S = 11$, $\deg D_TD_S = 13$. So $\deg A \le 1$, $\deg C \le 10$, $D$ constant: $2+11+1 = 14$ unknowns and 14 coefficients in $N$. Square.

Why are the WK filters pole-free? ::: $\nu_T = (A/D_T)\big/\big(N/(D_TD_S)\big) = A\,D_S/N$ — $D_T$ cancels. The infinite peaks appear in both numerator and denominator and divide out, so the filter is an ordinary smooth function.

Why do the three filters sum to 1? ::: $\nu_T+\nu_S+\nu_I = (AD_S + CD_T + D\,D_TD_S)/N = N/N = 1$ — the same identity that defines the partial fractions.

## Component models

What model does the canonical trend follow? ::: **ARIMA(0,2,2)** — which is the reduced form of a local linear trend, level and slope both random walks.

Clever way to read a component's model off the algebra ::: The spectrum of $(1-B)^2T$ is $D_T \cdot (A_{\text{can}}/D_T) = A_{\text{can}}$, and a cosine polynomial's coefficients *are* the autocovariances. Degree 2 means autocovariances vanish beyond lag 2, i.e. MA(2). No spectral factorisation needed.

Why does the canonical step raise the numerator degree by one? ::: Subtracting $m_TD_T$ (degree 2) from $A$ (degree 1) gives degree 2. That extra degree is the unit MA root the rule creates.

Is the canonical irregular approximately white? ::: Exactly white. Its spectrum is a constant by construction.

Standing caution about component models ::: They are implied by the fitted reduced form plus the convention — never estimated from component data, because none exists. You are reporting the consequences of assumptions, not measurements.

## The filters

Who owns which frequency, for the airline model? ::: $\nu_T(0)=1$; $\nu_S=1$ at every seasonal frequency; the irregular takes the gaps. Measured: $\nu_T(0)=1.00000$, $\nu_S(2\pi/12)=0.99994$.

Why is $\nu_S(\pi) = 1$ and not a bug? ::: $\omega=\pi$ *is* a seasonal frequency for monthly data — $k=6$, the two-month cycle. The seasonal legitimately owns all the power there.

How fast do the seasonal filter weights decay? ::: At roughly $\Theta$ per **year**. $\Theta = 0.557$ needs about 331 lags (27.6 years); $\Theta = 0.9$ needs 50+ years.

The real difference between X-11 and SEATS filters ::: Not sharpness but **adaptivity**. SEATS narrows the notches for stable seasonality and widens them for volatile, automatically, because $\Theta$ says which. X-11 picks from a small fixed menu.

## Implementation

The nine steps ::: fit ARIMA → split the AR side → build cosine polynomials → partial fractions → check admissibility → canonical shift → WK filters → invert to weights, extend with forecasts, filter → normalise the constant.

Trap: what does truncating the filter too early look like? ::: A **constant level offset**, not noise — because the weights no longer sum to $\nu(0)$. Symptom: your component correlates with the reference at 0.999 but sits a fixed distance away.

Trap: what if the extension is shorter than the filter? ::: The convolution has no valid range and you get all `NA`, or silent `NA`s near the ends. Assert `extend >= max_lag`.

Trap: why is the trend/seasonal constant a convention? ::: $\nu_S(0)=0$, so the seasonal filter annihilates constants — the theory cannot say which component a constant belongs to. X-13 makes multiplicative factors average 1 in **levels**, forcing a log-mean of $-\sigma^2/2$. Skipping it costs 0.88%.

The single best end-to-end test of an implementation ::: $T + S + I = \log z$ exactly. It is sensitive to every step and needs no reference implementation.

Which options must be pinned when comparing against X-13? ::: `transform.function` (or it may run additive while you run multiplicative), `arima.model`, `regression.aictest`, `outlier`. When a comparison fails by a lot, suspect the harness before the algorithm.

What does the identity $\log z = \log(s11) + \log(s10)$ tell you? ::: Which series was actually decomposed. If it holds against the raw data, no preadjustment happened; if not, regARIMA removed something first. That is how you audit a black box.

Method difference vs implementation precision ::: On AirPassengers, SEATS vs X-11 differ by 0.76% while our implementation differs from X-13's by 0.001% — a factor of ~660. **Which method you publish matters far more than decimal-place agreement.**
