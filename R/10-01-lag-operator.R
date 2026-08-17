# 10-01 -- The lag operator B is just algebra.
source("R/_setup.R")

# (1-B)(1-B^12) expanded ----------------------------------------------------
p <- poly_mult(c(1, -1), c(1, rep(0, 11), -1))
cat("(1-B)(1-B^12) =", poly_show(p), "\n")
# 1 - B - B^12 + B^13  ->  z_t - z_{t-1} - z_{t-12} + z_{t-13}

# ORDER DOES NOT MATTER -- polynomial multiplication commutes -----------------
a <- diff(diff(lap, lag = 1), lag = 12)
b <- diff(diff(lap, lag = 12), lag = 1)
cat("max abs difference between the two orders:", max(abs(a - b)), "\n")   # 0

# ...and applying the expanded polynomial directly gives the same thing ------
c_direct <- apply_poly(lap, p)
cat("expanded-polynomial route matches:", max(abs(c_direct - a)) < 1e-12, "\n")

# Division as a geometric series --------------------------------------------
# 1/(1 - 0.8B) = 1 + 0.8B + 0.64B^2 + ...
phi <- 0.8
psi <- phi^(0:9)
cat("\nweights of 1/(1-0.8B):\n"); print(round(psi, 4))
cat("weight on a shock 5 periods ago:", round(psi[6], 4), "\n")

# check: multiplying back by (1-0.8B) should leave 1, 0, 0, ...
cat("\n(1-0.8B) * psi(B) =", poly_show(round(poly_mult(c(1, -phi), psi), 10)), "\n")

# B kills nothing constant, and (1-B) does -----------------------------------
tt <- 1:50
cat("\n(1-B) applied to 5 + 2t gives constant:", unique(round(apply_poly(5 + 2 * tt, c(1, -1)), 10)), "\n")
cat("(1-B)^2 applied to 5 + 2t gives:", unique(round(apply_poly(5 + 2 * tt, diff_poly(d = 2)), 10)), "\n")

# EXERCISE 2: 1 - B^12 = (1-B)(1 + B + ... + B^11)
S <- rep(1, 12)
cat("\n(1-B)*S(B) =", poly_show(poly_mult(c(1, -1), S)), "\n")
