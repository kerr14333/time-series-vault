---
aliases: [Validating general SEATS, Root sorting validation, rmod and epsphi]
tags: [module-4]
---

# Validating the general implementation against X-13

Code: [[code-40-11-validating-general-seats|`R/40-11-validating-general-seats.R`]]

[[40-08-validating-against-x13]] checks `_seats.R` against the Census binary on the airline model. That result says nothing about [[40-10-general-seats]], because the thing the general code does — decide which component each AR root belongs to — is exactly the thing the airline model never exercises. Every root in an airline model is a unit root sitting on a frequency the split already knows about.

So the general code went into the vault validated for *internal* consistency only: the decomposition identity held exactly, the partial-fraction residual was $10^{-13}$, and it independently reproduced 40-02's finding that `cpi` is inadmissible. All true, all reassuring, and none of it able to catch a wrong classification rule — because a wrong rule produces a perfectly self-consistent decomposition of the wrong thing.

It caught nothing. There were **seven** errors: three in the classification rule, one in the arithmetic underneath it, two normalisation conventions, and one structural. Not one of them broke the identity, and not one showed up in a plot. Together they were worth a factor of a thousand — the airline implementation in [[40-08-validating-against-x13]] inherited two of the fixes and went from 0.001% to 0.000003%.

## What X-13 will tell you, if you ask it properly

X-13 does not report the AR split in `udg()`. It **prints** it, under *FACTORIZATION OF THE TOTAL AUTOREGRESSIVE POLYNOMIAL*, as three separate polynomials:

```text
Autoregressive trend-cycle polynomial
PHIPT( 0)  1.0000
PHIPT( 1) -2.0000
PHIPT( 2)  1.0000

Autoregressive TRANSITORY polynomial
PHIC( 0)  1.0000
PHIC( 1)  0.6438
PHIC( 2)  0.2129
```

That is `imp` fitted as $(2,1,0)(0,1,1)$. The trend got $(1-B)^2$ and nothing else; the whole AR(2) went to the **transitory** component. Reading that printout is how the rest of this note gets its answers — parsing a program's output is inelegant, but the alternative is asserting the rule from the source code and never testing it, which is how the errors below got in.

> [!tip] Ask the program, not the manual
> The rule is also in the Census Fortran (`sigsub.f`), and reading it there is how the constants below were found. But source code tells you what the program is *supposed* to do; the printout tells you what it did. Reading `sigsub.f` gives you `rmod` and `epsphi`. It does not tell you that a root can sit exactly on a boundary and that your own arithmetic will decide which side — that only shows up when you compare the two outputs.

## Error 1: modulus was never tested

The rule that shipped sorted roots by **frequency alone**. X-13 tests frequency *and* persistence: a root may only enter the trend or the seasonal if the modulus of its inverse, $1/|z|$, reaches `rmod` $= 0.5$.

`imp`'s AR(2) pair sits at $134.2°$, which is $14°$ from the seasonal frequency at $120°$ — inside the old $15°$ window, so the old rule called it **seasonal**. Its inverse modulus is $0.4614$. It is a transient that decays by half every two and a half months, and the old code was putting it into the factor that gets subtracted from the same month of every future year.

## Error 2: the seasonal window was seven times too wide

The old window was half the gap between seasonal frequencies, $15°$. X-13's `epsphi` is $2°$. Seasonal unit roots sit *exactly* on $2\pi k/s$, so a tight window costs nothing and a wide one captures cycles that merely happen to be nearby.

## Error 3: the trend boundary was moved for the wrong reason

X-13 sends a complex pair within $360/2s = 15°$ of frequency zero to the **trend**. For monthly data that is any cycle of 24 months or longer.

An earlier version of `_seats_general.R` had exactly this rule, then narrowed it to frequency zero, with this comment:

> A first version used half the gap between seasonal frequencies for every class, which meant any cycle longer than 24 months was called "trend" — so the transitory component essentially never fired, defeating the point of the exercise. TRAMO-SEATS assigns only roots at frequency zero to the trend.

