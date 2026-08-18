---
aliases: [Quiz Module 2]
tags: [quiz, module-2]
---

# Quiz — Module 2 (X-11)

#flashcards/module-2

Same two modes as [[quiz-module-1]]: drill the cards offline with the Spaced Repetition plugin, or say *"quiz me on module 2"* for an adaptive session in chat.

---

## Filters

What is the useful reframe of "a moving average"? ::: A **linear filter** — it multiplies each frequency by a fixed amount. Choosing a moving average is choosing which frequencies to keep and which to destroy.

Gain and phase, defined ::: Substitute $B = e^{-i\omega}$ into the filter polynomial. Gain $G(\omega) = |\nu(e^{-i\omega})|$ is how much a cycle of that frequency is scaled; phase is how far it is shifted in time.

Why must interior filters be symmetric? ::: Symmetry makes the transfer function real, so the phase shift is zero. A filter with nonzero phase would **move turning points in time** — a recession would appear to start in a different month than it did.

What does $\sum_j w_j = 1$ guarantee? ::: $G(0) = 1$ — the filter preserves the level. Every trend filter in X-11 has weights summing to 1.

How do you analyse a whole iteration of moving averages? ::: Compose them: applying $\nu_1$ then $\nu_2$ gives $\nu_2(B)\nu_1(B)$, so the gains multiply. The whole of X-11 collapses into one filter.

Trend filter vs seasonal-adjustment filter — where do they differ? ::: At high frequencies. Both pass frequency 0 and kill the seasonal frequencies, but a trend filter kills the high frequencies too, while an SA filter passes them — the irregular stays in a seasonally adjusted series.

## The 2×12 MA

Write down the centred 12-term MA ::: $\tfrac{1}{24}(1,2,2,2,2,2,2,2,2,2,2,2,1)$ — thirteen weights, summing to 1.

Where does the 1,2,…,2,1 shape come from? ::: It is $\tfrac12(1+B)$ times $\tfrac1{12}(1+B+\cdots+B^{11})$ — a 2-term MA of a 12-term MA. The interior terms get hit twice, the two ends once.

Why average two 12-term MAs instead of using one? ::: An even-length MA is centred *between* two months. Averaging two consecutive ones recentres it on a month, restoring symmetry and hence zero phase.

What is the 2×12 MA's gain at the seasonal frequencies? ::: Exactly zero — of order $10^{-16}$ when measured. A 12-term average of a period-12 pattern averages one whole cycle, which is its mean.

Same polynomial, three roles ::: $S(B) = 1+B+\cdots+B^{11}$ is the seasonal half of $(1-B^{12})$ in differencing, the filter that kills seasonality in X-11, and the AR denominator assigned to the seasonal component in SEATS.

Three things the 2×12 MA gets wrong ::: It damages genuine trend curvature; its side lobes leak high-frequency noise back in with a sign flip; and it costs six observations at each end.

## Henderson

What does the Henderson filter optimise? ::: Among all symmetric filters of a given length that reproduce a **cubic exactly**, it is the one minimising the sum of squared third differences of the weights — i.e. the smoothest.

Why does Henderson have negative weights at the ends? ::: They let the filter follow curvature rather than flattening it. The consequence is that a Henderson trend can occasionally overshoot beyond the range of the data.

What is the gain of a 13-term Henderson at the annual frequency? ::: About **0.85** — an annual cycle passes almost untouched. Henderson is a low-pass filter and removing seasonality is not its job.

Why does the 2×12 MA have to run before Henderson? ::: Because Henderson barely attenuates the annual frequency. Apply it to raw seasonal data and most of the annual swing lands in your "trend". Seasonal first, Henderson second.

How is the Henderson length chosen? ::: From the I/C ratio — average absolute month-to-month change in the irregular over that of the trend-cycle. Below 1.0 gives 9 terms, 1.0–3.5 gives 13, above 3.5 gives 23. Noisier series get longer filters.

Trap when computing the I/C ratio in a multiplicative decomposition ::: The irregular is a ratio around 1 while the trend is on the level scale. Compare **percent** changes for both. Mixing the scales gives a tiny ratio and always selects the shortest filter.

## Seasonal filters

What direction does the seasonal filter run in? ::: **Across years, within a calendar month.** All the Januaries form one series and get smoothed; then all the Februaries. It is a polynomial in $B^{12}$, not in $B$.

Weights of the 3×3, 3×5 and 3×9 ::: $\tfrac19(1,2,3,2,1)$, $\tfrac1{15}(1,2,3,3,3,2,1)$, $\tfrac1{27}(1,2,3,3,3,3,3,3,3,2,1)$ — each a convolution of a 3-term MA with a 3-, 5- or 9-term MA.

What does the choice of seasonal filter length control? ::: How fast the seasonal pattern is allowed to evolve. Longer = steadier, slower to adapt. Exactly the trade-off $\Theta$ controls in the airline model.

