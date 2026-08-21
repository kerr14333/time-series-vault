---
aliases: [General SEATS, Transitory component, Root sorting, Arbitrary ARIMA]
tags: [module-4, key]
---

# SEATS for an arbitrary model, and the fourth component

Code: [[code-40-10-general-seats|`R/40-10-general-seats.R`]], built on [[code-_seats_general|`R/_seats_general.R`]]

Everything in Module 4 so far assumed the airline model. That is not a small assumption — it is *why* [[40-01-unobserved-components-and-reduced-form]] could state the AR split in advance:

$$(1-B)(1-B^{12}) = \underbrace{(1-B)^2}_{\text{trend}} \cdot \underbrace{S(B)}_{\text{seasonal}}$$

For a general $(p,d,q)(P,D,Q)_s$ there is no such formula. The split has to be **discovered**.

## Sort the roots by frequency

Build the full AR polynomial $\phi(B)\Phi(B^s)(1-B)^d(1-B^s)^D$, find every root, and ask what *frequency* each one sits at. A root $z$ has frequency $\omega = |\arg z|$, so:

| Root frequency | Component |
|---|---|
| $\omega \approx 0$ | **trend** |
| $\omega \approx 2\pi k/s$ | **seasonal** |
| anything else | **transitory** |

That third row is new. The airline model cannot produce it — all its AR roots are unit roots at frequency 0 or at the seasonal frequencies — but a general model can, and then you have a **fourth component**.

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
trend    : 1 - 2B + 1B^2 
seasonal : 1 + B + B^2 + B^3 + B^4 + B^5 + B^6 + B^7 + B^8 + B^9 + B^10 + B^11 
transitory roots: 0 
difference from the hard-coded split: trend 2.07e-08  seasonal 2.29e-14
```
<!-- end -->

Thirteen roots, sorted correctly with no human input: two at frequency zero, eleven at the six seasonal frequencies, none left over. The seasonal polynomial matches exactly.

> [!warning] The trend differs by $2\times10^{-8}$, and that is not a bug
> $(1-B)^2$ has a **double** root at $B=1$, and root-finding at a repeated root loses roughly half the available precision — you get $\sqrt{\varepsilon}$, not $\varepsilon$. The hard-coded version knows the answer algebraically and is exact; the general version has to find it numerically and cannot be.
>
> **Generality has a numerical price**, and this is where it is paid. It propagates: the full decomposition below matches the validated implementation to $1.3\times10^{-5}$ in the trend, against $3\times10^{-6}$ for the hard-coded route against X-13. Fine for understanding, and a reason to keep the special case for production.

Running the whole decomposition rather than just the split:

<!-- run -->
```r
g <- seats_decompose_general(AirPassengers, ma = 0.4018, sma = 0.5569,
                             d = 1, D = 1, s = 12, max_lag = 340, extend = 360)
r <- seats_decompose(AirPassengers, 0.4018, 0.5569, normalize = FALSE)
for (k in c("trend", "seasonal"))
  cat(sprintf("%-9s max |general - _seats.R| = %.8f\n",
              k, max(abs(as.numeric(g[[k]]) - as.numeric(r[[k]])))))
cat(sprintf("partial-fraction residual %.2e   admissible %s\n", g$residual, g$admissible))
```
```text
trend     max |general - _seats.R| = 0.00001275
seasonal  max |general - _seats.R| = 0.00000011
partial-fraction residual 7.22e-14   admissible TRUE
```
<!-- end -->

## The fourth component, on a model that has one

Take an AR(2) with a complex root pair at a 40-month cycle — too slow to be seasonal, too fast to be trend:

<!-- run -->
```r
per <- 40; rmod <- 1.05; wc <- 2 * pi / per
spT <- seats_ar_split_general(ar = c(2 * cos(wc) / rmod, -1 / rmod^2),
                              d = 1, D = 1, s = 12)
head(spT$table[order(spT$table$freq_rad), ], 4)
```
```text
   modulus freq_rad    period  component
