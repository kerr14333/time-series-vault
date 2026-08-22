# _seats.R -- the SEATS canonical decomposition, from scratch.
# source() after _setup.R and _spectral.R.
#
# THE IDEA IN SEVEN LINES
#   1. fit an ARIMA; split its AR side into trend and seasonal factors
#   2. write the pseudo-spectrum as N / (DT * DS)      [cosine polynomials]
#   3. partial fractions:  N = A*DS + C*DT + D*DT*DS
#      -> trend spectrum A/DT, seasonal C/DS, irregular the constant D
#   4. check all three are non-negative                 (admissibility)
#   5. canonical: subtract each component's minimum, give it to the irregular
#   6. Wiener-Kolmogorov filters: nu_T = (A - mT*DT)*DS / N, etc.
#   7. extend the series with forecasts, apply the symmetric filters
#
# Everything is done with REAL COSINE POLYNOMIALS. A real even function of
# frequency is written  p(w) = c0 + 2*sum_{k>=1} ck*cos(k w), stored as the
# vector (c0, c1, ..., cn). For a polynomial P(B), the cosine coefficients of
# |P(e^{-iw})|^2 are just the autocovariances of P -- see cospoly_from_poly.

# ---- cosine-polynomial arithmetic ------------------------------------------
cospoly_from_poly <- function(p) {
  n <- length(p) - 1L
  vapply(0:n, function(k) sum(p[1:(n + 1L - k)] * p[(1L + k):(n + 1L)]), numeric(1))
}
cospoly_eval <- function(cc, w) {
  k <- seq_along(cc) - 1L
  vapply(w, function(x) cc[1] + 2 * sum(cc[-1] * cos(x * k[-1])), numeric(1))
}
cospoly_mult <- function(a, b) {
  la <- c(rev(a[-1]), a[1], a[-1])
  lb <- c(rev(b[-1]), b[1], b[-1])
  lc <- as.numeric(stats::convolve(la, rev(lb), type = "open"))
  m  <- (length(lc) - 1L) / 2L
  lc[(m + 1L):length(lc)]
}
pad0 <- function(x, n) c(x, rep(0, n - length(x)))

# ---- step 1: split the AR side ---------------------------------------------
# For an airline-type model the differencing operator is (1-B)^d (1-B^s)^D.
# (1-B)(1-B^s) = (1-B)^2 * S(B) with S(B) = 1 + B + ... + B^{s-1}.
seats_ar_split <- function(d = 1, D = 1, s = 12, ar = numeric(0)) {
  trend <- 1
  for (i in seq_len(d + D)) trend <- poly_mult(trend, c(1, -1))   # (1-B)^(d+D)
  seas <- 1
  for (i in seq_len(D)) seas <- poly_mult(seas, rep(1, s))        # S(B)^D
  if (length(ar)) trend <- poly_mult(trend, c(1, -ar))            # stationary AR -> trend side
  list(trend = trend, seasonal = seas)
}

# ---- steps 2-4: the partial fraction ---------------------------------------
seats_partial_fractions <- function(ma_poly, ar_trend, ar_seas, ngrid = 4000) {
  N  <- cospoly_from_poly(ma_poly)
  DT <- cospoly_from_poly(ar_trend)
  DS <- cospoly_from_poly(ar_seas)
  DTDS <- cospoly_mult(DT, DS)

  degN <- length(N) - 1L
  nA <- length(DT) - 1L          # deg A < deg DT
  nC <- length(DS) - 1L          # deg C < deg DS
  nD <- degN - (length(DTDS) - 1L) + 1L
  if (nD < 1L) nD <- 1L

  grid <- seq(0, pi, length.out = ngrid)
  colsA <- vapply(0:(nA - 1L), function(k)
    cospoly_eval(replace(numeric(nA), k + 1L, 1), grid) * cospoly_eval(DS, grid),
    numeric(ngrid))
  colsC <- vapply(0:(nC - 1L), function(k)
    cospoly_eval(replace(numeric(nC), k + 1L, 1), grid) * cospoly_eval(DT, grid),
    numeric(ngrid))
  colsD <- vapply(0:(nD - 1L), function(k)
    cospoly_eval(replace(numeric(nD), k + 1L, 1), grid) * cospoly_eval(DTDS, grid),
    numeric(ngrid))

  X   <- cbind(colsA, colsC, colsD)
  y   <- cospoly_eval(N, grid)
  sol <- qr.solve(X, y)
  resid <- max(abs(X %*% sol - y))

  list(N = N, DT = DT, DS = DS,
       A = sol[1:nA],
       C = sol[(nA + 1L):(nA + nC)],
       Dc = sol[(nA + nC + 1L):(nA + nC + nD)],
       residual = resid)
}

