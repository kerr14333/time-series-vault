# 30-08 -- What a filter IS, and why frequency is its natural language.
#
# Modules 2 and 4 both build filters; this script establishes the general
# facts they rely on, none of which are specific to seasonal adjustment.
source("R/_setup.R"); source("R/_x11.R"); source("R/_spectral.R")

# ---- 1. linear + time-invariant => convolution ----------------------------
cat("=== 1. LTI forces the convolution form ===\n")
# A filter is LINEAR (scaling and adding inputs scales and adds outputs) and
# TIME-INVARIANT (delaying the input just delays the output). Those two
# assumptions ALONE force y_t = sum_j w_j x_{t-j}. Demonstrate both.
w <- henderson(13)
x1 <- as.numeric(lap)
set.seed(1); x2 <- rnorm(length(x1))
a <- 3; b <- -2
lhs <- symfilter(a * x1 + b * x2, w)
rhs <- a * symfilter(x1, w) + b * symfilter(x2, w)
cat("  linearity  : max |F(ax+by) - aF(x) - bF(y)| =",
    format(max(abs(lhs - rhs), na.rm = TRUE)), "\n")

shift <- 7
y_then_shift <- c(rep(NA, shift), head(symfilter(x1, w), -shift))
shift_then_y <- symfilter(c(rep(NA, shift), head(x1, -shift)), w)
cat("  invariance : max |shift(F(x)) - F(shift(x))| =",
    format(max(abs(y_then_shift - shift_then_y), na.rm = TRUE)), "\n\n")

# ---- 2. the eigenfunction property ----------------------------------------
cat("=== 2. complex exponentials are EIGENFUNCTIONS ===\n")
cat("Feed in e^{i w t}; get back the SAME function, scaled by a complex number.\n")
cat("That scalar is the transfer function. This one fact is why the frequency\n")
cat("domain is the natural coordinate system for filters.\n\n")
tt <- 1:400
for (fq in c(1/12, 1/6, 0.3)) {
  ww <- 2 * pi * fq
  xin <- exp(1i * ww * tt)
  m <- (length(w) - 1) / 2
  yout <- vapply((m + 1):(length(tt) - m), function(t)
    sum(w * xin[(t + m):(t - m)]), complex(1))
  ratio <- yout / xin[(m + 1):(length(tt) - m)]
  H <- transfer(w, fq)
  cat(sprintf("  f = %.4f : output/input constant? sd = %.2e   ratio = %+.5f   H(f) = %+.5f\n",
              fq, sd(Mod(ratio)), Re(ratio[1]), Re(H)))
}

# ---- 3. gain and phase are just modulus and argument ----------------------
cat("\n=== 3. gain = |H|, phase = arg(H) ===\n")
ff <- c(0, 1/12, 1/6, 1/4, 1/2)
sym <- ma_2xs(12)
one <- sym[7:13] / sum(sym[7:13])            # a one-sided version
cat("  freq      gain(sym)  phase(sym)   gain(1-sided)  phase(1-sided)\n")
for (f in ff)
  cat(sprintf("  %6.4f  %9.5f  %10.5f  %13.5f  %14.5f\n",
              f, gain(sym, f), phase(sym, f), gain(one, f), phase(one, f)))
cat("  Symmetric: phase identically 0 or pi -- no cycle is moved in time.\n")
cat("  One-sided: phase varies with frequency -- different cycles shift by\n")
cat("  different amounts, which is how end filters displace turning points.\n")

# ---- 4. group delay: how far a filter actually shifts a cycle -------------
cat("\n=== 4. group delay = -d(phase)/d(omega), in PERIODS ===\n")
gdelay <- function(wts, f, h = 1e-4) {
  p1 <- Arg(transfer(wts, f - h)); p2 <- Arg(transfer(wts, f + h))
  -(p2 - p1) / (2 * h) / (2 * pi)
}
# Use a LOW-PASS filter, and stay away from its zeros: where the gain is 0
# the phase jumps by pi and the derivative is meaningless, not infinite.
hsym <- henderson(13)
hone <- hsym[7:13] / sum(hsym[7:13])        # the crude one-sided version
cat("  freq  period   gain(sym)  delay(sym)   gain(1-sided)  delay(1-sided)\n")
for (f in c(1/60, 1/36, 1/24, 1/18)) {
  cat(sprintf("  %.4f %6.1f  %9.4f  %10.3f  %13.4f  %14.3f\n",
              f, 1/f, gain(hsym, f), gdelay(hsym, f),
              gain(hone, f), gdelay(hone, f)))
}
cat("  The symmetric filter delays NOTHING at any frequency.\n")
cat("  The one-sided filter delays by about 1.5 months -- roughly half its\n")
cat("  length -- and by a DIFFERENT amount at each frequency. That is why a\n")
cat("  concurrent trend estimate lags, and why the lag is not a constant you\n")
cat("  can simply subtract off (20-07).\n")