1     1.00   0.0000 521942205      trend
14    1.00   0.0000 521946831      trend
11    1.05   0.1571        40 transitory
15    1.05   0.1571        40 transitory
```
<!-- end -->

<!-- run -->
```r
cat("trend      :", poly_show(spT$trend), "\n")
cat("transitory :", poly_show(spT$transitory), "\n")
```
```text
trend      : 1 - 2B + 1B^2 
transitory : 1 - 1.881311B + 0.9070295B^2 
```
<!-- end -->

The cyclical pair is isolated into its own component, and the trend comes back as exactly $(1-B)^2$.

> [!important] Why this matters practically
> `_seats.R` would have folded that pair into the trend, because its rule is "stationary AR goes to the trend side". You would then publish a trend containing a **three-year business cycle**, and readers interpret the trend as "the underlying level". A transitory component is how you say *this movement is real, persistent enough to model, and not the trend*.

## What happens on real series

<!-- run -->
```r
source("R/40-10-general-seats.R")
```
```text
=== 1. the general code must reproduce the special case ===
  trend    : 1 - 2B + 1B^2 
  seasonal : 1 + B + B^2 + B^3 + B^4 + B^5 + B^6 + B^7 + B^8 + B^9 + B^10 + B^11 
  transitory: none (correct -- an airline model has no cyclical roots)
  max difference from the hard-coded split: trend 2.07e-08  seasonal 2.29e-14
  The trend gap is 2e-8, not 0, and that is worth understanding: (1-B)^2
  has a DOUBLE root at B = 1, and root-finding at a repeated root loses
  about half the available precision. Generality has a numerical price.

=== 2. full decomposition vs the validated airline implementation ===
  trend     max |general - _seats.R| = 0.00001275
  seasonal  max |general - _seats.R| = 0.00000011
  partial-fraction residual 7.22e-14   admissible TRUE

=== 3. a TRANSITORY component: the thing the airline model cannot have ===
  AR(2) with complex roots at period 40 months, modulus 1.05
 modulus freq_rad    period  component
    1.00   0.0000 521942205      trend
    1.00   0.0000 521946831      trend
    1.05   0.1571        40 transitory
    1.05   0.1571        40 transitory
    1.00   0.5236        12   seasonal
  ...
  trend      : 1 - 2B + 1B^2 
... [27 more lines]
```
<!-- end -->

Two findings worth separating.

**`cpi` comes back inadmissible.** [[40-02-admissible-decompositions]] found that with the airline machinery on a fitted airline model; this reaches it with different code, a different model $(2,1,2)(1,0,1)$, an $N$-way partial fraction and an $N$-component canonical step. Two independent implementations agreeing on the awkward case is worth more than either alone.

**No real catalogue series produces a transitory component.** Every AR root in `unemp`, `cpi` and `ukgas` landed at frequency zero or at a seasonal frequency. The fourth component is real, demonstrable and — on this evidence — **rare**. That is an honest negative result, not a failure of the code: economic series that need a distinct cyclical component are the exception, which is why the airline model survives as a default.

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

1. **The classification tolerances are choices.** `tol_trend = 1e-3` radians and half the inter-seasonal gap are defensible, not canonical. A first version used the wide tolerance for the trend too, which classified *any cycle longer than 24 months* as trend — the transitory component then essentially never fired, defeating the exercise. TRAMO-SEATS assigns only frequency-zero roots to the trend, which is what this does now.
2. **No comparison against X-13's own general decomposition.** The airline case is validated against the binary; the general case is validated for *internal* consistency (identity exact, residual $10^{-12}$, admissibility agreeing with 40-02) but not against Census output for a non-airline model.
3. **Precision is lower**, for the repeated-root reason above.
4. **Transitory components are untested on real data**, because no catalogue series produces one.

## Exercises

*Solutions: [[solutions#40-10-general-seats|worked answers]] in the solutions appendix.*

1. Confirm the general split reproduces the airline split, and measure the difference. Explain why it is not zero.
2. Construct AR(2) roots at a 6-month period instead of 40. Where do they get classified, and is that right?
3. Vary `tol_frac` from 0.2 to 0.9 on a model whose roots sit near a seasonal frequency. At what point does the classification flip?
4. Take `unemp`'s fitted model and check every root's classification by hand against the table.
5. Build a model with **two** transitory pairs at different frequencies. Does the partial fraction still solve cleanly?
6. Decompose a series with a genuine business cycle (try `sunspots` with an appropriate model) and see whether the cycle lands in the transitory component.
7. Compare the general decomposition of `AirPassengers` with X-13's `s10` directly. How much of the $1.3\times10^{-5}$ gap is the repeated-root problem?

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** Where will the roots of $(1 - 0.9B^{12})$ be classified? All seasonal? Predict, then check — the answer surprises most people.
2. **Break it.** Set `tol_trend` to 0.3 and re-run the 40-month example. Where does the cyclical pair go now, and what have you silently published?
3. **Transfer.** Fit a model with two distinct cyclical pairs and confirm both land in the transitory component.

## Links

- Prev: [[40-09-burman-algorithm]] · Module map: [[40-00-seats-map]]
- Builds on: [[40-01-unobserved-components-and-reduced-form]], [[40-03-canonical-decomposition]], [[40-02-admissible-decompositions]]
- Algebra: [[derivations#D9. The canonical decomposition, and why it is a convention|D9]], [[derivations#D4. The seasonal difference contains the trend difference|D4]]
