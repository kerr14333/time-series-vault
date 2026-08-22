---
aliases: [40-10-general-seats.R]
tags: [code, generated]
---

# `R/40-10-general-seats.R`

SEATS for an arbitrary (p,d,q)(P,D,Q), with a transitory component.

> [!info] Generated file
> Mirror of `R/40-10-general-seats.R`. **Edit the script, not this note** — re-run `R/make-code-notes.R` to refresh.
> Concept note: [[40-10-general-seats]]

```r
# 40-10 -- SEATS for an arbitrary (p,d,q)(P,D,Q), with a transitory component.
#
# _seats.R hard-codes the airline model's AR split. This script uses
# _seats_general.R, which DISCOVERS the split by finding the AR roots and
# sorting them by frequency.
source("R/_seats_general.R"); source("R/_series.R")
suppressMessages(library(seasonal))

# ---- 1. the airline model still comes out right ---------------------------
cat("=== 1. the general code must reproduce the special case ===\n")
sp <- seats_ar_split_general(d = 1, D = 1, s = 12)
old <- seats_ar_split(1, 1, 12)
cat("  trend    :", poly_show(sp$trend), "\n")
cat("  seasonal :", poly_show(sp$seasonal), "\n")
cat("  transitory: none (correct -- an airline model has no cyclical roots)\n")
cat(sprintf("  max difference from the hard-coded split: trend %.2e  seasonal %.2e\n",
            max(abs(sp$trend - old$trend)), max(abs(sp$seasonal - old$seasonal))))
cat("  (1-B)^2 has a DOUBLE root at B = 1, and polyroot cannot return it as\n")
cat("  one root: it returns a cluster of two, about 1e-7 apart, with small\n")
cat("  imaginary parts of opposite sign. Rebuilding the factor from the MEAN\n")
cat("  of the conjugate pair cancels that error instead of propagating it,\n")
cat("  which is why the gap here is 1e-14 rather than the 1e-8 you get from\n")
cat("  using either member alone. Generality has a numerical price, and this\n")
cat("  is how you avoid paying it.\n")

cat("\n=== 2. full decomposition vs the validated airline implementation ===\n")
g <- seats_decompose_general(AirPassengers, ma = 0.4018, sma = 0.5569,
                             d = 1, D = 1, s = 12, max_lag = 340, extend = 360)
r <- seats_decompose(AirPassengers, 0.4018, 0.5569)
for (k in c("trend", "seasonal"))
  cat(sprintf("  %-9s max |general - _seats.R| = %.8f\n",
              k, max(abs(as.numeric(g[[k]]) - as.numeric(r[[k]])))))
cat(sprintf("  partial-fraction residual %.2e   admissible %s\n",
            g$residual, g$admissible))

# ---- 3. where a cyclical pair actually goes -------------------------------
cat("\n=== 3. two cycles, two different answers ===\n")
show_cycle <- function(per, rB, want) {
  wc <- 2 * pi / per
  sp <- seats_ar_split_general(ar = c(2 * cos(wc) / rB, -1 / rB^2), d = 1, D = 1, s = 12)
  row <- sp$table[abs(sp$table$modulus - rB) < 1e-6, ][1, ]
  cat(sprintf("  period %2d months, 1/|B| = %.3f, %5.2f deg  ->  %-10s (X-13: %s)\n",
              per, row$inv_mod, 360 / per, row$component, want))
  invisible(sp)
}
spT <- show_cycle(40, 1.05, "trend")
show_cycle(20, 1.05, "transitory")
show_cycle( 9, 1.50, "transitory")
cat("\n  The 40-month cycle joins the TREND, and that is correct: X-13 sends\n")
cat("  any complex pair within 360/(2s) = 15 degrees of frequency zero -- a\n")
cat("  cycle of 24 months or longer -- to the trend. The component is the\n")
cat("  TREND-CYCLE. A business cycle belongs in it by construction, and the\n")
cat("  boundary is a period of two years, not a matter of taste.\n")
cat("  Verified against X-13's printed AR factorization at 6, 9, 12, 15 (all\n")
cat("  trend) and 16.4, 18, 40 degrees (all transitory) -- see 40-11.\n")
cat("\n  trend polynomial for the 40-month case:", poly_show(spT$trend), "\n")
spC <- seats_ar_split_general(ar = c(2 * cos(2*pi/9) / 1.5, -1 / 1.5^2),
                              d = 1, D = 1, s = 12)
cat("  transitory polynomial for the 9-month case:", poly_show(spC$transitory), "\n")
cat("  A 9-month cycle is too fast for the trend and not a seasonal\n")
cat("  frequency, so it becomes the fourth component: the code says 'this\n")
cat("  movement is real and persistent, and it is not the trend'.\n")

# ---- 4. real series: which get a non-airline model? ----------------------
cat("\n=== 4. the catalogue, with models fitted properly ===\n")
cases <- list(
  list(nm = "unemp", x = seasonal::unemp, o = c(1,1,1), s = c(0,1,1)),
  list(nm = "cpi",   x = seasonal::cpi,   o = c(2,1,2), s = c(1,0,1)),
  list(nm = "ukgas", x = UKgas,           o = c(1,1,1), s = c(0,1,1))
)
for (cs in cases) {
  s <- frequency(cs$x)
  f <- tryCatch(arima(log(cs$x), order = cs$o,
                      seasonal = list(order = cs$s, period = s), method = "ML"),
                error = function(e) NULL)
  if (is.null(f)) { cat(sprintf("  %-8s arima failed\n", cs$nm)); next }
  co <- coef(f); p <- cs$o[1]; q <- cs$o[3]; P <- cs$s[1]; Q <- cs$s[3]
  ar  <- if (p) as.numeric(co[1:p]) else numeric(0)
  ma  <- if (q) -as.numeric(co[p + 1:q]) else numeric(0)
  sar <- if (P) as.numeric(co[p+q + 1:P]) else numeric(0)
  sma <- if (Q) -as.numeric(co[p+q+P + 1:Q]) else numeric(0)
  d <- tryCatch(seats_decompose_general(cs$x, ar, ma, sar, sma,
                                        d = cs$o[2], D = cs$s[2], s = s,
                                        max_lag = 200, extend = 220),
                error = function(e) NULL)
  if (is.null(d)) { cat(sprintf("  %-8s decomposition failed\n", cs$nm)); next }
  nb <- table(d$table$component)
  recon <- as.numeric(d$trend) + as.numeric(d$seasonal) +
           as.numeric(d$transitory) + as.numeric(d$irregular)
  cat(sprintf("  %-8s roots: %-34s identity %.1e  admissible %-5s  sd(transitory) %.4f\n",
              cs$nm, paste(names(nb), nb, sep = "=", collapse = " "),
              max(abs(log(as.numeric(cs$x)) - recon)), d$admissible, sd(d$transitory)))
}
cat("\n  Two things to notice.\n")
cat("  (a) cpi comes back INADMISSIBLE -- independently reproducing the result\n")
cat("      40-02 found by a completely different route. Two implementations\n")
cat("      agreeing on an awkward case is worth more than either alone.\n")
cat("  (b) cpi and ukgas DO produce a transitory component, and unemp does\n")
cat("      not. An earlier version of this script reported no transitory\n")
cat("      component on any real series -- that was an artifact of a wrong\n")
cat("      classification rule, which had no modulus test and a 15-degree\n")
cat("      seasonal window, so short-lived roots were swept into the seasonal.\n")
cat("      X-13 requires the inverse-root modulus to reach 0.5 before a root\n")
cat("      may join the trend or the seasonal, and puts the seasonal window\n")
cat("      at 2 degrees. Under the correct rule the fourth component is\n")
cat("      uncommon but not rare. See 40-11 for the validation.\n")

# ---- 5. the seasonal AR contributes a TREND root -------------------------
cat("\n=== 5. a detail that is easy to get wrong ===\n")
spS <- seats_ar_split_general(sar = 0.8, d = 0, D = 0, s = 12)
cat("  the operator (1 - 0.8 B^12) alone has 12 roots:\n")
print(table(spS$table$component))
cat("  One of them sits at frequency ZERO and belongs to the TREND, not the\n")
cat("  seasonal -- (1 - Phi B^12) is not a purely seasonal operator. Sorting\n")
cat("  by frequency gets this right automatically; sorting by which factor a\n")
cat("  root came from would not.\n")
```

## Run it

```r
setwd("D:/time-series-vault/time-series-vault")
source("R/40-10-general-seats.R")
```

Back to [[40-10-general-seats]] · index: [[code-index]]
