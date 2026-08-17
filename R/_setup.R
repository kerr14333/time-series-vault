# _setup.R -- shared helpers. source() this at the top of every script.
#
# CONVENTION USED THROUGHOUT THIS VAULT: Census / Box-Jenkins.
#   phi(B)   = 1 - phi1 B - ... - phip B^p      (same as R)
#   theta(B) = 1 - th1 B  - ... - thq B^q       (OPPOSITE sign to stats::arima)
# See note 10-11-sign-conventions.

ma_r_to_census <- function(ma) -ma
ma_census_to_r <- function(ma) -ma

# Apply a polynomial in B, given as coefficients c(c0, c1, ..., cp) meaning
# c0 + c1*B + c2*B^2 + ..., to a series. Returns a ts with the first p values dropped.
apply_poly <- function(x, coef) {
  p <- length(coef) - 1L
  n <- length(x)
  out <- rep(NA_real_, n)
  for (t in seq.int(p + 1L, n)) out[t] <- sum(coef * x[t - (0:p)])
  y <- out[(p + 1L):n]
  if (is.ts(x)) ts(y, start = time(x)[p + 1L], frequency = frequency(x)) else y
}

# Multiply two polynomials in B given as coefficient vectors (c0 first).
poly_mult <- function(a, b) {
  out <- rep(0, length(a) + length(b) - 1L)
  for (i in seq_along(a)) for (j in seq_along(b)) out[i + j - 1L] <- out[i + j - 1L] + a[i] * b[j]
  out
}

# The differencing operator (1-B)^d (1-B^s)^D as a coefficient vector.
diff_poly <- function(d = 0, D = 0, s = 12) {
  p <- 1
  if (d > 0) for (i in seq_len(d)) p <- poly_mult(p, c(1, -1))
  if (D > 0) for (i in seq_len(D)) p <- poly_mult(p, c(1, rep(0, s - 1), -1))
  p
}

# Pretty-print a polynomial in B from a coefficient vector.
poly_show <- function(coef, var = "B") {
  terms <- character(0)
  for (k in seq_along(coef)) {
    cf <- coef[k]; pw <- k - 1L
    if (abs(cf) < 1e-12) next
    sgn <- if (cf < 0) " - " else if (length(terms)) " + " else ""
    val <- abs(cf)
    body <- if (pw == 0) format(val) else
      paste0(if (abs(val - 1) < 1e-12) "" else format(val),
             var, if (pw == 1) "" else paste0("^", pw))
    terms <- c(terms, paste0(sgn, body))
  }
  paste0(terms, collapse = "")
}

# Roots of a polynomial in B given c0-first coefficients, with moduli.
poly_roots <- function(coef) {
  r <- polyroot(coef)
  data.frame(root = r, modulus = round(Mod(r), 4),
             freq_rad = round(Arg(r), 4),
             period = ifelse(abs(Arg(r)) < 1e-9, Inf, round(2 * pi / abs(Arg(r)), 3)))
}

lap <- log(AirPassengers)   # the running example, logged
