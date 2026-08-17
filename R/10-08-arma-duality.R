# 10-08 -- psi-weights, pi-weights, and common factors.
source("R/_setup.R")
set.seed(51)

phi <- 0.7; theta_census <- 0.4          # Census sign
theta_r <- ma_census_to_r(theta_census)  # = -0.4 for R's functions

# EXERCISE 1: psi-weights from phi(B) psi(B) = theta(B) ---------------------
# By hand, recursively: psi_0 = 1; psi_j = phi*psi_{j-1} - theta_j
psi_hand <- numeric(12); prev <- 1
for (j in 1:12) { psi_hand[j] <- phi * prev - (if (j == 1) theta_census else 0); prev <- psi_hand[j] }
psi_fun <- ARMAtoMA(ar = phi, ma = theta_r, 12)
cat("psi by hand:", round(psi_hand, 5), "\n")
cat("ARMAtoMA()  :", round(psi_fun, 5), "\n")
cat("match:", isTRUE(all.equal(psi_hand, psi_fun)), "\n")

# EXERCISE 2: pi-weights from theta(B) pi(B) = phi(B) -----------------------
# Same recursion with the roles swapped.
pi_hand <- numeric(12); prev <- 1
for (j in 1:12) { pi_hand[j] <- theta_census * prev - (if (j == 1) phi else 0); prev <- pi_hand[j] }
cat("\npi by hand :", round(pi_hand, 5), "\n")
cat("(the AR(inf) form: pi(B) z_t = a_t, i.e. how the past determines today's shock)\n")

op <- par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))
plot(1:12, psi_fun, type = "h", lwd = 3, col = "steelblue",
     main = "psi: what a shock does to the future", xlab = "lag", ylab = "")
plot(1:12, pi_hand, type = "h", lwd = 3, col = "firebrick",
     main = "pi: what the past says about today's shock", xlab = "lag", ylab = "")
par(op)

# EXERCISE 3: common factors ------------------------------------------------
x <- arima.sim(list(ar = 0.7, ma = -0.4), 400)
f11 <- arima(x, order = c(1, 0, 1), include.mean = FALSE)
f22 <- arima(x, order = c(2, 0, 2), include.mean = FALSE)
cat("\nARMA(1,1):\n"); print(round(coef(f11), 3)); cat("  se:", round(sqrt(diag(f11$var.coef)), 3), "\n")
cat("\nARMA(2,2) fitted to the SAME data:\n"); print(round(coef(f22), 3))
cat("  se:", round(sqrt(diag(f22$var.coef)), 3), "\n")

cf <- coef(f22)
cat("\nAR roots:\n"); print(poly_roots(c(1, -cf["ar1"], -cf["ar2"]))$root)
cat("MA roots:\n"); print(poly_roots(c(1,  cf["ma1"],  cf["ma2"]))$root)
cat("\nNear-identical AR and MA roots = a common factor = the model is over-ordered.\n")
cat("AICC-ish comparison: AIC(1,1) =", round(AIC(f11), 2), " AIC(2,2) =", round(AIC(f22), 2), "\n")
