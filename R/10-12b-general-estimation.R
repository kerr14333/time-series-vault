# 10-12b -- Exact ML for a GENERAL ARIMA, built from scratch.
#
# 10-12 explains estimation using the airline model, where there are two
# parameters and the likelihood surface can be drawn. This script does the
# general case: any (p,d,q)(P,D,Q)_s, via the state-space form and the Kalman
# filter, and checks the result against stats::arima().
#
# The whole thing is three ideas:
#   1. a seasonal ARIMA is an ordinary ARMA with mostly-zero coefficients
#   2. any ARMA can be written as a linear state-space model
#   3. the Kalman filter turns that into one-step errors, which ARE the likelihood
#
source("R/_setup.R")

# ---------------------------------------------------------------- 1. expand
# Multiply the seasonal polynomials out. phi(B)Phi(B^s) and theta(B)Theta(B^s).
# Coefficients here are in R's convention throughout: z = phi1 z(-1) + ... +
# a + ma1 a(-1) + ...  (Census signs are the negatives; see 10-11.)
expand_seasonal <- function(ar = numeric(0), ma = numeric(0),
                            sar = numeric(0), sma = numeric(0), s = 12) {
  # to polynomial form 1 - ar1 B - ...  so we can multiply, then back again
  ar_poly <- c(1, -ar)
  ma_poly <- c(1, ma)
  if (length(sar)) {
    sp <- c(1, rep(0, s - 1))
    for (i in seq_along(sar)) sp <- c(sp, rep(0, s - 1), -sar[i])
    sp <- c(1, unlist(lapply(seq_along(sar), function(i) c(rep(0, s - 1), -sar[i]))))
    ar_poly <- poly_mult(ar_poly, sp)
  }
  if (length(sma)) {
    sq <- c(1, unlist(lapply(seq_along(sma), function(i) c(rep(0, s - 1), sma[i]))))
    ma_poly <- poly_mult(ma_poly, sq)
  }
  list(ar = -ar_poly[-1], ma = ma_poly[-1])
}

# ------------------------------------------------------- 2. state-space form
# Harvey's form. r = max(p, q+1); the state carries the "unfinished business"
# of the MA part, which is why its dimension is not just p.
#
#        T = | phi_1  1  0 ... |      R = | 1      |      Z = (1, 0, ..., 0)
#            | phi_2  0  1 ... |          | ma_1   |
#            |  ...            |          | ...    |
#            | phi_r  0  0 ... |          | ma_r-1 |
#
arma_ss <- function(ar, ma) {
  p <- length(ar); q <- length(ma)
  r <- max(p, q + 1L)
  phi <- c(ar, rep(0, r - p))
  th  <- c(1, ma, rep(0, r - q - 1L))
  Tm <- matrix(0, r, r)
  Tm[, 1] <- phi
  if (r > 1L) Tm[seq_len(r - 1L), -1] <- diag(r - 1L)
  list(T = Tm, R = matrix(th[seq_len(r)], ncol = 1), r = r)
}

# Stationary initial covariance solves P = T P T' + R R'.  vec form:
#   vec(P) = (I - T (x) T)^{-1} vec(RR')
init_P <- function(T, R) {
  r <- nrow(T)
  A <- diag(r * r) - kronecker(T, T)
  P <- try(matrix(solve(A, as.vector(R %*% t(R))), r, r), silent = TRUE)
  if (inherits(P, "try-error")) diag(1e6, r) else P    # fall back to diffuse
}

# ------------------------------------------------- 3. the Kalman likelihood
# Returns the CONCENTRATED log-likelihood: sigma^2 is solved for, not searched.
kalman_loglik <- function(y, ar, ma, verbose = FALSE) {
  ss <- arma_ss(ar, ma); Tm <- ss$T; Rm <- ss$R; r <- ss$r
  a <- matrix(0, r, 1)
  P <- init_P(Tm, Rm)
  n <- length(y)
  ssq <- 0; sumlogF <- 0
  for (t in seq_len(n)) {
    # predict
    a <- Tm %*% a
    P <- Tm %*% P %*% t(Tm) + Rm %*% t(Rm)
    # one-step error and its variance (Z picks the first element)
    v <- y[t] - a[1, 1]
    F <- P[1, 1]
    if (!is.finite(F) || F <= 0) return(list(loglik = -Inf, sigma2 = NA))
    ssq     <- ssq + v * v / F
    sumlogF <- sumlogF + log(F)
    # update
    K <- P[, 1, drop = FALSE] / F
    a <- a + K * v
    P <- P - K %*% P[1, , drop = FALSE]
  }
  s2 <- ssq / n                                  # concentrated sigma^2
  ll <- -0.5 * (n * log(2 * pi * s2) + sumlogF + n)
  if (verbose) cat(sprintf("  n=%d  sigma2=%.6f  loglik=%.4f\n", n, s2, ll))
  list(loglik = ll, sigma2 = s2, n = n)
}

