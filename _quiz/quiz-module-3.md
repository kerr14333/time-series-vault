---
aliases: [Quiz Module 3]
tags: [quiz, module-3]
---

# Quiz — Module 3 (Spectra and signal extraction)

#flashcards/module-3

This is the module that decides whether SEATS makes sense to you. Drill it harder than the other two.

---

## Frequencies

Two units for frequency, and how to tell them apart ::: Radians per period $\omega \in [0,\pi]$, or cycles per period $f \in [0,0.5]$, with $\omega = 2\pi f$. The axis maximum gives it away: $\pi \approx 3.14$ versus $0.5$.

The six seasonal frequencies for monthly data ::: $f = k/12$ for $k=1..6$: periods 12, 6, 4, 3, 2.4 and 2 months. Plus $f=0$, the trend.

What is the Nyquist frequency and why does the axis stop there? ::: $\omega=\pi$, period 2 — the fastest observable cycle. Anything faster is **aliased**: sampled monthly, it is indistinguishable from a slower cycle.

Why does seasonality occupy six frequencies rather than one? ::: A seasonal pattern is any repeating period-12 shape, not necessarily a sine. Fourier decomposes an arbitrary period-12 shape into a fundamental plus harmonics at periods 6, 4, 3, 2.4 and 2. A sharp December spike needs the high harmonics; a smooth season barely uses them.

Where does SEATS's $\theta(B)\theta(F)$ pairing come from? ::: It is a squared modulus. $|\theta(e^{-i\omega})|^2 = \theta(e^{-i\omega})\theta(e^{i\omega})$, and $e^{i\omega}$ is $F$. Nothing more exotic than $|w|^2 = w\bar w$.

## The spectral density

Definition of the spectral density ::: $f(\omega) = \frac{1}{2\pi}\sum_k \gamma_k e^{-i\omega k}$ — the Fourier transform of the autocovariance function. Invertible, so $f$ and $\{\gamma_k\}$ carry identical information.

The interpretation that matters ::: The area under $f$ over a band of frequencies is the amount of the series' **variance** contributed by cycles in that band. In particular $\int f = \gamma_0 = \mathrm{Var}(z_t)$.

Spectrum of white noise ::: Flat, $f(\omega) = \sigma_a^2/2\pi$ — every frequency contributes equally. Hence "white".

Which spectral property makes decomposition possible? ::: **Additivity over independent components**: if $z = s+n$ with $s\perp n$ then $f_z = f_s + f_n$. Decomposition is hard in the time domain and is plain addition in the frequency domain.

Why must a spectrum be non-negative, and where does that bite? ::: A negative "spectrum" is not a spectrum. This is exactly the **admissibility** constraint that stops some ARIMA models from admitting a decomposition in SEATS.

What is wrong with the raw periodogram? ::: It is **not consistent** — its variance does not shrink as $n$ grows. More data gives more frequencies, not a better estimate at each one. Fix by smoothing (Daniell spans), tapering, or fitting a model and using its theoretical spectrum.

Why plot spectra on a log scale? ::: Trend power near $\omega=0$ is orders of magnitude above everything else and flattens the rest of the plot into the floor on a linear axis.

## The ARMA spectrum

The central formula ::: $f(\omega) = \dfrac{\sigma_a^2}{2\pi}\cdot\dfrac{|\theta(e^{-i\omega})|^2}{|\phi(e^{-i\omega})|^2}$.

Where the formula comes from ::: White noise has a flat spectrum, and filtering multiplies the spectrum by the squared gain. An ARMA is white noise passed through $\theta(B)/\phi(B)$. Two facts, one line.

AR roots versus MA roots, spectrally ::: AR (denominator) roots near the unit circle give **peaks**; MA (numerator) roots near it give **troughs**, and an exact **zero** if the root is on the circle. Closer to the circle = sharper feature.

What does $(1-B^{12})$ look like as a filter? ::: Twelve roots on the unit circle, so zeros at all six seasonal frequencies **and** at frequency 0. Seasonal differencing is a filter whose gain is zero exactly where the seasonal lives.

Why does "rational" matter so much? ::: A ratio of polynomials submits to **partial fractions** — split the denominator $\phi$ into $\phi_T\phi_S$ and the spectrum splits into $f_T + f_S + f_I$. That is the SEATS decomposition.

## Pseudo-spectrum

What is a pseudo-spectrum? ::: The ARMA spectral formula applied to a model with unit roots. The denominator vanishes at those frequencies, so the expression diverges — well defined everywhere except finitely many points, where it is $+\infty$.

Why are the infinities a feature rather than a defect? ::: They mark exactly where the components live: a pole at $\omega=0$ is the trend, poles at $2\pi k/12$ are the seasonal. Sorting the roots into those bins is step 1 of SEATS.