The first sentence is a correct description of X-13's behaviour. The second is an unchecked claim, and it is false. The rule was changed because its consequence was inconvenient for the example being written, and the justification was invented afterwards. That is a worse failure than the other two: those were misreadings, this was a correct rule discarded on a hunch.

## The boundary, measured

<!-- run -->
```r
source("R/40-11-validating-general-seats.R")
```
```text
=== 1. where does a cyclical AR pair go? ours vs X-13's own printout ===
  The rule under test: a complex pair joins the TREND if the inverse-root
  modulus exceeds rmod = 0.5 and the frequency is within 360/(2s) = 15
  degrees of zero; joins the SEASONAL if the modulus clears 0.5 and the
  frequency is within epsphi = 2 degrees of a multiple of 30; otherwise
  it is TRANSITORY.

  period    1/|B| degrees  X-13        ours        
      60    0.667    6.00  trend       trend       OK
      40    0.667    9.00  trend       trend       OK
      40    0.833    9.00  trend       trend       OK
      30    0.667   12.00  trend       trend       OK
      24    0.667   15.00  trend       trend       OK
      22    0.667   16.36  transitory  transitory  OK
      20    0.667   18.00  transitory  transitory  OK
       9    0.667   40.00  transitory  transitory  OK

  8 of 8 readable cases agree.
  The boundary is a period of 24 months and it is sharp: 30 months is
  trend, 22 months is transitory, and nothing about the series changes
  across that line except the root's angle.

  The 24-month row is the one that used to disagree, and it is worth
  knowing why it stopped. The test is a STRICT inequality against an
... [122 more lines]
```
<!-- end -->

Eight of eight positions agree, and the rule is sharp at 24 months: 30 months is trend, 22 months is transitory, and the only thing that changes across that line is the root's angle.

## Error 4: the angle was noisier than the boundary

The 24-month row did **not** agree at first, and the reason is worth more than the fix.

The classification tests are strict inequalities against exact boundaries — $15°$, a multiple of $30°$. Roots land exactly on those boundaries, and then the answer is decided by whatever noise the computed angle carries. The same 24-month root comes out on opposite sides depending on which polynomial you factor:

| Computed from | Angle |
|---|---|
| the AR(2) alone | $15° - 1.8\times10^{-14}$ |
| the expanded degree-14 AR polynomial | $15° + 7.1\times10^{-13}$ |

The obvious implementation builds $\phi(B)\Phi(B^s)(1-B)^d(1-B^s)^D$ and calls `polyroot` once. That is where the $10^{-12}$ comes from, and it is not a rounding curiosity — it is a coin flip deciding which component a root belongs to.

The fix is not an epsilon. It is to **never expand the polynomial**, because every factor's roots are already known or cheap:

| Factor | Roots |
|---|---|
| $(1-B)^d$ | $d$ roots at exactly 1 |
| $(1-B^s)^D$ | $D$ copies of the $s$-th roots of unity, from $\cos$ and $\sin$ |
| $\Phi(B^s)$ | roots of a degree-$P$ polynomial in $u = B^s$, then $s$-th roots of each |
| $\phi(B)$ | `polyroot` on degree $p$ — the only place it is needed |

Angles then come out exact to machine precision and the strict inequality means what it says. As a side effect the repeated-root problem disappears: the airline trend polynomial now matches the hard-coded split to **exactly zero**.

> [!important] This is not a contrived worry
> A **negative** seasonal AR coefficient puts every root of $(1 - \Phi B^s)$ at an *odd* multiple of $180/s$ — for monthly data exactly $15°, 45°, 75° \dots$ The first of those sits exactly on the trend boundary. It is not a construction: `nottem` fitted as $(1,0,0)(1,1,1)$ has $\Phi = -0.2966$, and getting that one root wrong moved the published trend by **2.6 °F**.

## The decomposition itself

With the classification fixed, `imp` under $(2,1,0)(0,1,1)$ — a model `_seats.R` cannot represent at all — comes out as:

