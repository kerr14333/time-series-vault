# _seats_general.R -- SEATS for an arbitrary (p,d,q)(P,D,Q)_s model.
#
# _seats.R handles the airline model: the AR side is exactly (1-B)^2 S(B), so
# the trend/seasonal split is known in advance and hard-coded. That covers the
# running example and most published adjustments, but not the general case.
#
# Here the split is DISCOVERED instead. Build the full AR polynomial, find its
# roots, and sort each root into a component by the FREQUENCY it sits at:
#
#     omega ~ 0            -> trend
#     omega ~ 2 pi k / s   -> seasonal
#     anything else        -> TRANSITORY, a fourth component the airline
#                             model never produces
#
# The transitory component is the visible payoff. An AR root at, say, a
# three-year cycle belongs to neither the trend nor the seasonal, and forcing
# it into either (as _seats.R would) puts a business cycle in your trend.
#
# _seats.R is left alone: it is validated to 0.001% and half the vault depends
# on it. This file is additive.
source("R/_setup.R"); source("R/_spectral.R"); source("R/_seats.R")

# ---- rebuilding a polynomial from a subset of its roots --------------------
# For a polynomial in B with root z, the factor is (1 - B/z). Conjugate pairs
# must be kept together or the coefficients come out complex.
# Pairing is done by NEAREST conjugate, not by a distance threshold. A fixed
# threshold looks safe and is not: polyroot splits a repeated root into a
# cluster whose members sit ~1e-7 apart, which is far outside any tolerance
# tight enough to be meaningful, and the function then declares a perfectly
# real polynomial complex. A real polynomial's complex roots must pair up, so
# matching each to its closest available conjugate needs no tolerance at all.
poly_from_roots <- function(z) {
  p <- 1
  used <- rep(FALSE, length(z))
  for (i in seq_along(z)) {
    if (used[i]) next
    used[i] <- TRUE
    if (abs(Im(z[i])) < 1e-9) {                    # real root
      p <- poly_mult(p, c(1, -1 / Re(z[i])))
      next
    }
    cand <- which(!used)
    if (!length(cand)) stop("unpaired complex root -- polynomial is not real")
    j <- cand[which.min(abs(Conj(z[cand]) - z[i]))]
    used[j] <- TRUE
    # (1 - B/z)(1 - B/zbar) = 1 - 2Re(1/z) B + |1/z|^2 B^2, using the mean of
    # the pair so a split repeated root does not bias the factor.
    inv <- (1 / z[i] + Conj(1 / z[j])) / 2
    p <- poly_mult(p, c(1, -2 * Re(inv), Mod(inv)^2))
  }
  Re(p)
}

