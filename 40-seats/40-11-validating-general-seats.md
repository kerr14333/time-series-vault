---
aliases: [Validating general SEATS, Root sorting validation, rmod and epsphi]
tags: [module-4]
---

# Validating the general implementation against X-13

Code: [[code-40-11-validating-general-seats|`R/40-11-validating-general-seats.R`]]

[[40-08-validating-against-x13]] checks `_seats.R` against the Census binary and gets 0.001% on the airline model. That result says nothing about [[40-10-general-seats]], because the thing the general code does — decide which component each AR root belongs to — is exactly the thing the airline model never exercises. Every root in an airline model is a unit root sitting on a frequency the split already knows about.

So the general code went into the vault validated for *internal* consistency only: the decomposition identity held exactly, the partial-fraction residual was $10^{-13}$, and it independently reproduced 40-02's finding that `cpi` is inadmissible. All true, all reassuring, and none of it able to catch a wrong classification rule — because a wrong rule produces a perfectly self-consistent decomposition of the wrong thing.

It caught nothing. There were four errors: three in the classification rule and one in the normalisation, and the fourth is the one worth remembering, because it was invisible in every plot.

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
> The rule is also in the Census Fortran (`sigsub.f`), and reading it there is how the constants below were found. But source code tells you what the program is *supposed* to do. The printout tells you what it did. When those disagree — and on the boundary case below they effectively do — the printout wins.

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
      24    0.667   15.00  trend       transitory  <-- MISMATCH
      22    0.667   16.36  transitory  transitory  OK
      20    0.667   18.00  transitory  transitory  OK
       9    0.667   40.00  transitory  transitory  OK

  7 of 8 readable cases agree.
  The boundary is a period of 24 months and it is sharp: 30 months is
  trend, 22 months is transitory, and nothing about the series changes
  across that line except the root's angle.

  The one disagreement is AT the boundary, and it is not a rule error.
  From the AR(2) alone the angle is 15 -1.8e-14 degrees -- below the
... [48 more lines]
```
<!-- end -->

Seven of eight positions agree. The rule is sharp at 24 months: 30 months is trend, 22 months is transitory, and the only thing that changes across that line is the root's angle.

The eighth is *at* the boundary — a cycle of exactly 24 months, sitting exactly on the $15°$ cutoff. Both programs compute the angle to within a part in $10^{12}$ and round to opposite sides of a strict inequality. It is left in the output as a mismatch rather than patched with an epsilon: an epsilon chosen to make a test pass would hide a real property of the rule, which is that it has a discontinuity and a root can sit on it.

## The decomposition itself

With the classification fixed, `imp` under $(2,1,0)(0,1,1)$ — a model `_seats.R` cannot represent at all — comes out as:

| Table | Component | Interior mean | Max | Ends |
|---|---|---|---|---|
| `s10` | seasonal factors | 0.0112% | 0.0115% | 0.0115% |
| `s11` | adjusted series | 0.0112% | 0.0115% | 0.0115% |
| `s12` | trend | 0.0054% | 0.0055% | 0.0056% |
| `s14` | transitory | 0.0000% | 0.0001% | 0.0001% |

The transitory component — the one piece of this that has no counterpart in the airline machinery — agrees to $10^{-6}$.

## Error 4: a constant nobody would have seen

The first run of that comparison came back 1.28% out on every component. In logs the difference was $+0.012688$ with a spread of $9.8\times10^{-7}$: **the shape was already right and the level was wrong**.

$\nu_S(0) = 0$, so the seasonal filter annihilates constants, and the theory genuinely cannot say whether a given constant belongs to the trend or to the seasonal. Some convention has to fix it. X-13 normalises multiplicative factors to average 1 **in levels**, which in logs means a mean near $-\sigma^2/2$, not 0. `_seats.R` does this and documents it. `_seats_general.R` did not.

> [!warning] Why nothing caught it
> A constant multiplicative offset is invisible in every plot in this vault. The trend still tracks the series. The seasonal factors still repeat with the right shape and amplitude. The decomposition identity still holds exactly, because the constant moves between components without leaving. Every internal check passed, and a reader comparing a plot of our trend against a plot of X-13's would have seen two identical curves.
>
> It took comparing against X-13 **on a series `_seats.R` cannot handle**. The general code was the only route to that series, so nothing else in the vault could have found this.

What remains is a residual constant of 0.0112%, which is the normalisation *window*: X-13 is not averaging over exactly the 366 observations this code uses. Restricting to complete calendar years makes it worse (0.09%), so the convention is something else again. The 1e-6 shape agreement is the number that says the filters are right; the last constant is bookkeeping.

## What this changed elsewhere

- [[40-10-general-seats]]'s showcase example — a 40-month cycle isolated into the transitory component — was wrong, and its "why this matters" argument was backwards. X-13 puts a 40-month cycle in the trend.
- Its **honest negative result** — no catalogue series produces a transitory component — was an artifact of the missing modulus gate. `cpi` and `ukgas` both produce one.
- The repeated-root precision loss described there was real but avoidable: rebuilding a conjugate pair's quadratic factor from the *mean* of the pair rather than either member takes the airline trend polynomial from $2\times10^{-8}$ to $3\times10^{-14}$.

> [!important] The general lesson, which is not about SEATS
> Four errors, and the internal checks caught none of them, because internal checks answer "is this code consistent with itself". Three of the four were consistent with themselves. The fourth — the constant — was consistent with itself *and* invisible in every graphic.
>
> An implementation is validated against an independent one or it is not validated. "It reproduces the special case" is necessary and nowhere near sufficient, since the special case is precisely where the general machinery does nothing.

## Exercises

*Solutions: [[solutions#40-11-validating-general-seats|worked answers]] in the solutions appendix.*

1. Run the classification comparison. Which position disagrees, and why is it not a rule error?
2. Set `rmod = 0` and re-classify `imp`. Which component gains the AR(2), and what does it do to the seasonal factors?
3. Set `epsphi = 15` and confirm you reproduce the original bug.
4. Take the 40-month cycle and find the modulus at which it stops being trend. Is it `rmod` exactly?
5. Run the decomposition with `normalize = FALSE` and confirm the 1.28% offset. Plot our seasonal against X-13's — can you see it?
6. Compute the log difference between the two seasonal components and show that its standard deviation is $10^{-6}$ while its mean is not.
7. Why does the transitory component agree to $10^{-6}$ when the seasonal only reaches 0.011%?
8. `imp` fitted as an airline model has no AR(2) at all. Decompose it both ways and compare the seasonal factors — how much does the model choice move them, against how much the implementation does?
9. Find a second real series whose fitted model produces a transitory component, and validate it the same way.
10. The parsing in `x13_ar_split()` depends on X-13's output format. Write the check that would tell you it had silently stopped working.

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** Before running anything, say where a pair at 26 months with inverse modulus 0.6 goes. Then check.
2. **Break it.** Remove the conjugate-pair averaging from `poly_from_roots()` and measure how far the airline trend polynomial drifts.
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
