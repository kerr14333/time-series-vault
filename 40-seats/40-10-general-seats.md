---
aliases: [General SEATS, Transitory component, Root sorting, Arbitrary ARIMA]
tags: [module-4, key]
---

# SEATS for an arbitrary model, and the fourth component

Code: [[code-40-10-general-seats|`R/40-10-general-seats.R`]], built on [[code-_seats_general|`R/_seats_general.R`]]

Everything in Module 4 so far assumed the airline model. That is not a small assumption — it is *why* [[40-01-unobserved-components-and-reduced-form]] could state the AR split in advance:

$$(1-B)(1-B^{12}) = \underbrace{(1-B)^2}_{\text{trend}} \cdot \underbrace{S(B)}_{\text{seasonal}}$$

For a general $(p,d,q)(P,D,Q)_s$ there is no such formula. The split has to be **discovered**.

## Sort the roots by frequency and modulus

Build the full AR polynomial $\phi(B)\Phi(B^s)(1-B)^d(1-B^s)^D$, find every root, and ask two questions about each one: what *frequency* it sits at, and how *persistent* it is. A root $z$ has frequency $\omega = |\arg z|$; its persistence is the modulus of the inverse root, $1/|z|$, which is at most 1 for a stationary root and close to 1 for one that dies out slowly.

X-13's rule, with its own default constants:

| Root | Component |
|---|---|
| real positive, $1/\lvert z\rvert \ge 0.5$ | **trend** |
| real negative, $1/\lvert z\rvert \ge 0.5$ | **seasonal** (frequency $\pi$) |
| complex pair, $1/\lvert z\rvert > 0.5$, within $360/2s = 15°$ of zero | **trend** |
| complex pair, $1/\lvert z\rvert \ge 0.5$, within $2°$ of a multiple of $360/s$ | **seasonal** |
| anything else | **transitory** |

Three things in that table are worth pausing on.

**Modulus is a gate, not decoration.** A root deep inside the unit circle dies out in a few months. Calling it seasonal because its angle happens to land near $2\pi k/s$ puts a short transient into the seasonal factors, where it will be subtracted from every future year. The cutoff `rmod` is $0.5$.

**A complex pair within $15°$ of zero is trend, not transitory.** For monthly data that means *any cycle of 24 months or longer*. This is deliberate and it is why the component is called the trend-**cycle**: a business cycle belongs in it. [[40-11-validating-general-seats]] checks that boundary against X-13 at eight root positions.

**The seasonal window is $2°$, not half the $30°$ gap.** Seasonal unit roots sit exactly on those frequencies, so a tight window costs nothing, and a wide one swallows cycles that are merely nearby.

The last row is what is new. The airline model cannot produce it — all its AR roots are unit roots at frequency 0 or at the seasonal frequencies — but a general model can, and then you have a **fourth component**.

`R/_seats_general.R` implements this, along with an $N$-way partial fraction, an $N$-component canonical adjustment, and the corresponding filters. `_seats.R` is untouched: it is validated to 0.001% and half the vault depends on it.

## First, does it reproduce the special case?

A generalisation that breaks the case you already trust is worthless, so this is the first check, not the last:

<!-- run -->
```r
source("R/_seats_general.R")
sp <- seats_ar_split_general(d = 1, D = 1, s = 12)
old <- seats_ar_split(1, 1, 12)
cat("trend    :", poly_show(sp$trend), "\n")
cat("seasonal :", poly_show(sp$seasonal), "\n")
cat("transitory roots:", sum(sp$table$component == "transitory"), "\n")
cat(sprintf("difference from the hard-coded split: trend %.2e  seasonal %.2e\n",
            max(abs(sp$trend - old$trend)), max(abs(sp$seasonal - old$seasonal))))
```
```text
trend    : 1 - 2B + B^2 
seasonal : 1 + B + B^2 + B^3 + B^4 + B^5 + B^6 + B^7 + B^8 + B^9 + B^10 + B^11 
transitory roots: 0 
difference from the hard-coded split: trend 2.62e-14  seasonal 9.84e-14
```
<!-- end -->

Thirteen roots, sorted correctly with no human input: two at frequency zero, eleven at the six seasonal frequencies, none left over. The seasonal polynomial matches exactly.

> [!warning] The repeated root, and how not to pay for it
> $(1-B)^2$ has a **double** root at $B=1$, and `polyroot` cannot return it as one root. It returns a cluster of two, about $10^{-7}$ apart, with small imaginary parts of opposite sign — root-finding at a repeated root loses roughly half the available precision, $\sqrt{\varepsilon}$ rather than $\varepsilon$.
>
> Rebuilding the quadratic factor from the **mean** of the conjugate pair cancels that error instead of propagating it. Using either member alone leaves $2\times10^{-8}$ in the trend polynomial; averaging brings it to $3\times10^{-14}$. **Generality has a numerical price and this is where it is paid** — but most of the bill is avoidable, and it took comparing against X-13 to notice it was being paid at all.