| Table | Component | Interior mean | Max | Ends |
|---|---|---|---|---|
| `s10` | seasonal factors | 0.0000% | 0.0000% | 0.0002% |
| `s11` | adjusted series | 0.0000% | 0.0000% | 0.0002% |
| `s12` | trend | 0.0000% | 0.0000% | 0.0000% |
| `s14` | transitory | 0.0000% | 0.0000% | 0.0001% |

The transitory component — the one piece of this that has no counterpart in the airline machinery — agrees to $10^{-6}$.

## Error 5: a constant nobody would have seen

The first run of that comparison came back 1.28% out on every component. In logs the difference was $+0.012691$ with a spread of $1.9\times10^{-7}$: **the shape was already right and the level was wrong**.

$\nu_S(0) = 0$, so the seasonal filter annihilates constants, and the theory genuinely cannot say whether a given constant belongs to the trend or to the seasonal. Some convention has to fix it. X-13 normalises multiplicative factors to average 1 **in levels**, which in logs means a mean near $-\sigma^2/2$, not 0. `_seats.R` does this and documents it. `_seats_general.R` did not.

> [!warning] Why nothing caught it
> A constant multiplicative offset is invisible in every plot in this vault. The trend still tracks the series. The seasonal factors still repeat with the right shape and amplitude. The decomposition identity still holds exactly, because the constant moves between components without leaving. Every internal check passed, and a reader comparing a plot of our trend against a plot of X-13's would have seen two identical curves.
>
> It took comparing against X-13 **on a series `_seats.R` cannot handle**. The general code was the only route to that series, so nothing else in the vault could have found this.

Getting that far left 0.0112% — still a constant, a hundred times smaller. It looked like bookkeeping and was worth chasing anyway, because a residue that is *constant* is never noise.

## Error 6: two normalisations, over two different spans

There is not one convention. There are two, and they use different windows.

The way to find them is not to guess: it is to look through X-13's own tables for the value that comes out **exactly** 1.000000000, because an exact 1 is an imposed rule and nothing else is. On `imp`, which runs July 1983 to December 2013 and so is *not* a whole number of years:

| Table | Level mean, full span | Level mean, first $\lfloor n/12 \rfloor \times 12$ |
|---|---|---|
| `s10` seasonal | 1.000112054 | **1.000000000** |
| `s13` irregular | **1.000000000** | 0.999984698 |
| `s14` transitory | 1.000282561 | 1.000251353 |

So: the **seasonal** averages 1 over the first whole number of years, dropping the leftover months at the end; the **irregular** averages 1 over the **full** span; the **transitory** is not normalised at all; and the trend takes both constants.

The asymmetry is not arbitrary once you see it. A partial final year holds some months and not others, so averaging a *seasonal* factor over it weights those months twice and drags the constant with them. The irregular has no periodic structure, so a partial year costs it nothing and there is no reason to throw six observations away. Nobody would guess that pair, and no amount of staring at the algebra would produce it.

## Error 7: the trend is a residual, not a filter output

That still left the trend out, and it did something strange: **it got worse as the filter got longer.**

Here is the effect isolated, on `AirPassengers`, with the constants already correct so only the shape is being compared:

| `max_lag` | seasonal | trend from its filter | trend as a residual |
|---|---|---|---|
| 250 | 0.00007% | 0.00005% | 0.00005% |
| 331 | 0.00000% | 0.00007% | 0.00003% |
| 500 | 0.00000% | 0.00010% | 0.00003% |
| 1200 | 0.00001% | 0.00024% | 0.00003% |

The seasonal converges, as truncation error should. The filtered trend **diverges** — five times worse at 1200 lags than at 250 — while the residual sits flat.

The reason is the same $\nu(0)$ that runs through this whole note. The seasonal and irregular filters have gain **zero** at frequency zero, so they are blind to the level and immune to whatever the forecast extension does. The trend filter has gain **one** there, so the longer the filter, the deeper it reaches into an ever-lengthening ARIMA forecast, and the more of that forecast's drift it integrates. *Longer is safer* is true for two of the three components and false for the third.

