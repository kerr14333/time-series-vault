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
poly_from_roots <- function(z) {
  p <- 1
  used <- rep(FALSE, length(z))
  for (i in seq_along(z)) {
    if (used[i]) next
    if (abs(Im(z[i])) < 1e-9) {                    # real root
      p <- poly_mult(p, c(1, -1 / Re(z[i])))
      used[i] <- TRUE
    } else {                                        # find its conjugate
      j <- which(!used & abs(Conj(z) - z[i]) < 1e-7 & seq_along(z) != i)
      if (!length(j)) stop("unpaired complex root -- polynomial is not real")
      j <- j[1]
      # (1 - B/z)(1 - B/zbar) = 1 - 2Re(1/z) B + |1/z|^2 B^2
      inv <- 1 / z[i]
      p <- poly_mult(p, c(1, -2 * Re(inv), Mod(inv)^2))
      used[i] <- TRUE; used[j] <- TRUE
    }
  }
  Re(p)
}

# ---- the classification itself ---------------------------------------------
# Returns the three AR polynomials plus a table of what went where, because
# the table is the part a reader needs to check.
# tol_trend is deliberately TIGHT. A first version used half the gap between
# seasonal frequencies for every class, which meant any cycle longer than 24
# months was called "trend" -- so the transitory component essentially never
# fired, defeating the point of the exercise. TRAMO-SEATS assigns only roots
# at frequency zero (real positive roots) to the trend; a complex pair at a
# three-year cycle is transitory, and belongs there.
seats_ar_split_general <- function(ar = numeric(0), sar = numeric(0),
                                   d = 0, D = 0, s = 12,
                                   tol_trend = 1e-3, tol_frac = 0.5) {
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

  z <- polyroot(full)
  w <- abs(Arg(z))                       # frequency of each root, radians
  seas_w <- 2 * pi * (1:(s %/% 2)) / s   # the seasonal frequencies
  tol <- tol_frac * (2 * pi / s)         # half the gap between them, by default

  lab <- character(length(z))
  for (i in seq_along(z)) {
    if (w[i] < tol_trend) {
      lab[i] <- "trend"
    } else if (min(abs(w[i] - seas_w)) < tol) {
      lab[i] <- "seasonal"
    } else {
      lab[i] <- "transitory"
    }
  }

  tab <- data.frame(
    modulus = round(Mod(z), 4),
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
                                    verbose = FALSE) {
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
  out$irregular <- ts(y - as.numeric(out$trend) - as.numeric(out$seasonal) -
                        as.numeric(out$transitory), start = start(x), frequency = s)
  out$table <- sp$table
  out$admissible <- cn$admissible
  out$residual <- pf$residual
  out
}