# ---- step 5: the canonical adjustment --------------------------------------
seats_canonical <- function(pf, ngrid = 8000) {
  w  <- seq(1e-6, pi - 1e-6, length.out = ngrid)
  gT <- cospoly_eval(pf$A,  w) / cospoly_eval(pf$DT, w)
  gS <- cospoly_eval(pf$C,  w) / cospoly_eval(pf$DS, w)
  gI <- cospoly_eval(pf$Dc, w)

  admissible <- min(gT) > -1e-8 && min(gS) > -1e-8 && min(gI) > -1e-8
  mT <- max(0, min(gT)); mS <- max(0, min(gS))

  L1 <- max(length(pf$A), length(pf$DT))
  L2 <- max(length(pf$C), length(pf$DS))
  Acan <- pad0(pf$A, L1) - mT * pad0(pf$DT, L1)
  Ccan <- pad0(pf$C, L2) - mS * pad0(pf$DS, L2)
  Dcan <- pf$Dc; Dcan[1] <- Dcan[1] + mT + mS

  c(pf, list(Acan = Acan, Ccan = Ccan, Dcan = Dcan,
             mT = mT, mS = mS, admissible = admissible,
             min_gT = min(gT), min_gS = min(gS), min_gI = min(gI)))
}

# ---- step 6: the WK filters, as functions of frequency ---------------------
# nu_T = (A - mT DT) DS / N.  No denominator zeros: N has no roots on the
# circle when the model is invertible, so these are ordinary smooth functions.
seats_filters <- function(cn, w) {
  Nw  <- cospoly_eval(cn$N,  w)
  DTw <- cospoly_eval(cn$DT, w)
  DSw <- cospoly_eval(cn$DS, w)
  list(trend     = cospoly_eval(cn$Acan, w) * DSw / Nw,
       seasonal  = cospoly_eval(cn$Ccan, w) * DTw / Nw,
       irregular = cospoly_eval(cn$Dcan, w) * DTw * DSw / Nw)
}

# Filter weights: w_j = (1/pi) * int_0^pi nu(w) cos(j w) dw.
filter_weights <- function(nu, w, max_lag = 120) {
  vapply(0:max_lag, function(j) {
    y <- nu * cos(j * w)
    (1 / pi) * sum((head(y, -1) + tail(y, -1)) / 2 * diff(w))
  }, numeric(1))
}

# ---- step 7: apply to data -------------------------------------------------
apply_sym_weights <- function(x, wts) {
  full <- c(rev(wts[-1]), wts)
  as.numeric(stats::filter(x, full, method = "convolution", sides = 2))
}

# The whole thing, for an airline-type model on one series.
# How many lags before the WK weights are negligible?
#
# The seasonal filter's weights decay by roughly a factor of Theta per YEAR (the
# seasonal MA root governs them), so the required length is set by Theta and is
# not a fixed number. Theta = 0.56 needs ~24 years; Theta = 0.9 needs ~130. This
# is the "narrow notches require long filters" trade-off of 30-06, as an actual
# array length. Truncating too early leaves the weights summing to something
# other than nu(0), which shows up as a constant LEVEL OFFSET in the component.
seats_max_lag <- function(theta, Theta, s = 12, tol = 1e-7, cap = 600) {
  r <- max(abs(theta), abs(Theta), 0.1)
  per_period <- if (abs(Theta) >= abs(theta)) abs(Theta)^(1 / s) else abs(theta)
  n <- ceiling(log(tol) / log(max(per_period, 0.05)))
  min(max(n, 5 * s), cap)
}

