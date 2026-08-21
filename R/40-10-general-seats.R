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
cat("  The trend gap is 2e-8, not 0, and that is worth understanding: (1-B)^2\n")
cat("  has a DOUBLE root at B = 1, and root-finding at a repeated root loses\n")
cat("  about half the available precision. Generality has a numerical price.\n")

cat("\n=== 2. full decomposition vs the validated airline implementation ===\n")
g <- seats_decompose_general(AirPassengers, ma = 0.4018, sma = 0.5569,
                             d = 1, D = 1, s = 12, max_lag = 340, extend = 360)
r <- seats_decompose(AirPassengers, 0.4018, 0.5569, normalize = FALSE)
for (k in c("trend", "seasonal"))
  cat(sprintf("  %-9s max |general - _seats.R| = %.8f\n",
              k, max(abs(as.numeric(g[[k]]) - as.numeric(r[[k]])))))
cat(sprintf("  partial-fraction residual %.2e   admissible %s\n",
            g$residual, g$admissible))

# ---- 3. the fourth component, on a model that actually has one ------------
cat("\n=== 3. a TRANSITORY component: the thing the airline model cannot have ===\n")
per <- 40; rmod <- 1.05; wc <- 2 * pi / per
a1 <- 2 * cos(wc) / rmod; a2 <- -1 / rmod^2
cat(sprintf("  AR(2) with complex roots at period %d months, modulus %.2f\n", per, rmod))
spT <- seats_ar_split_general(ar = c(a1, a2), d = 1, D = 1, s = 12)
print(head(spT$table[order(spT$table$freq_rad), ], 5), row.names = FALSE)
cat("  ...\n")
cat("  trend      :", poly_show(spT$trend), "\n")
cat("  transitory :", poly_show(spT$transitory), "\n")
cat("  The cyclical pair went to TRANSITORY. _seats.R would have folded it\n")
cat("  into the trend, putting a three-year business cycle inside a series\n")
cat("  people read as 'the underlying level'.\n")

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
cat("  (b) NO real catalogue series produces a transitory component. Every AR\n")
cat("      root landed at frequency zero or at a seasonal frequency. The\n")
cat("      fourth component is real and demonstrable, and it is also rare.\n")

# ---- 5. the seasonal AR contributes a TREND root -------------------------
cat("\n=== 5. a detail that is easy to get wrong ===\n")
spS <- seats_ar_split_general(sar = 0.8, d = 0, D = 0, s = 12)
cat("  the operator (1 - 0.8 B^12) alone has 12 roots:\n")
print(table(spS$table$component))
cat("  One of them sits at frequency ZERO and belongs to the TREND, not the\n")
cat("  seasonal -- (1 - Phi B^12) is not a purely seasonal operator. Sorting\n")
cat("  by frequency gets this right automatically; sorting by which factor a\n")
cat("  root came from would not.\n")