Running the whole decomposition rather than just the split:

<!-- run -->
```r
g <- seats_decompose_general(AirPassengers, ma = 0.4018, sma = 0.5569,
                             d = 1, D = 1, s = 12, max_lag = 340, extend = 360)
r <- seats_decompose(AirPassengers, 0.4018, 0.5569)
for (k in c("trend", "seasonal"))
  cat(sprintf("%-9s max |general - _seats.R| = %.8f\n",
              k, max(abs(as.numeric(g[[k]]) - as.numeric(r[[k]])))))
cat(sprintf("partial-fraction residual %.2e   admissible %s\n", g$residual, g$admissible))
```
```text
trend     max |general - _seats.R| = 0.00001279
seasonal  max |general - _seats.R| = 0.00000007
partial-fraction residual 6.84e-14   admissible TRUE
```
<!-- end -->

## The fourth component, on a model that has one

Two AR(2) pairs, same modulus, different periods. Predict where each goes before reading the output:

<!-- run -->
```r
where <- function(per, rB) {
  wc <- 2 * pi / per
  sp <- seats_ar_split_general(ar = c(2 * cos(wc) / rB, -1 / rB^2), d = 1, D = 1, s = 12)
  row <- sp$table[abs(sp$table$modulus - rB) < 1e-6, ][1, ]
  cat(sprintf("period %2d months, %5.2f degrees -> %s\n", per, 360 / per, row$component))
  invisible(sp)
}
spT <- where(40, 1.05)
spC <- where(20, 1.05)
where(9, 1.50)
```
```text
period 40 months,  9.00 degrees -> trend
period 20 months, 18.00 degrees -> transitory
period  9 months, 40.00 degrees -> transitory
```
<!-- end -->

<!-- run -->
```r
cat("40-month trend  :", poly_show(spT$trend), "\n")
cat("20-month trend  :", poly_show(spC$trend), "\n")
cat("20-month transit:", poly_show(spC$transitory), "\n")
```
```text
40-month trend  : 1 - 3.881311B + 5.669652B^2 - 3.69537B^3 + 0.9070295B^4 
20-month trend  : 1 - 2B + B^2 
20-month transit: 1 - 1.811536B + 0.9070295B^2 
```
<!-- end -->

The 40-month pair is **absorbed into the trend**, whose polynomial is now degree 4 rather than $(1-B)^2$. The 20-month pair is isolated into its own component and the trend comes back as exactly $(1-B)^2$.

> [!important] The boundary is two years, and it is not a matter of taste
> A first version of this vault presented the 40-month case as the showcase transitory component and said `_seats.R` would wrongly fold it into the trend. X-13 folds it into the trend too — deliberately, because a complex pair within $15°$ of frequency zero is what a **trend-cycle** component is for. The claim was written from an unchecked assumption about TRAMO-SEATS and survived until the code was compared against Census output.
>
> What the fourth component is actually for is the movement that is too fast to be trend and not at a seasonal frequency: a 20-month cycle, a 9-month cycle, or a root too far inside the unit circle to be either. That is a narrower and less romantic claim than "it keeps the business cycle out of your trend", and it is the true one.

## What happens on real series

<!-- run -->
```r
source("R/40-10-general-seats.R")
```
```text
=== 1. the general code must reproduce the special case ===
  trend    : 1 - 2B + B^2 
  seasonal : 1 + B + B^2 + B^3 + B^4 + B^5 + B^6 + B^7 + B^8 + B^9 + B^10 + B^11 
  transitory: none (correct -- an airline model has no cyclical roots)
  max difference from the hard-coded split: trend 2.62e-14  seasonal 9.84e-14
  (1-B)^2 has a DOUBLE root at B = 1, and polyroot cannot return it as
  one root: it returns a cluster of two, about 1e-7 apart, with small
  imaginary parts of opposite sign. Rebuilding the factor from the MEAN
  of the conjugate pair cancels that error instead of propagating it,
  which is why the gap here is 1e-14 rather than the 1e-8 you get from
  using either member alone. Generality has a numerical price, and this
  is how you avoid paying it.

=== 2. full decomposition vs the validated airline implementation ===
  trend     max |general - _seats.R| = 0.00001279
  seasonal  max |general - _seats.R| = 0.00000007
  partial-fraction residual 6.84e-14   admissible TRUE

=== 3. two cycles, two different answers ===
  period 40 months, 1/|B| = 0.952,  9.00 deg  ->  trend      (X-13: trend)
  period 20 months, 1/|B| = 0.952, 18.00 deg  ->  transitory (X-13: transitory)
  period  9 months, 1/|B| = 0.667, 40.00 deg  ->  transitory (X-13: transitory)

  The 40-month cycle joins the TREND, and that is correct: X-13 sends
... [41 more lines]
```
<!-- end -->

