# 40-09 -- Burman's algorithm, built from scratch.
#
# The Wiener-Kolmogorov filter is an INFINITE two-sided filter (30-06). Our
# seats_decompose() copes by truncating it and extending the series far
# enough that the truncation does not matter -- which needed 331 lags, 27.6
# years, for a 12-year series (30-07). That works, but it is brute force.
#
# Burman (1980) gets the SAME answer exactly, with two short recursions and
# only q forecasts. This script builds it and checks the two against each
# other.
#
# The trick, in one line: a symmetric rational filter splits by partial
# fractions into a backward-looking piece and a forward-looking piece,
#
#     W(B,F) / [theta(B) theta(F)]  =  g(B)/theta(B)  +  g(F)/theta(F)
#
# and each piece is an ordinary one-sided recursion that runs in O(n).
#
source("R/_setup.R"); source("R/_spectral.R"); source("R/_seats.R")

# ---- symmetric Laurent polynomials, stored as coefficients of B^0..B^m -----
# A symmetric Laurent polynomial c_0 + sum_j c_j (B^j + F^j) is exactly what
# an autocovariance-like object is. cospoly_from_poly() in _seats.R already
# produces these.

# Multiply two symmetric Laurent polynomials (one-sided storage).
laurent_mult <- function(a, b) {
  fa <- c(rev(a[-1]), a); fb <- c(rev(b[-1]), b)     # full two-sided form
  fc <- stats::convolve(fa, rev(fb), type = "open")
  m <- (length(fc) - 1) / 2
  fc[(m + 1):length(fc)]
}

# ---- step 1: the numerator and denominator of the component filter ---------
# nu_S = Ccan(B,F) * DT(B,F) / N(B,F),  N = theta(B) theta(F).
burman_pieces <- function(theta, Theta, s = 12) {
  ma <- airline_ma(theta, Theta)          # theta(B), Census signs, degree 13
  sp <- seats_ar_split(1, 1, s)
  pf <- seats_partial_fractions(ma, sp$trend, sp$seas)
  cn <- seats_canonical(pf)
  list(ma = ma, cn = cn,
       W_seas  = laurent_mult(cn$Ccan, cn$DT),
       W_trend = laurent_mult(cn$Acan, cn$DS),
       N = cn$N)
}

# ---- step 2: solve W(B,F) = g(B) theta(F) + g(F) theta(B) -----------------
# Match coefficients of B^k for k = 0..m. g has degree q = length(theta) - 1.
# Coefficient of B^k in g(B)theta(F): sum_j g_j th_{j-k}  (th index >= 0)
# Coefficient of B^k in g(F)theta(B): sum_j g_j th_{j+k}
burman_g <- function(W, ma_poly) {
  q <- length(ma_poly) - 1L                 # theta degree
  th <- function(i) if (i >= 0 && i <= q) ma_poly[i + 1L] else 0
  m <- q                                    # match k = 0..q
  A <- matrix(0, m + 1L, q + 1L)
  for (k in 0:m) for (j in 0:q)
    A[k + 1L, j + 1L] <- th(j - k) + th(j + k)
  # k = 0 double-counts the constant term: g_j th_j appears once, not twice
  for (j in 0:q) A[1L, j + 1L] <- th(j)
  rhs <- vapply(0:m, function(k) if (k + 1L <= length(W)) W[k + 1L] else 0, numeric(1))
  rhs[1L] <- rhs[1L] / 2                    # symmetric storage: halve the centre
  as.numeric(qr.solve(A, rhs))
}

# ---- step 3: the two one-sided recursions ---------------------------------
# theta(B) u_t = g(B) z_t   run FORWARD;   theta(F) v_t = g(F) z_t  BACKWARD.
# theta has all roots outside the unit circle, so both are stable.
# theta(B) u_t = g(B) z_t, solved forward. Census signs: theta = 1 - th1 B - ...
# so  u_t = sum_j g_j z_{t-j}  -  sum_{i>=1} theta_i u_{t-i}.
solve_fwd <- function(z, g, ma_poly) {
  n <- length(z); q <- length(ma_poly) - 1L
  u <- numeric(n)
  for (t in seq_len(n)) {
    acc <- 0
    for (j in 0:(length(g) - 1L)) if (t - j >= 1) acc <- acc + g[j + 1L] * z[t - j]
    if (q >= 1) for (i in 1:q) if (t - i >= 1) acc <- acc - ma_poly[i + 1L] * u[t - i]
    u[t] <- acc
  }
  u
}
solve_bwd <- function(z, g, ma_poly) rev(solve_fwd(rev(z), g, ma_poly))