The airline model's pseudo-spectrum ::: A **double** pole at $\omega=0$ (from $(1-B)^2$), six poles at the seasonal frequencies (from $S(B)$), and a finite floor in between — the irregular.

What controls the WIDTH of the seasonal peaks? ::: $\Theta$. Close to 1 puts a numerator near-zero beside each pole, making the peaks narrow — a stable, sharply defined seasonal. Small $\Theta$ leaves them broad, i.e. seasonality that wanders.

Why do the infinities not break the filter? ::: The WK filter is a **ratio** $f_s/f_z$. At a seasonal frequency both are infinite and the ratio tends to 1 — the seasonal owns all the power there. Ratios of infinities behave even when the pieces do not.

## Filters

The filtering theorem ::: If $y = \nu(B)x$ then $f_y(\omega) = |\nu(e^{-i\omega})|^2 f_x(\omega)$. Filtering rescales each frequency independently; it never mixes them.

Gain of $(1-B)$ ::: $2|\sin(\omega/2)|$ — zero at $\omega=0$, rising to **2** at $\omega=\pi$. Differencing kills the trend *and amplifies the high frequencies*, which is why over-differenced series look noisier.

Gain of $(1-B^{12})$ ::: $2|\sin(6\omega)|$ — seven zeros, at frequency 0 and the six seasonal frequencies.

Why is a symmetric filter non-negotiable in the interior? ::: Its transfer function is real, so phase is zero and nothing shifts in time. An asymmetric filter shifts different cycles by different amounts, so turning points move.

The ideal SA filter, and why it cannot exist ::: Gain 0 exactly at the six seasonal frequencies, 1 everywhere else. A discontinuous gain needs infinitely many weights — and it is the wrong target anyway, because evolving seasonality smears power into *bands* around those frequencies. Every real filter trades off notch depth, notch width, and collateral damage.

In one sentence, the difference between X-11 and SEATS ::: They resolve the same notch-shape trade-off differently — X-11 with a fixed empirical recipe, SEATS with a model fitted to the series.

## Wiener–Kolmogorov

The WK filter ::: $\nu_s(\omega) = f_s(\omega)/f_z(\omega)$ — at each frequency, keep the share of the power belonging to the component.

Why is that obviously the right answer? ::: Filtering acts on each frequency independently, so the problem separates into one signal-to-noise shrinkage problem per frequency, with answer $f_s/(f_s+f_n)$.

What does $\nu_s + \nu_n = 1$ guarantee? ::: The component estimates add back to the observed series **exactly**. The decomposition is additive by construction.

The WK filter in model terms ::: $\nu_s(B,F) = \dfrac{\sigma_s^2}{\sigma_a^2}\cdot\dfrac{\theta_s(B)\theta_s(F)\,\phi_n(B)\phi_n(F)}{\theta(B)\theta(F)}$.

Why does the trend filter contain the *seasonal's* AR polynomial? ::: Its job is to reject the seasonal, so it inherits the seasonal's denominator as numerator zeros — placing exact zeros at the seasonal frequencies.

Three properties of the WK filter ::: Symmetric (zero phase); doubly infinite (uses all past and all future); convergent, with weights decaying at a rate set by how close $\theta$'s roots are to the unit circle.

Why do narrow notches force long filters? ::: A sharp feature in the frequency domain requires a wide window in the time domain. $\Theta$ near 1 narrows the seasonal peaks *and* slows the weight decay. It is the uncertainty principle, in seasonal adjustment.

Why is the decomposition not identified by the data? ::: You can only ever fit $f_z$, and infinitely many pairs $(f_s,f_n)$ sum to the same $f_z$ — shift white noise between them and nothing observable changes. Splitting requires an assumption beyond the fitted model.

Two ways to resolve the non-identification ::: Structural modelling (specify and fit the components directly), or the **canonical decomposition** (fit the observed series, then split by a stated convention — maximise the irregular's variance). SEATS takes the second.

## Finite samples

Three ways to apply an infinite filter to finite data ::: Truncate the weights; forecast-extend and then filter symmetrically; or Burman's algorithm, which computes the exact finite-sample answer directly. The last two agree.

Why is forecast extension exactly right, not an approximation? ::: For a linear filter applied to a series extended by minimum-MSE forecasts, the result *is* the minimum-MSE estimate of the filtered value given the data. Forecasting and filtering commute appropriately.

What goes wrong if you truncate and renormalise? ::: Renormalising forces the weights to sum to 1 but distorts the gain, most visibly at low frequencies where the filter should pass everything.

The revision problem, derived three ways ::: (1) the filter needs future values that do not exist; (2) the end filter differs structurally from the interior filter; (3) the WK filter is doubly infinite and must be completed with forecasts. One phenomenon, three languages.

Four checks when implementing a decomposition ::: Weights sum to 1; the interior filter is symmetric; the components add back to the input exactly; and the interior agrees with SEATS even if the ends do not.