Two findings worth separating.

**`cpi` comes back inadmissible.** [[40-02-admissible-decompositions]] found that with the airline machinery on a fitted airline model; this reaches it with different code, a different model $(2,1,2)(1,0,1)$, an $N$-way partial fraction and an $N$-component canonical step. Two independent implementations agreeing on the awkward case is worth more than either alone.

**`cpi` and `ukgas` do produce a transitory component; `unemp` does not.** An earlier version of this note reported that *no* catalogue series produced one and presented that as an honest negative result. It was an artifact: the classification rule had no modulus gate and a $15°$ seasonal window, so short-lived roots were swept into the seasonal component where they silently distorted the factors. Under X-13's actual rule the fourth component is uncommon but not rare — and `imp`, fitted as $(2,1,0)(0,1,1)$, gets one that X-13 agrees with to $10^{-6}$. See [[40-11-validating-general-seats]].

The lesson is the one that keeps recurring in this vault: a negative result from code you have not checked against an independent implementation is not evidence of anything. It reads as rigour and it is the opposite.

## A detail that is easy to get wrong

> [!tip] $(1 - \Phi B^{12})$ is not a purely seasonal operator
> Its twelve roots are spread around the circle at the seasonal frequencies **and at frequency zero**. That zero-frequency root belongs to the **trend**.
>
> Sorting by frequency gets this right without being told. Sorting by *which factor a root came from* — the intuitive approach — would put all twelve in the seasonal and quietly move a trend root into your seasonal component.

<!-- run -->
```r
spS <- seats_ar_split_general(sar = 0.8, d = 0, D = 0, s = 12)
table(spS$table$component)
```
```text

seasonal    trend 
      11        1 
```
<!-- end -->

## What is still missing

Being explicit, so nothing here is oversold:

1. **The classification constants are X-13's, not universal.** `rmod = 0.5` and `epsphi = 2°` are the defaults of one program, exposed here as arguments because they are conventions rather than theorems. What is *not* a choice is that both tests exist: drop either and you are not doing what SEATS does.
2. **Precision is lower than the hard-coded route**, for the repeated-root reason above — though much less so since the conjugate-pair averaging.
3. **One boundary case disagrees with X-13**: a cycle of exactly $2s$ periods sits exactly on the trend cutoff, and the two programs round to opposite sides. [[40-11-validating-general-seats]] shows the arithmetic rather than papering over it.
4. **Only the multiplicative case is exercised.** Everything here logs the series first; an additive general decomposition is untested.

## Exercises

*Solutions: [[solutions#40-10-general-seats|worked answers]] in the solutions appendix.*

1. Confirm the general split reproduces the airline split, and measure the difference. Explain why it is not zero.
2. Construct AR(2) roots at a 6-month period instead of 40. Where do they get classified, and is that right?
3. Vary `epsphi` from 1 to 15 degrees on a model whose roots sit near a seasonal frequency. At what point does the classification flip, and which value matches X-13?
4. Take `unemp`'s fitted model and check every root's classification by hand against the table.
5. Build a model with **two** transitory pairs at different frequencies. Does the partial fraction still solve cleanly?
6. Decompose a series with a genuine business cycle (try `sunspots` with an appropriate model). Predict which component the cycle lands in *from its period* before you run it.
7. Compare the general decomposition of `AirPassengers` with X-13's `s10` directly. How much of the remaining gap is the repeated-root problem?
8. Set `rmod = 0` and re-classify `imp`'s fitted $(2,1,0)(0,1,1)$. Where does the AR(2) go, and what does the seasonal component now contain that it should not?

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** Where will the roots of $(1 - 0.9B^{12})$ be classified? All seasonal? Predict, then check — the answer surprises most people.
2. **Break it.** Set `epsphi = 15` (the old, wrong window) and re-classify `imp`'s fitted model. Where does the AR(2) pair go, and what have you silently published?
3. **Transfer.** Fit a model with two distinct cyclical pairs and confirm both land in the transitory component.

## Practice set

*Drills, output-reading and judgement calls. Short answers; the point is fluency and knowing what you are looking at.*

1. **Drill.** Run the root classification for three fitted catalogue models and tabulate the counts.
2. **Drill.** Report the split for $(1-\Phi B^{12})$ alone and explain the trend root.
3. **Read it.** A root sits at modulus 1.00 and frequency 0.5236. Which component, and what period?

## Links

- Prev: [[40-09-burman-algorithm]] · Next: [[40-11-validating-general-seats]] · Module map: [[40-00-seats-map]]
- Builds on: [[40-01-unobserved-components-and-reduced-form]], [[40-03-canonical-decomposition]], [[40-02-admissible-decompositions]]
- Algebra: [[derivations#D9. The canonical decomposition, and why it is a convention|D9]], [[derivations#D4. The seasonal difference contains the trend difference|D4]]
