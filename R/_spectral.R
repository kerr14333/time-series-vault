# _spectral.R -- frequency-domain helpers. source() after _setup.R.
#
# CONVENTION: polynomials are passed as FULL coefficient vectors, c0 first, in B.
#   phi(B) = 1 - 0.8B      ->  c(1, -0.8)
#   theta(B) = 1 - 0.4B    ->  c(1, -0.4)      [Census sign, see 10-11]
# Passing whole polynomials avoids every sign-convention argument.

# Evaluate a polynomial in B at B = exp(-i*omega). freq is in CYCLES per period.
poly_eval_freq <- function(coef, freq) {
  j <- seq_along(coef) - 1L
  sapply(freq, function(f) sum(coef * exp(-2i * pi * f * j)))
}

FREQ <- seq(0, 0.5, length.out = 1001)      # cycles per month

# Spectral density of an ARMA: (sigma2/2pi) |theta|^2 / |phi|^2.
# Returns Inf where phi has a root on the unit circle (a pseudo-spectrum).
arma_spectrum <- function(ma_poly = 1, ar_poly = 1, sigma2 = 1, freq = FREQ) {
  num <- Mod(poly_eval_freq(ma_poly, freq))^2
  den <- Mod(poly_eval_freq(ar_poly, freq))^2
  s <- (sigma2 / (2 * pi)) * num / den
  s[den < 1e-12] <- Inf
  s
}

# Theoretical spectrum from autocovariances -- the DEFINITION, for cross-checking
# the closed form above.
spectrum_from_acov <- function(gamma, freq = FREQ) {
  k <- seq_along(gamma) - 1L          # gamma[1] is gamma_0
  sapply(freq, function(f) {
    (1 / (2 * pi)) * (gamma[1] + 2 * sum(gamma[-1] * cos(2 * pi * f * k[-1])))
  })
}

# Squared gain of a filter given as a polynomial in B (one-sided) --------------
sq_gain_poly <- function(coef, freq = FREQ) Mod(poly_eval_freq(coef, freq))^2

# The airline model's polynomials --------------------------------------------
airline_ma <- function(theta, Theta) poly_mult(c(1, -theta), c(1, rep(0, 11), -Theta))
airline_ar <- function() diff_poly(d = 1, D = 1, s = 12)      # (1-B)(1-B^12)

# Wiener-Kolmogorov gain: the share of power belonging to the component -------
wk_gain <- function(f_component, f_total) {
  g <- f_component / f_total
  # both infinite at a shared pole -> the component owns all the power there
  g[!is.finite(f_component) & !is.finite(f_total)] <- 1
  g[is.finite(f_component) & !is.finite(f_total)]  <- 0
  g
}

# Filter weights from a symmetric transfer function, by numerical inversion.
# nu must be a real, even function of frequency sampled on [0, 0.5]; the weights
# are the Fourier coefficients, w_j = int nu(f) cos(2 pi f j) df over [-.5,.5],
# computed by the trapezoidal rule and doubled by evenness.
integrate_cos <- function(nu, freq, j) {
  y <- nu * cos(2 * pi * freq * j)
  2 * sum((head(y, -1) + tail(y, -1)) / 2 * diff(freq))
}
wk_weights <- function(nu, freq = FREQ, max_lag = 60) {
  sapply(0:max_lag, function(j) integrate_cos(nu, freq, j))
}

SEAS_F <- (1:6) / 12                 # seasonal frequencies, cycles per month
mark_seasonal_freq <- function(col = "firebrick") abline(v = SEAS_F, col = col, lty = 3)
