# _x11.R -- X-11 building blocks, hand-coded. source() after _setup.R.
#
# Everything here is deliberately written out rather than pulled from a package,
# because the point of Module 2 is to see the filters.

# ---- applying a symmetric filter -------------------------------------------
# w is a vector of length 2m+1, centred: w[m+1] is the weight on the current obs.
symfilter <- function(x, w) {
  y <- stats::filter(x, w, method = "convolution", sides = 2)
  if (is.ts(x)) ts(as.numeric(y), start = start(x), frequency = frequency(x)) else as.numeric(y)
}

# Carry the first/last non-NA value outward. A crude stand-in for proper end
# filters -- which is exactly the point made in note 20-07.
na_fill_ends <- function(x) {
  v <- as.numeric(x)
  ok <- which(!is.na(v))
  if (!length(ok)) return(x)
  if (ok[1] > 1) v[1:(ok[1] - 1)] <- v[ok[1]]
  n <- length(v)
  if (tail(ok, 1) < n) v[(tail(ok, 1) + 1):n] <- v[tail(ok, 1)]
  if (is.ts(x)) ts(v, start = start(x), frequency = frequency(x)) else v
}

# ---- the filters -----------------------------------------------------------

# centred 12-term MA: (1/24)(1,2,2,...,2,1)
ma_2x12 <- function() c(1, rep(2, 11), 1) / 24

# Henderson weights, closed form. len must be odd.
# For a (2m+1)-term filter, with n = m+2:
#   w_j ~ 315[(n-1)^2-j^2][n^2-j^2][(n+1)^2-j^2][3n^2-16-11j^2]
#         / (8n(n^2-1)(4n^2-1)(4n^2-9)(4n^2-25))
henderson <- function(len) {
  stopifnot(len %% 2 == 1, len >= 5)
  m <- (len - 1) / 2
  n <- m + 2
  j <- -m:m
  num <- 315 * ((n - 1)^2 - j^2) * (n^2 - j^2) * ((n + 1)^2 - j^2) * (3 * n^2 - 16 - 11 * j^2)
  den <- 8 * n * (n^2 - 1) * (4 * n^2 - 1) * (4 * n^2 - 9) * (4 * n^2 - 25)
  num / den
}

# seasonal MAs: p x q means a p-term MA of a q-term MA
seasonal_ma <- function(type = c("3x3", "3x5", "3x9", "3x15")) {
  type <- match.arg(type)
  q <- as.integer(sub("^3x", "", type))
  poly_mult(rep(1, 3) / 3, rep(1, q) / q)
}

# ---- frequency response ----------------------------------------------------
# freq in cycles per period (0 to 0.5). Returns the complex transfer function.
transfer <- function(w, freq = seq(0, 0.5, length.out = 501)) {
  m <- (length(w) - 1) / 2
  j <- -m:m
  sapply(freq, function(f) sum(w * exp(-2i * pi * f * j)))
}
gain  <- function(w, freq = seq(0, 0.5, length.out = 501)) Mod(transfer(w, freq))
phase <- function(w, freq = seq(0, 0.5, length.out = 501)) Arg(transfer(w, freq))

SEAS_FREQ <- (1:6) / 12          # seasonal frequencies, cycles per month

# ---- the seasonal filter: smooth each calendar month across years ----------
seasonal_smooth <- function(si, w) {
  s   <- frequency(si)
  out <- si
  for (mth in 1:s) {
    idx <- seq(mth, length(si), by = s)
    v   <- as.numeric(si)[idx]
    sm  <- as.numeric(stats::filter(v, w, method = "convolution", sides = 2))
    ok  <- which(!is.na(sm))
    if (length(ok)) {                       # carry the ends outward
      if (ok[1] > 1) sm[1:(ok[1] - 1)] <- sm[ok[1]]
      if (tail(ok, 1) < length(sm)) sm[(tail(ok, 1) + 1):length(sm)] <- sm[tail(ok, 1)]
    }
    out[idx] <- sm
  }
  out
}