# ---- the classification itself ---------------------------------------------
# Returns the three AR polynomials plus a table of what went where, because
# the table is the part a reader needs to check.
#
# The rule below is X-13's own, read out of sigsub.f and then verified against
# the printed AR factorization for seven different root positions. Two things
# in it are not obvious, and an earlier version of this file got both wrong:
#
#   * MODULUS MATTERS, not just frequency. A root is only allowed into the
#     trend or the seasonal if the modulus of the INVERSE root is at least
#     rmod (default 0.5). A root far inside the unit circle dies out in a few
#     months; calling it "seasonal" because it happens to sit near 2 pi k / s
#     puts a three-month transient into the seasonal factors. X-13 sends it to
#     the transitory component instead.
#
#   * A COMPLEX PAIR WITHIN 15 DEGREES OF ZERO IS TREND. The window is
#     360 / (2 s) degrees, so for monthly data any cycle of 24 months or
#     longer joins the trend. That is deliberate: the component is the
#     TREND-CYCLE, and a business cycle belongs in it. An earlier version of
#     this file called that a bug and narrowed the window to frequency zero,
#     on the strength of an unchecked claim about TRAMO-SEATS. It disagreed
#     with X-13 at every low-frequency root. Verified here: 6, 9, 12 and 15
#     degrees go to the trend; 16.4 and 18 degrees go to the transitory.
#
# The seasonal window is TIGHT -- epsphi is 2 degrees, not half the 30-degree
# gap between seasonal frequencies. Seasonal unit roots sit exactly on those
# frequencies, so nothing is lost, and a wide window swallows cycles that are
# merely nearby.
#
# rmod_seasonal is the one piece not verified directly: X-13 raises the
# modulus bar to 0.9 for the seasonal when the model has no seasonal unit
# roots to anchor it (sigsub.f, RmodS). Reproduced here from D and sar.
seats_ar_split_general <- function(ar = numeric(0), sar = numeric(0),
                                   d = 0, D = 0, s = 12,
                                   rmod = 0.5, epsphi = 2,
                                   rmod_seasonal = NULL) {
  # full AR side: phi(B) Phi(B^s) (1-B)^d (1-B^s)^D
  full <- c(1)
  if (length(ar))  full <- poly_mult(full, c(1, -ar))
  if (length(sar)) {
    sp <- c(1, unlist(lapply(seq_along(sar), function(i) c(rep(0, s - 1), -sar[i]))))
    full <- poly_mult(full, sp)
  }
  for (i in seq_len(d)) full <- poly_mult(full, c(1, -1))
  for (i in seq_len(D)) full <- poly_mult(full, c(1, rep(0, s - 1), -1))

  if (length(full) <= 1L)
    return(list(trend = 1, seasonal = 1, transitory = 1, full = full,
                table = data.frame()))

  if (is.null(rmod_seasonal))
    rmod_seasonal <- if (D >= 1 || length(sar)) rmod else 0.9

  z   <- polyroot(full)
  zi  <- 1 / z                           # X-13 works with the inverse roots
  mod <- Mod(zi)                         # <= 1 for a stationary root
  w   <- abs(Arg(z))                     # frequency, radians
  deg <- w * 180 / pi
  k       <- 360 / s                     # gap between seasonal frequencies, degrees
  seas_dg <- k * (1:(s %/% 2))

  # Classify CONJUGATE PAIRS, not individual roots. Right on a boundary -- a
  # cycle of exactly 24 months sits exactly on the 15 degree line -- the two
  # members of a pair land either side of the test and the component
  # polynomial comes out complex. Pair first, decide once, label both.
  used <- rep(FALSE, length(z))
  grp <- list()
  for (i in seq_along(z)) {
    if (used[i]) next
    used[i] <- TRUE
    if (abs(Im(zi[i])) < 1e-9) { grp[[length(grp) + 1L]] <- i; next }
    cand <- which(!used)
    if (!length(cand)) stop("unpaired complex root -- AR polynomial is not real")
    j <- cand[which.min(abs(Conj(z[cand]) - z[i]))]
    used[j] <- TRUE
    grp[[length(grp) + 1L]] <- c(i, j)
  }

  lab <- character(length(z))
  for (g in grp) {
    m <- mean(mod[g]); a <- mean(deg[g])
    lab[g] <- if (length(g) == 1L) {
      if (Re(zi[g]) > 0) {                             # frequency 0
        if (m >= rmod) "trend" else "transitory"
      } else {                                         # frequency pi
        if (m >= rmod_seasonal) "seasonal" else "transitory"
      }
    } else if (m > rmod && a < k / 2) {                # cycle of >= 2s periods
      "trend"
    } else if (m >= rmod_seasonal && min(abs(a - seas_dg)) < epsphi) {
      "seasonal"
    } else {
      "transitory"
    }
  }

  tab <- data.frame(
    modulus = round(Mod(z), 4),
    inv_mod = round(mod, 4),
    freq_rad = round(w, 4),
    period = ifelse(w < 1e-8, Inf, round(2 * pi / pmax(w, 1e-12), 2)),
    component = lab, stringsAsFactors = FALSE)
  tab <- tab[order(tab$freq_rad), ]

  grab <- function(k) if (any(lab == k)) poly_from_roots(z[lab == k]) else 1
  list(trend = grab("trend"), seasonal = grab("seasonal"),
       transitory = grab("transitory"), full = full, table = tab)
}