# Difference first, then it is a plain ARMA problem.
difference <- function(x, d = 0, D = 0, s = 12) {
  y <- as.numeric(x)
  if (D > 0) for (i in seq_len(D)) y <- diff(y, lag = s)
  if (d > 0) for (i in seq_len(d)) y <- diff(y, lag = 1)
  y
}

# ------------------------------------------------------------- 4. the fitter
fit_arima_ml <- function(x, order = c(0, 1, 1), seasonal = c(0, 1, 1), s = 12,
                         verbose = FALSE) {
  p <- order[1]; d <- order[2]; q <- order[3]
  P <- seasonal[1]; D <- seasonal[2]; Q <- seasonal[3]
  y <- difference(x, d, D, s)
  npar <- p + q + P + Q
  negll <- function(par) {
    ar  <- if (p) par[seq_len(p)] else numeric(0)
    ma  <- if (q) par[p + seq_len(q)] else numeric(0)
    sar <- if (P) par[p + q + seq_len(P)] else numeric(0)
    sma <- if (Q) par[p + q + P + seq_len(Q)] else numeric(0)
    e <- expand_seasonal(ar, ma, sar, sma, s)
    -kalman_loglik(y, e$ar, e$ma)$loglik
  }
  start <- rep(0.1, npar)
  opt <- optim(start, negll, method = "L-BFGS-B",
               lower = rep(-0.95, npar), upper = rep(0.95, npar),
               control = list(maxit = 400))
  ar  <- if (p) opt$par[seq_len(p)] else numeric(0)
  ma  <- if (q) opt$par[p + seq_len(q)] else numeric(0)
  sar <- if (P) opt$par[p + q + seq_len(P)] else numeric(0)
  sma <- if (Q) opt$par[p + q + P + seq_len(Q)] else numeric(0)
  e <- expand_seasonal(ar, ma, sar, sma, s)
  k <- kalman_loglik(y, e$ar, e$ma)
  list(par = opt$par, loglik = k$loglik, sigma2 = k$sigma2, n = k$n,
       order = order, seasonal = seasonal, convergence = opt$convergence)
}