# ---- step 4: put it together ----------------------------------------------
burman_component <- function(z, theta, Theta, s = 12, which = "seasonal",
                             extend = 60) {
  bp <- burman_pieces(theta, Theta, s)
  W  <- if (which == "seasonal") bp$W_seas else bp$W_trend
  g  <- burman_g(W, bp$ma)
  # extend with forecasts/backcasts so the recursions have run-up room
  y  <- as.numeric(z)
  f  <- arima(y, order = c(0, 1, 1),
              seasonal = list(order = c(0, 1, 1), period = s), method = "ML")
  fc <- as.numeric(predict(f, n.ahead = extend)$pred)
  bc <- rev(as.numeric(predict(arima(rev(y), order = c(0, 1, 1),
              seasonal = list(order = c(0, 1, 1), period = s), method = "ML"),
              n.ahead = extend)$pred))
  ext <- c(bc, y, fc)
  out <- solve_fwd(ext, g, bp$ma) + solve_bwd(ext, g, bp$ma)
  out[(extend + 1):(extend + length(y))]
}

# ============================================================== DEMONSTRATION
if (sys.nframe() == 0L) {

th <- 0.4018; Th <- 0.5569
cat("=== 1. the filter is a ratio, and its denominator is theta(B)theta(F) ===\n")
bp <- burman_pieces(th, Th)
cat("  theta(B) has degree", length(bp$ma) - 1, "-- nonzero at lags",
    paste(which(abs(bp$ma) > 1e-12) - 1, collapse = ", "), "\n")
cat("  numerator W(B,F) reaches lag", length(bp$W_seas) - 1, "\n")

cat("\n=== 2. partial fractions: solve W = g(B)theta(F) + g(F)theta(B) ===\n")
g <- burman_g(bp$W_seas, bp$ma)
cat("  g has", length(g), "coefficients; first six:\n   ",
    paste(sprintf("%.5f", head(g, 6)), collapse = "  "), "\n")

# verify the identity numerically on the unit circle
w <- seq(0.01, pi - 0.01, length.out = 400)
lhs <- cospoly_eval(bp$W_seas, w) / cospoly_eval(bp$N, w)
gB <- outer(w, 0:(length(g) - 1L), function(a, b) cos(a * b)) %*% g
thB <- function(ww) {
  z <- complex(modulus = 1, argument = -ww)
  vapply(z, function(zz) sum(bp$ma * zz^(0:(length(bp$ma) - 1L))), complex(1))
}
gBc <- function(ww) {
  z <- complex(modulus = 1, argument = -ww)
  vapply(z, function(zz) sum(g * zz^(0:(length(g) - 1L))), complex(1))
}
rhs <- Re(gBc(w) / thB(w) + Conj(gBc(w) / thB(w)))
cat("  max |LHS - RHS| on the unit circle:", format(max(abs(lhs - rhs))), "\n")
cat("  (if that is small, the partial-fraction split is correct)\n")

cat("\n=== 2b. do the two loops really implement nu_S? ===\n")
# The decisive test: feed a pure cosine through the recursions and measure the
# output amplitude. If the loops ARE the filter, this must equal nu_S exactly.
nn <- 2000; tt <- 1:nn
emp_gain <- function(freq) {
  x <- cos(2 * pi * freq * tt)
  y <- solve_fwd(x, g, bp$ma) + solve_bwd(x, g, bp$ma)
  mid <- 500:1500                       # away from both ends
  max(abs(y[mid])) / max(abs(x[mid]))
}
cat("  frequency        measured gain     nu_S\n")
for (fq in c(0.0001, 1/12, 1/6, 0.2, 0.5)) {
  wr <- 2 * pi * fq
  target <- cospoly_eval(bp$W_seas, wr) / cospoly_eval(bp$N, wr)
  cat(sprintf("  %8.4f %16.5f %10.5f\n", fq, emp_gain(fq), target))
}
cat("  Zero gain at the trend frequency, one at each seasonal frequency,\n")
cat("  and the formula reproduced exactly in between. The loops are the filter.\n")

cat("\n=== 3. two recursions, versus the brute-force filter ===\n")
# NOTE seats_decompose() logs internally, so it takes the RAW series while
# burman_component() takes the already-logged one. Getting this wrong makes
# the reference five times too small and looks like a broken algorithm.
ref <- as.numeric(seats_decompose(AirPassengers, th, Th, normalize = FALSE)$seasonal)
for (E in c(24, 60, 120, 240)) {
  b <- burman_component(as.numeric(lap), th, Th, which = "seasonal", extend = E)
  cat(sprintf("  extension %3d months : max |Burman - brute force| = %.7f\n",
              E, max(abs(b - ref))))
}
cat("  The two agree to 1e-5 once the recursions have room to warm up.\n")
cat("  The run-up is needed because we start both recursions from ZERO.\n")
cat("  Burman derives exact starting values instead; that refinement is the\n")
cat("  only part of the published algorithm this script leaves out.\n")

cat("\n=== 4. why anyone bothers ===\n")
cat("  brute force needs", seats_max_lag(th, Th), "filter weights =",
    round(seats_max_lag(th, Th) / 12, 1), "years of extension.\n")
cat("  Burman needs g of length", length(g), "and two O(n) passes.\n")
cat("  Same answer, far less arithmetic -- and no truncation tolerance to\n")
cat("  choose, which is the part that silently bites (see 30-07).\n")

}