# ---- N-way partial fractions -----------------------------------------------
# N(B,F) / [D1 D2 ... Dk] = sum_i Ai/Di + polynomial part.
# Same least-squares-on-a-frequency-grid trick as _seats.R, generalised to any
# number of denominators.
seats_partial_fractions_general <- function(ma_poly, ar_list, ngrid = 4000) {
  ar_list <- ar_list[vapply(ar_list, function(p) length(p) > 1L, logical(1))]
  N  <- cospoly_from_poly(ma_poly)
  Ds <- lapply(ar_list, cospoly_from_poly)
  Dall <- Reduce(cospoly_mult, Ds)

  nA <- vapply(Ds, function(D) length(D) - 1L, integer(1))   # deg Ai < deg Di
  degN <- length(N) - 1L
  nD <- degN - (length(Dall) - 1L) + 1L
  if (nD < 1L) nD <- 1L

  grid <- seq(0, pi, length.out = ngrid)
  # column block for numerator i: basis element times the OTHER denominators
  cols <- list()
  for (i in seq_along(Ds)) {
    others <- if (length(Ds) > 1L) Reduce(cospoly_mult, Ds[-i]) else c(1)
    ov <- cospoly_eval(others, grid)
    cols[[i]] <- vapply(0:(nA[i] - 1L), function(k)
      cospoly_eval(replace(numeric(nA[i]), k + 1L, 1), grid) * ov, numeric(ngrid))
  }
  colsD <- vapply(0:(nD - 1L), function(k)
    cospoly_eval(replace(numeric(nD), k + 1L, 1), grid) * cospoly_eval(Dall, grid),
    numeric(ngrid))

  X <- do.call(cbind, c(cols, list(colsD)))
  y <- cospoly_eval(N, grid)
  sol <- qr.solve(X, y)
  resid <- max(abs(X %*% sol - y))

  out <- list(N = N, D = Ds, Dall = Dall, residual = resid)
  at <- 0L
  out$A <- lapply(seq_along(Ds), function(i) {
    v <- sol[(at + 1L):(at + nA[i])]; at <<- at + nA[i]; v
  })
  out$Dc <- sol[(at + 1L):(at + nD)]
  out
}

# ---- canonical adjustment, N components ------------------------------------
seats_canonical_general <- function(pf, ngrid = 8000) {
  w <- seq(1e-6, pi - 1e-6, length.out = ngrid)
  g <- lapply(seq_along(pf$D), function(i)
    cospoly_eval(pf$A[[i]], w) / cospoly_eval(pf$D[[i]], w))
  gI <- cospoly_eval(pf$Dc, w)

  mins <- vapply(g, min, numeric(1))
  admissible <- all(mins > -1e-8) && min(gI) > -1e-8
  m <- pmax(0, mins)

  Acan <- lapply(seq_along(pf$D), function(i) {
    L <- max(length(pf$A[[i]]), length(pf$D[[i]]))
    pad0(pf$A[[i]], L) - m[i] * pad0(pf$D[[i]], L)
  })
  Dcan <- pf$Dc; Dcan[1] <- Dcan[1] + sum(m)

  c(pf, list(Acan = Acan, Dcan = Dcan, mins = mins, m = m,
             admissible = admissible, min_irr = min(gI)))
}

# ---- the filters -----------------------------------------------------------
# nu_i = Acan_i * (product of the OTHER denominators) / N.  Pole-free for the
# same reason as the airline case: the Di cancel and N has no unit roots.
seats_filters_general <- function(cn, w) {
  Nw <- cospoly_eval(cn$N, w)
  k <- length(cn$D)
  nu <- lapply(seq_len(k), function(i) {
    others <- if (k > 1L) Reduce(cospoly_mult, cn$D[-i]) else c(1)
    cospoly_eval(cn$Acan[[i]], w) * cospoly_eval(others, w) / Nw
  })
  nu$irregular <- cospoly_eval(cn$Dcan, w) * cospoly_eval(cn$Dall, w) / Nw
  nu
}