The real tell was in X-13's output all along: its own tables satisfy $\log y = s_{12} + s_{10} + s_{13}$ to $9\times10^{-15}$. Three independently truncated filters do not do that — ours miss by $10^{-5}$. X-13 computes one component by **subtraction**, and it has to be the trend, because the trend is the one carrying the level.

Taking it as a residual instead: **0.00003%**, flat in filter length like everything else.

Before the two normalisations were also fixed, this same effect showed up an order of magnitude larger, because the filtered trend was carrying a wrong constant on top of the drift. That is what made it visible at all — and it is the reason the errors in this note had to be found in the order they were.

## The additive case

Everything above logs the series first. The additive path was the one remaining piece of `_seats_general.R` that nothing in the vault exercised — and it is where error 5 actually bites, because `nottem` fitted as $(1,0,0)(1,1,1)$ has a negative $\Phi$.

With factorwise root-finding, our split matches X-13's exactly: trend $= (1-B)$, seasonal $= S(B)$, and the **entire stationary AR side** — $(1 - 0.2710B)(1 + 0.2966B^{12})$ — in the transitory. Note what that means: with $\Phi$ negative, $(1 - \Phi B^{12})$ has no root at frequency zero and none at a seasonal frequency, so not one of its twelve roots is seasonal. The operator that looks most seasonal contributes nothing to the seasonal component.

The decomposition then agrees, but only once the filter is long enough:

| `max_lag` | seasonal, sd of error | trend, mean error |
|---|---|---|
| 150 | 0.1534 °F | −0.937 °F |
| 250 | 0.0119 °F | −0.067 °F |
| 400 | 0.0005 °F | −0.001 °F |

> [!warning] Nothing used to warn you that the filter was too short
> The components come back looking entirely reasonable — right shape, right period, plausible trend — and at 150 lags they are out by a tenth of a degree in the seasonal and a full degree in the trend. No error, no `NA`, no diagnostic. The vault's own scripts were running `imp` at `max_lag = 200` when it needs 224.
>
> `seats_decompose_general()` now checks it, and the check is worth stating because the intuitive version is wrong. The decay rate is **not** set by the AR side. The Wiener–Kolmogorov filter is a *ratio* whose poles are the zeros of $\theta(B)\theta(F)$, so the weights fall off like $m^{\text{lag}}$ with $m$ the largest inverse-root modulus of the **MA** polynomial. For `nottem`, $\Theta = 0.7282$ gives $m = 0.7282^{1/12} = 0.974$ and a required $\log(10^{-6})/\log m \approx 523$ lags.
>
> `AirPassengers` needs 283, `imp` 224, `nottem` 523. Asking the AR side instead would have said 136 for `nottem` and looked fine.
>
> `max_lag` now **defaults** from the model rather than being a fixed number, which is what `_seats.R` has done via `seats_max_lag()` since the day it was written. That is the second time the general implementation turned out to be missing something the special case already knew — the first was the normalisation. It was built by generalising the algebra and not the hard-won details, and both gaps survived every internal check.

## What this changed elsewhere

- [[40-10-general-seats]]'s showcase example — a 40-month cycle isolated into the transitory component — was wrong, and its "why this matters" argument was backwards. X-13 puts a 40-month cycle in the trend.
- Its **honest negative result** — no catalogue series produces a transitory component — was an artifact of the missing modulus gate. `cpi` and `ukgas` both produce one.
- The repeated-root precision loss described there was real and entirely avoidable: finding roots factor by factor instead of expanding first takes the airline trend polynomial from $2\times10^{-8}$ to **exactly zero**.
- `_seats.R` — the validated, airline-only implementation that half this vault depends on — inherited errors 6 and 7. It was missing the irregular normalisation entirely and was taking its trend from the filter. [[40-08-validating-against-x13]] went from 0.001% to **0.000003%**, and its "where the residual comes from" section had to be rewritten because the residual it was accounting for no longer existed.