seats_decompose <- function(x, theta, Theta, s = 12, logs = TRUE,
                            max_lag = seats_max_lag(theta, Theta, s),
                            extend = max_lag + s, ngrid = 8000,
                            normalize = TRUE) {
  # The symmetric filter spans 2*max_lag+1 terms, so the series must be extended
  # by at least max_lag on each side or the convolution has no valid range at
  # the original endpoints. Getting this wrong silently returns all NA.
  stopifnot(extend >= max_lag)
  y  <- if (logs) log(x) else x
  ma <- poly_mult(c(1, -theta), c(1, rep(0, s - 1), -Theta))
  sp <- seats_ar_split(d = 1, D = 1, s = s)
  pf <- seats_partial_fractions(ma, sp$trend, sp$seasonal)
  cn <- seats_canonical(pf)

  w  <- seq(1e-8, pi - 1e-8, length.out = ngrid)
  nu <- seats_filters(cn, w)
  wt <- lapply(nu, filter_weights, w = w, max_lag = max_lag)

  # extend with forecasts and backcasts from the same model
  fit  <- arima(y, c(0, 1, 1), list(order = c(0, 1, 1), period = s))
  fwd  <- as.numeric(predict(fit, n.ahead = extend)$pred)
  rev_ <- rev(as.numeric(y))
  fitb <- arima(ts(rev_, frequency = s), c(0, 1, 1), list(order = c(0, 1, 1), period = s))
  bwd  <- rev(as.numeric(predict(fitb, n.ahead = extend)$pred))
  ext  <- c(bwd, as.numeric(y), fwd)

  keep <- (extend + 1):(extend + length(y))
  out <- lapply(wt, function(ww) apply_sym_weights(ext, ww)[keep])

  # NORMALISATION. The seasonal filter has nu_S(0) = 0, so it annihilates any
  # constant: the theory cannot say whether a constant belongs to the trend or
  # to the seasonal. Some convention must fix it, and it is a presentation
  # choice, not part of the decomposition.
  #
  # X-13 normalises MULTIPLICATIVE factors to average 1 in LEVELS. In logs that
  # forces a mean of about -var/2, NOT 0 -- which is exactly the constant offset
  # you see if you skip this step (0.88% on AirPassengers). Match it.
  #
  # TWO factors are normalised, over TWO DIFFERENT SPANS, and the trend takes
  # both constants:
  #
  #   the SEASONAL  averages 1 over the first floor(n/s)*s observations
  #   the IRREGULAR averages 1 over the FULL span
  #
  # A partial final year holds some months and not others, so averaging the
  # seasonal over it weights those months twice; the irregular has no periodic
  # structure and loses nothing to a partial year. Both were read out of X-13's
  # own tables by looking for the value that is exactly 1.000000000.
  #
  # This file only ever sees series whose length is a multiple of s, so the
  # seasonal half changes nothing here. The IRREGULAR half was missing
  # altogether and was worth 0.01% on AirPassengers.
  if (normalize && logs) {
    k <- (length(out$seasonal) %/% s) * s
    if (k < s) k <- length(out$seasonal)
    sh_s <- log(mean(exp(out$seasonal[seq_len(k)])))
    sh_i <- log(mean(exp(out$irregular)))
    out$seasonal  <- out$seasonal - sh_s
    out$irregular <- out$irregular - sh_i
  }

  # THE TREND IS A RESIDUAL, not a filter output. X-13's own tables satisfy
  # log y = s12 + s10 + s13 to 9e-15, which is not something three independently
  # truncated filters do -- ours miss by 1e-5. So X-13 computes one component by
  # subtraction, and it has to be the trend, since the trend is the one carrying
  # the level.
  #
  # Taking it from the filter instead costs 0.0011% on AirPassengers and, worse,
  # gets WORSE as max_lag grows: 0.0009% at 250 lags, 0.0017% at 500, 0.0039% at
  # 1200. The seasonal and irregular filters have gain zero at frequency zero
  # and are immune; the trend filter has gain one there, so it integrates the
  # drift of an ever-longer forecast extension. "Longer is safer" is true for
  # two of the three components and false for this one. As a residual it is
  # 0.00003% and improves monotonically, like everything else.
  out$trend <- as.numeric(y) - out$seasonal - out$irregular

  mk <- function(v) ts(v, start = start(x), frequency = s)
  list(trend = mk(out$trend), seasonal = mk(out$seasonal), irregular = mk(out$irregular),
       sa = mk(as.numeric(y) - out$seasonal),
       weights = wt, filters = nu, freq = w, canon = cn, pf = pf, logs = logs)
}