# ---- extreme-value weights (multiplicative irregular) ----------------------
# Returns a weight in [0,1] per observation. sigmalim defaults to X-11's (1.5, 2.5).
extreme_weights <- function(irr, sigmalim = c(1.5, 2.5)) {
  v <- as.numeric(irr)
  s <- sd(v - 1, na.rm = TRUE)
  d <- abs(v - 1) / s
  w <- rep(1, length(v))
  mid <- d >= sigmalim[1] & d <= sigmalim[2]
  w[mid] <- (sigmalim[2] - d[mid]) / (sigmalim[2] - sigmalim[1])
  w[d > sigmalim[2]] <- 0
  w[is.na(w)] <- 1
  w
}

# Replace downweighted points by a same-month average of surviving neighbours.
replace_extremes <- function(si, wts) {
  s <- frequency(si); v <- as.numeric(si); out <- v
  for (mth in 1:s) {
    idx <- seq(mth, length(v), by = s)
    vv  <- v[idx]; ww <- wts[idx]
    for (k in seq_along(vv)) {
      if (ww[k] < 1) {
        nb <- vv[max(1, k - 2):min(length(vv), k + 2)]
        nw <- ww[max(1, k - 2):min(length(vv), k + 2)]
        repl <- if (any(nw == 1)) mean(nb[nw == 1]) else mean(nb)
        out[idx[k]] <- ww[k] * vv[k] + (1 - ww[k]) * repl
      }
    }
  }
  ts(out, start = start(si), frequency = s)
}

# ---- I/C ratio and automatic Henderson length -----------------------------
# Both parts must be on the SAME scale. In the multiplicative case the irregular
# is a ratio around 1 while the trend is on the level scale, so compare PERCENT
# month-to-month changes for both. Mixing the two scales silently gives a tiny
# ratio and therefore always picks the shortest Henderson filter.
ic_ratio <- function(trend, irr) {
  ti <- as.numeric(trend); ii <- as.numeric(irr)
  cbar <- mean(abs(diff(ti) / head(ti, -1)), na.rm = TRUE)
  ibar <- mean(abs(diff(ii) / head(ii, -1)), na.rm = TRUE)
  ibar / cbar
}
henderson_length <- function(ic) if (ic < 1.0) 9L else if (ic < 3.5) 13L else 23L

# ---- the full X-11 loop ----------------------------------------------------
# Multiplicative only. Returns the D-tables.
x11_decompose <- function(z, sfilter1 = "3x3", sfilter2 = "3x5",
                          hlen = NULL, extreme = TRUE, verbose = FALSE) {
  w12 <- ma_2x12()

  # 1-2. crude trend, then SI ratios
  T1 <- na_fill_ends(symfilter(z, w12))
  SI <- z / T1

  # 3-4. first seasonal, centred
  S1 <- seasonal_smooth(SI, seasonal_ma(sfilter1))
  S1 <- S1 / na_fill_ends(symfilter(S1, w12))

  # 5-6. first adjusted series, then a proper Henderson trend
  A1 <- z / S1
  ic <- ic_ratio(T1, z / (T1 * S1))
  h  <- if (is.null(hlen)) henderson_length(ic) else hlen
  if (verbose) cat(sprintf("I/C ratio = %.2f  ->  %d-term Henderson\n", ic, h))
  T2 <- na_fill_ends(symfilter(A1, henderson(h)))

  # 7-8. better SI ratios; downweight extremes
  SI2 <- z / T2
  if (extreme) {
    wts <- extreme_weights(SI2 / seasonal_smooth(SI2, seasonal_ma(sfilter2)))
    SI2 <- replace_extremes(SI2, wts)
  } else wts <- rep(1, length(z))

  # 9-10. final seasonal, centred
  S2 <- seasonal_smooth(SI2, seasonal_ma(sfilter2))
  S2 <- S2 / na_fill_ends(symfilter(S2, w12))

  # 11-13. final tables. NOTE: D11 uses the ORIGINAL z, not the replaced series.
  D11 <- z / S2
  D12 <- na_fill_ends(symfilter(D11, henderson(h)))
  D13 <- D11 / D12

  list(d10 = S2, d11 = D11, d12 = D12, d13 = D13,
       henderson = h, ic = ic, weights = wts)
}