> [!important] The general lesson, which is not about SEATS
> Seven errors, and the internal checks caught none of them, because internal checks answer "is this code consistent with itself". All seven were consistent with themselves. Two of them were also invisible in every graphic in this vault, because a constant offset on a multiplicative factor does not change the shape of anything.
>
> An implementation is validated against an independent one or it is not validated. "It reproduces the special case" is necessary and nowhere near sufficient, since the special case is precisely where the general machinery does nothing — and worse, the special case here was itself wrong in two ways that only the general code could expose.
>
> The other transferable habit: **numerical error and convention error live on different scales.** Truncation, backcasting and optimiser differences buy you $10^{-4}$. Anything at $10^{-2}$ or $10^{-3}$ is a rule you have not matched, and it is written down somewhere in the other program's output. Look for the number that comes out exactly 1.

## Exercises

*Solutions: [[solutions#40-11-validating-general-seats|worked answers]] in the solutions appendix.*

1. Run the classification comparison. All eight positions agree — which one would disagree if the roots were taken from the expanded polynomial, and why?
2. Set `rmod = 0` and re-classify `imp`. Which component gains the AR(2), and what does it do to the seasonal factors?
3. Set `epsphi = 15` and confirm you reproduce the original bug.
4. Take the 40-month cycle and find the modulus at which it stops being trend. Is it `rmod` exactly?
5. Run the decomposition with `normalize = FALSE` and confirm the 1.28% offset. Plot our seasonal against X-13's — can you see it?
6. Compute the log difference between the two seasonal components and show that its standard deviation is $10^{-6}$ while its mean is not.
7. Why does the transitory component agree to $10^{-6}$ when the seasonal only reaches 0.011%?
8. `imp` fitted as an airline model has no AR(2) at all. Decompose it both ways and compare the seasonal factors — how much does the model choice move them, against how much the implementation does?
9. Find a second real series whose fitted model produces a transitory component, and validate it the same way.
10. The parsing in `x13_ar_split()` depends on X-13's output format. Write the check that would tell you it had silently stopped working.
11. Fit `nottem` as $(1,0,0)(1,1,1)$ and classify its roots. How many of the twelve roots of $(1 - \Phi B^{12})$ end up in the seasonal component, and why is the answer surprising?
12. Decompose `nottem` additively at `max_lag` 150 and 400 and plot both trends. Could you tell which one is wrong without the reference?
13. Print the level mean of `s10`, `s13` and `s14` for `imp` over the full span and over the first 360 observations. Which entries are exactly 1, and what does each one tell you?
14. Why does the seasonal normalisation drop the leftover months and the irregular one keep them? Answer from what the two components *are*, not from the code.
15. Take the trend from its filter rather than as a residual and plot the error against `max_lag` from 200 to 1200. Explain the shape, then say which component is immune and why.
16. `_seats.R` was validated against X-13 and still had two of these errors for weeks. What property of `AirPassengers` hid them?

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** Before running anything, say where a pair at 26 months with inverse modulus 0.6 goes. Then check.
2. **Break it.** Take the roots from `polyroot()` on the expanded AR polynomial instead of factor by factor, and re-run the classification comparison. Which row flips, and by how many degrees?
3. **Transfer.** The normalisation bug was invisible because every check was self-referential. Name another place in this vault where that risk exists, and say what independent comparison would close it.

## Practice set

*Drills, output-reading and judgement calls. Short answers; the point is fluency and knowing what you are looking at.*

1. **Drill.** State X-13's three constants and what each one gates.
2. **Drill.** For a root with $1/|z| = 0.48$ at $60°$, give the component.
3. **Read it.** A comparison shows mean log difference $0.0127$ and standard deviation $10^{-6}$. Diagnose it in one sentence.
4. **Read it.** X-13's transitory polynomial comes back as `1.0000` and nothing else. What does that mean?
5. **Judgement.** Your implementation matches on nine of ten series and is 1% out on the tenth, uniformly. Ship it?
6. **Judgement.** A colleague validates a new implementation by checking it reproduces the airline case exactly. What have they established?

## Links

- Prev: [[40-10-general-seats]] · Module map: [[40-00-seats-map]]
- Compare: [[40-08-validating-against-x13]] — the same exercise for the airline model
- Builds on: [[40-03-canonical-decomposition]], [[40-02-admissible-decompositions]]