Why centre the seasonal factors? ::: After smoothing they do not average to 1 within a year. Left alone that leaks a slow drift out of the seasonal and into the trend. X-11 divides them by a centred 12-term MA of themselves.

## The iteration

Why does X-11 have to iterate? ::: Every step needs an input it does not have yet — the seasonal needs a trend, the Henderson needs a de-seasonalised series, the filter lengths need a decomposition, the extreme-value weights need an irregular. The escape is to start crude and refine.

What are D10, D11, D12, D13? ::: Final seasonal factors, final seasonally adjusted series, final trend-cycle, final irregular. The B/C/D prefixes are just first/second/third pass.

D-tables vs S-tables ::: `D10`–`D13` are the X-11 outputs; SEATS writes `s10`–`s13` and `s16` for the same quantities. X-13 can produce both from one run.

How do you recover X-11's composite filter without doing the algebra? ::: The impulse-response trick — feed it a series that is flat except for a single spike. What comes out *is* the filter weights. Works on any implementation, including a black box.

What does X-11's composite SA filter look like in the frequency domain? ::: Gain near 1 almost everywhere, with six narrow notches at the seasonal frequencies. Its impulse response has negative weights at $\pm12$.

## Extreme values

Why does one outlier damage several years? ::: It enters the SI ratios for its calendar month, and the seasonal filter smooths across years *within* that month — so one bad January corrupts the seasonal factor for the Januaries around it.

X-11's sigma limits ::: Below $1.5\sigma$, full weight. Between $1.5\sigma$ and $2.5\sigma$, weight graduated linearly to zero. Above $2.5\sigma$, fully replaced.

Is a downweighted value removed from the published series? ::: No. The replacement is used only to **estimate the seasonal factors**. D11 is the original data divided by the final factors, so a genuine outlier stays visible.

regARIMA outlier detection vs sigma limits ::: regARIMA runs before decomposition, is model-based, gives a coefficient and a significance test, and distinguishes AO / LS / TC. Sigma limits are empirical, run during decomposition, and do none of that. Both are active in modern practice.

Why is X-11 not exactly a linear filter? ::: The extreme-value step is nonlinear. "The X-11 filter" always means the linear filter you get with that step disabled.

## End filters and revisions

Why can't the symmetric filter be used at the end of the sample? ::: It needs $m$ future observations and there are none. Whatever replaces it is asymmetric, so it has nonzero phase and shifts timing.

What do Musgrave's surrogate filters optimise? ::: The mean squared revision — the expected squared difference between the estimate now and what the symmetric filter will eventually give — under an assumed model for the series.

Why does adjustment fail *at* a turning point rather than before it? ::: Because it is the end filter, not the interior filter, that produces the recent estimates, and the end filter differs sharply from it. As data arrives each month is recomputed with a progressively less asymmetric filter — that convergence is the revision path.

The three mechanisms of turning-point failure ::: Forecast contamination (the extension extrapolates the old regime); asymmetric end-filter weights that do not average out; and the revision path converging to the symmetric-filter value.

Revision variance decay ::: About −50% after 1 year, −77% after 3, −88% after 5 (Maravall 1996).

What fraction of month-to-month movements in an SA series can be false signals? ::: About 40% (Maravall & Pierce 1983).

## X-11-ARIMA

What was Dagum's idea? ::: Fit an ARIMA, forecast a year ahead (and backcast), then apply the ordinary **symmetric** filters to the extended series — instead of using a special asymmetric filter at the ends.

Why does forecast extension beat Musgrave's filters? ::: Musgrave minimises revision under one assumed model for every series. Forecast extension uses a model fitted to the actual series, which knows its own seasonal persistence, trend behaviour, outliers and calendar effects.

Is forecast extension equivalent to an asymmetric filter? ::: Yes — applying a symmetric filter to model-based forecasts is algebraically the same as applying some implied asymmetric filter to the observed data. The question is only which one you get.

Why doesn't forecast extension fix turning points? ::: The model extrapolates the regime it has seen, so at a turn it is wrong in a systematic direction. A better model shrinks revisions in normal times; the information about the turn genuinely does not exist yet.

The trap when measuring whether a method reduces revisions ::: Comparing each method against **its own** later vintage measures self-consistency, not accuracy — a stably wrong method scores perfectly. Measure every method against one shared reference: the full-sample symmetric-filter value. On `AirPassengers` the wrong definition says extension is worthless (0.3%); the right one says it cuts revisions by 41%.

Lineage of the method ::: X-11 (1965, the filter iteration) → X-11-ARIMA (1980, Dagum, forecast extension) → X-12-ARIMA (1998, regARIMA and diagnostics) → X-13ARIMA-SEATS (2012, SEATS added alongside).