# ---- the whole thing -------------------------------------------------------
seats_decompose_general <- function(x, ar = numeric(0), ma = numeric(0),
                                    sar = numeric(0), sma = numeric(0),
                                    d = 1, D = 1, s = 12, logs = TRUE,
                                    max_lag = 400, extend = 420, ngrid = 8000,
                                    normalize = TRUE, verbose = FALSE) {
  stopifnot(extend >= max_lag)
  y <- as.numeric(x); if (logs) y <- log(y)

  # MA side: theta(B) Theta(B^s), Census signs
  mafull <- c(1)
  if (length(ma))  mafull <- poly_mult(mafull, c(1, -ma))
  if (length(sma)) {
    sq <- c(1, unlist(lapply(seq_along(sma), function(i) c(rep(0, s - 1), -sma[i]))))
    mafull <- poly_mult(mafull, sq)
  }

  sp <- seats_ar_split_general(ar, sar, d, D, s)
  if (verbose) { cat("AR roots and where they went:\n"); print(sp$table, row.names = FALSE) }

  parts <- list(trend = sp$trend, seasonal = sp$seasonal, transitory = sp$transitory)
  keep  <- names(parts)[vapply(parts, function(p) length(p) > 1L, logical(1))]
  pf <- seats_partial_fractions_general(mafull, parts[keep], ngrid = 4000)
  cn <- seats_canonical_general(pf, ngrid = ngrid)
  if (verbose)
    cat(sprintf("partial-fraction residual %.2e   admissible: %s\n",
                pf$residual, cn$admissible))

  wgrid <- seq(0, pi, length.out = ngrid)
  nu <- seats_filters_general(cn, wgrid)

  # extend with forecasts and backcasts from the same model
  ord <- c(length(ar), d, length(ma)); sord <- c(length(sar), D, length(sma))
  fit <- arima(y, order = ord, seasonal = list(order = sord, period = s),
               method = "ML")
  fc <- as.numeric(predict(fit, n.ahead = extend)$pred)
  bc <- rev(as.numeric(predict(
    arima(rev(y), order = ord, seasonal = list(order = sord, period = s),
          method = "ML"), n.ahead = extend)$pred))
  ext <- c(bc, y, fc)

  out <- list()
  for (i in seq_along(keep)) {
    wts <- filter_weights(nu[[i]], wgrid, max_lag = max_lag)
    full <- apply_sym_weights(ext, wts)
    out[[keep[i]]] <- ts(full[(extend + 1):(extend + length(y))],
                         start = start(x), frequency = s)
  }
  for (nm in setdiff(c("trend", "seasonal", "transitory"), keep))
    out[[nm]] <- ts(rep(0, length(y)), start = start(x), frequency = s)

  # NORMALISATION -- the same convention _seats.R uses, and it was missing here
  # until the decomposition was compared against X-13 on a non-airline model.
  # nu_S(0) = 0, so the seasonal filter annihilates any constant and the theory
  # cannot say whether that constant belongs to the trend or the seasonal.
  # X-13 normalises multiplicative factors to average 1 in LEVELS, which in
  # logs is a mean of about -var/2, not 0. Skip it and every component is off
  # by a pure constant: on `imp` that was 1.28%, with the SHAPE already correct
  # to 1e-6. A constant offset is the cheapest kind of disagreement to miss,
  # because it never shows up in a plot.
  if (normalize && logs) {
    shift <- log(mean(exp(as.numeric(out$seasonal))))
    out$seasonal <- out$seasonal - shift
    out$trend    <- out$trend + shift
  }

  out$irregular <- ts(y - as.numeric(out$trend) - as.numeric(out$seasonal) -
                        as.numeric(out$transitory), start = start(x), frequency = s)
  out$table <- sp$table
  out$admissible <- cn$admissible
  out$residual <- pf$residual
  out
}