# ============================================================== DEMONSTRATION
if (sys.nframe() == 0L) {

cat("=== 1. a seasonal ARIMA is an ARMA with mostly-zero coefficients ===\n")
e <- expand_seasonal(ar = numeric(0), ma = -0.4018, sma = -0.5569, s = 12)
cat("airline (0,1,1)(0,1,1): the MA side has", length(e$ma), "coefficients,\n")
cat("of which nonzero:", sum(abs(e$ma) > 1e-12), "-- at lags",
    paste(which(abs(e$ma) > 1e-12), collapse = ", "), "\n")
cat("values:", paste(round(e$ma[abs(e$ma) > 1e-12], 4), collapse = "  "), "\n\n")

cat("=== 2. does our Kalman likelihood match stats::arima()? ===\n")
cat("Evaluated at arima()'s own estimates -- so any gap is the LIKELIHOOD,\n")
cat("not the optimiser.\n\n")

cases <- list(
  list(lab = "AirPassengers (0,1,1)(0,1,1)", x = lap, o = c(0,1,1), s = c(0,1,1)),
  list(lab = "AirPassengers (1,1,0)(0,1,1)", x = lap, o = c(1,1,0), s = c(0,1,1)),
  list(lab = "AirPassengers (2,1,1)(0,1,1)", x = lap, o = c(2,1,1), s = c(0,1,1)),
  list(lab = "log(UKgas)    (0,1,1)(0,1,1)4", x = log(UKgas), o = c(0,1,1), s = c(0,1,1)),
  list(lab = "Nile          (0,1,1)",         x = Nile, o = c(0,1,1), s = c(0,0,0))
)

for (cs in cases) {
  freq <- if (identical(cs$s, c(0,0,0))) 12 else frequency(cs$x)
  fit <- try(arima(cs$x, order = cs$o,
                   seasonal = list(order = cs$s, period = freq),
                   method = "ML"), silent = TRUE)
  if (inherits(fit, "try-error")) { cat(sprintf("%-30s arima() failed\n", cs$lab)); next }
  co <- coef(fit)
  p <- cs$o[1]; q <- cs$o[3]; P <- cs$s[1]; Q <- cs$s[3]
  ar  <- if (p) co[seq_len(p)] else numeric(0)
  ma  <- if (q) co[p + seq_len(q)] else numeric(0)
  sar <- if (P) co[p + q + seq_len(P)] else numeric(0)
  sma <- if (Q) co[p + q + P + seq_len(Q)] else numeric(0)
  ee <- expand_seasonal(ar, ma, sar, sma, freq)
  y <- difference(cs$x, cs$o[2], cs$s[2], freq)
  k <- kalman_loglik(y, ee$ar, ee$ma)
  cat(sprintf("%-30s ours %10.4f   arima %10.4f   diff %.2e\n",
              cs$lab, k$loglik, fit$loglik, abs(k$loglik - fit$loglik)))
}

cat("\n=== 2b. the gap is R's diffuse prior, not our arithmetic ===\n")
# arima() runs the filter on the UNDIFFERENCED series, carrying the
# differencing in the state with a diffuse prior of variance kappa (default
# 1e6). That is an approximation of order 1/kappa. We difference first and use
# the exact stationary initialisation, so we should be the limit it converges
# to. Test it.
refc <- arima(lap, order = c(0,1,1), seasonal = list(order = c(0,1,1), period = 12),
              method = "ML")
coc <- coef(refc)
ec <- expand_seasonal(ma = coc[1], sma = coc[2], s = 12)
yc <- difference(lap, 1, 1, 12)
ours <- kalman_loglik(yc, ec$ar, ec$ma)$loglik
cat(sprintf("  ours (exact stationary init) : %.8f\n", ours))
for (kp in c(1e6, 1e8, 1e10, 1e12)) {
  f <- arima(lap, order = c(0,1,1), seasonal = list(order = c(0,1,1), period = 12),
             method = "ML", fixed = coc, transform.pars = FALSE, kappa = kp)
  cat(sprintf("  arima kappa = %-6.0e      : %.8f   gap %+.2e\n",
              kp, f$loglik, f$loglik - ours))
}
cat("  The gap falls by 100x when kappa rises by 100x -- it is O(1/kappa),\n")
cat("  exactly as a diffuse approximation should. By 1e10 it has converged on\n")
cat("  our value; by 1e12 it is WORSE, because a huge prior variance costs\n")
cat("  floating-point precision. The error is U-shaped in kappa.\n")

cat("\n=== 2c. the recursions, step by step, for the airline model ===\n")
ssA <- arma_ss(ec$ar, ec$ma)
cat(sprintf("  after differencing the airline model is ARMA(0,13), so r = %d\n", ssA$r))
cat("  T is the shift matrix (all phi are zero): T[i,i+1] = 1, first column 0\n")
cat("  Z = (1, 0, ..., 0)   picks the first state element\n")
cat("  R = (1, ma_1, ..., ma_13)' =\n     ",
    paste(sprintf("%.4f", as.vector(ssA$R)), collapse = " "), "\n")
P0A <- init_P(ssA$T, ssA$R)
cat(sprintf("  P0[1,1] = %.6f   (solves P = T P T' + RR')\n", P0A[1, 1]))
cat("\n   t      y_t    a_pred      v_t       F_t      K_1   cum ssq  cum logF\n")
{
  Tm <- ssA$T; Rm <- ssA$R; r <- ssA$r
  a <- matrix(0, r, 1); P <- P0A
  ssq <- 0; sumlogF <- 0
  for (t in seq_len(8)) {
    a <- Tm %*% a
    P <- Tm %*% P %*% t(Tm) + Rm %*% t(Rm)
    v <- yc[t] - a[1, 1]; F <- P[1, 1]
    ssq <- ssq + v * v / F; sumlogF <- sumlogF + log(F)
    K <- P[, 1, drop = FALSE] / F
    cat(sprintf("  %2d  %8.5f  %8.5f  %8.5f  %8.5f  %7.4f  %8.4f  %8.4f\n",
                t, yc[t], a[1, 1], v, F, K[1, 1], ssq, sumlogF))
    a <- a + K * v
    P <- P - K %*% P[1, , drop = FALSE]
  }
}
cat("  K_1 is exactly 1 here: for a pure-MA state space the gain on the first\n")
cat("  element is P[1,1]/F = F/F. An AR part is what makes it differ.\n")
cat("  F_t starts above 1 and settles toward 1: early on the filter has little\n")
cat("  history, so its one-step forecasts are less certain. That transient IS\n")
cat("  the 'exact' in exact maximum likelihood -- CSS throws it away.\n")

cat("\n=== 3. and can we FIND the estimates ourselves? ===\n")
own <- fit_arima_ml(lap, order = c(0,1,1), seasonal = c(0,1,1), s = 12)
ref <- arima(lap, order = c(0,1,1), seasonal = list(order = c(0,1,1), period = 12),
             method = "ML")
cat("our optimiser :", paste(round(own$par, 4), collapse = "  "),
    sprintf(" loglik %.4f\n", own$loglik))
cat("stats::arima():", paste(round(coef(ref), 4), collapse = "  "),
    sprintf(" loglik %.4f\n", ref$loglik))
cat(sprintf("max |coefficient difference| = %.2e\n", max(abs(own$par - coef(ref)))))

cat("\n=== 4. the state dimension for a few models ===\n")
for (cs in list(c(1,0), c(0,1), c(2,2), c(1,13), c(3,1))) {
  ss <- arma_ss(rep(0.1, cs[1]), rep(0.1, cs[2]))
  cat(sprintf("  ARMA(%2d,%2d) -> state dimension r = max(p, q+1) = %2d\n",
              cs[1], cs[2], ss$r))
}
cat("An airline model after differencing is ARMA(0,13), so r = 14. The state\n")
cat("is large because the MA reaches back 13 periods, not because the AR does.\n")

}