# ---- 5. the algebra: cascade multiplies, parallel adds --------------------
cat("\n=== 5. cascade multiplies transfer functions ===\n")
w3 <- rep(1, 3) / 3; w5 <- rep(1, 5) / 5
casc <- as.numeric(stats::convolve(w3, rev(w5), type = "open"))
f <- c(1/12, 1/5, 1/3)
cat("  freq   gain(cascade)   gain(3)*gain(5)\n")
for (fq in f)
  cat(sprintf("  %.4f  %13.6f  %16.6f\n", fq, gain(casc, fq), gain(w3, fq) * gain(w5, fq)))
cat("  So a chain of simple filters can be analysed one stage at a time --\n")
cat("  which is exactly how the X-11 composite filter is understood (20-05).\n")

# ---- 6. weights sum to 1 IS gain(0) = 1 ----------------------------------
cat("\n=== 6. the normalisation everyone states and few justify ===\n")
for (wts in list(w3, ma_2xs(12), henderson(13), seasonal_ma("3x5")))
  cat(sprintf("  length %2d : sum(w) = %.10f   gain(0) = %.10f\n",
              length(wts), sum(wts), gain(wts, 0)))
cat("  Identical, because gain(0) = |sum_j w_j e^{0}| = |sum_j w_j|. A filter\n")
cat("  whose weights did not sum to 1 would rescale a constant series.\n")

# ---- 7. FIR versus IIR ----------------------------------------------------
cat("\n=== 7. FIR vs IIR: why SEATS filters are not moving averages ===\n")
cat("  A moving average is FIR: finitely many weights, always stable.\n")
cat("  A WK filter is IIR -- a RATIO of polynomials. Its weight sequence is\n")
cat("  infinite. Two ways to cope:\n")
nu_seq <- 0.6^(0:40)
cat("    truncate  : keep terms until they are small. Weight 20 =",
    signif(nu_seq[21], 3), ", weight 40 =", signif(nu_seq[41], 3), "\n")
cat("    recurse   : run it as a difference equation, exactly (40-09).\n")

# ---- 8. you cannot build the brick wall ----------------------------------
cat("\n=== 8. the brick wall you cannot build ===\n")
# NOTE an ideal NOTCH -- gain 1 except exactly 0 at six isolated points -- is
# a red herring: isolated points have measure zero, so its Fourier
# coefficients are those of the identity filter. The real constraint shows up
# with an ideal LOW-PASS, gain 1 below a cutoff and 0 above.
ideal_lowpass <- function(L, fc) {
  wc <- 2 * pi * fc; j <- -L:L
  vapply(j, function(k) if (k == 0) wc / pi else sin(wc * k) / (pi * k), numeric(1))
}
fc <- 0.1
# Measure the overshoot over the WHOLE passband. Excluding a fixed window
# around the cutoff measures the wrong thing: the ripple narrows as L grows,
# so it moves inside the excluded window and the overshoot looks like it is
# shrinking when it is not.
cat("  cutoff at f = 0.10. Ideal gain: 1 below, 0 above.\n")
cat("  half-length   passband overshoot   transition width   max stopband gain\n")
for (L in c(12, 24, 48, 96, 192, 384)) {
  wts <- ideal_lowpass(L, fc)
  fpass <- seq(0, fc, length.out = 20001)
  over <- max(gain(wts, fpass)) - 1
  fg <- seq(0, 0.5, length.out = 20001)
  g <- gain(wts, fg)
  # transition width: from the last f where gain > 0.9 to the first where < 0.1
  lo <- max(fg[g > 0.9 & fg < fc]); hi <- min(fg[g < 0.1 & fg > fc])
  cat(sprintf("  %10d   %16.2f%%   %16.4f   %18.4f\n",
              L, 100 * over, hi - lo, max(g[fg > fc + 0.05])))
}
cat("  The transition width falls roughly like 1/L -- lengthening the filter\n")
cat("  really does buy a sharper edge. But the OVERSHOOT does not shrink: it\n")
cat("  settles near 9% and stays there however long the filter gets.\n")
cat("  That is Gibbs' phenomenon. You can buy sharpness with length; you can\n")
cat("  never buy a clean edge. Every practical seasonal filter is therefore a\n")
cat("  negotiated compromise, not an approximation to something achievable.\n")
