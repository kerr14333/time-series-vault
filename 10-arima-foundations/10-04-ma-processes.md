---
aliases: [MA, Moving average process]
tags: [module-1]
---

# MA processes — finite memory of shocks

Code: [[code-10-04-ma-processes|`R/10-04-ma-processes.R`]]

$$z_t = \theta(B) a_t$$

In the Box–Jenkins convention used by Census/X-13 and by this vault:

$$\theta(B) = 1 - \theta_1 B - \cdots - \theta_q B^q \quad\Longleftrightarrow\quad z_t = a_t - \theta_1 a_{t-1} - \cdots - \theta_q a_{t-q}$$

> [!warning] R uses the opposite sign
> `stats::arima()` reports MA coefficients with a **plus**: $z_t = a_t + \theta_1^{R}a_{t-1}$. So $\theta^{\text{Census}} = -\theta^{R}$. This single minus sign has cost more debugging hours in this field than anything else. Full treatment: [[10-11-sign-conventions]].

## The mental picture

An MA($q$) has a memory of exactly $q$ periods and then **total amnesia**. A shock at time $t$ influences $z_t, \dots, z_{t+q}$ and then is gone, permanently. Contrast the AR echo in [[10-03-ar-processes]], which never fully dies.

That hard cutoff shows up directly in the ACF.

## ACF of MA(1)

$z_t = a_t - \theta a_{t-1}$.

$$\gamma_0 = (1+\theta^2)\sigma_a^2,\qquad \gamma_1 = -\theta\,\sigma_a^2,\qquad \gamma_k = 0 \ \ (k \ge 2)$$

$$\rho_1 = \frac{-\theta}{1+\theta^2}, \qquad \rho_k = 0 \ \ (k\ge2)$$

Two things fall out and both matter later:

**(a) The ACF truncates at lag $q$.** $z_t$ and $z_{t-2}$ share no shock, so their covariance is exactly zero. This is the identifying signature:

|  | ACF | PACF |
|---|---|---|
| MA($q$) | **cuts off after lag $q$** | decays |

**(b) $|\rho_1| \le 1/2$ for any MA(1).** Maximised at $\theta = \pm 1$. So if a differenced series shows $\rho_1 = -0.8$, no MA(1) can fit it — the model is wrong, not the estimate. Useful sanity check.

## The non-uniqueness that motivates invertibility

$\rho_1 = -\theta/(1+\theta^2)$ is unchanged if you replace $\theta$ by $1/\theta$:

$$\frac{-1/\theta}{1 + 1/\theta^2} = \frac{-\theta}{\theta^2+1}$$

So $\theta = 0.5$ and $\theta = 2$ give the **identical autocorrelation function**, hence the identical Gaussian likelihood shape in terms of ACF — the data cannot tell them apart from second moments alone. Two models, one ACF. You need a rule to pick.

That rule is invertibility: [[10-05-invertibility]]. Read it next; this is the setup for it.

## Why MA is the natural language for differenced data

Differencing a series usually *creates* MA structure. Concretely: if $z_t$ is a random walk plus independent noise (a signal-plus-noise model, exactly the situation in seasonal adjustment), then $(1-B)z_t$ is an MA(1) with negative $\rho_1$. So the "difference-then-MA" shape of the airline model is not an arbitrary choice — it is what unobserved-components structure looks like after differencing. That equivalence *is* the bridge to SEATS. See [[10-10-airline-model]] and [[40-00-seats-map]].

## Numerically

The defining feature of an MA is that the ACF **stops**.

An MA(1) has exactly one nonzero autocorrelation, $\rho_1 = -\theta/(1+\theta^2)$ in Census sign. Everything past lag 1 is zero:

<!-- run -->
```r
set.seed(2)
x <- arima.sim(list(ma = -0.6), n = 4000)     # R sign; Census theta = +0.6
th <- 0.6
round(rbind(sample = acf(x, lag.max = 5, plot = FALSE)$acf[-1],
            theory = c(-th / (1 + th^2), 0, 0, 0, 0)), 3)
```
```text
         [,1]  [,2]   [,3]  [,4]   [,5]
sample -0.442 0.014 -0.024 0.026 -0.031
theory -0.441 0.000  0.000 0.000  0.000
```
<!-- end -->

The ceiling nobody expects: an MA(1) autocorrelation can never exceed 0.5 in magnitude, whatever $\theta$ is.

<!-- run -->
```r
th <- seq(-3, 3, by = 0.5)
round(rbind(theta = th, rho1 = -th / (1 + th^2)), 3)
```
```text
      [,1]   [,2] [,3]   [,4] [,5] [,6] [,7] [,8] [,9]  [,10] [,11]  [,12]
theta -3.0 -2.500 -2.0 -1.500 -1.0 -0.5    0  0.5  1.0  1.500   2.0  2.500
rho1   0.3  0.345  0.4  0.462  0.5  0.4    0 -0.4 -0.5 -0.462  -0.4 -0.345
      [,13]
theta   3.0
rho1   -0.3
```
<!-- end -->

## Exercises

*Solutions: [[solutions#10-04-ma-processes|worked answers]] in the solutions appendix.*

1. Plot $\rho_1(\theta)$ for $\theta \in [-3, 3]$. Mark the pair $(0.5, 2)$.
2. Simulate MA(2) and confirm the ACF dies after lag 2 while the PACF does not.
3. Simulate a random walk plus white noise, difference it, and look at the ACF. Which MA order does it look like? Is $\rho_1$ positive or negative? Why must it be that sign?

> [!abstract] Derivation
> - [[derivations#D2. The MA(1) autocorrelation, and why it cannot exceed one half|the ACF, the cut-off, and the 0.5 ceiling]]

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** An MA(2) has $\theta_1 = \theta_2 = 0.5$. Before computing, is $\rho_1$ positive or negative? Now compute both $\rho_1$ and $\rho_2$.
2. **Break it.** Try to construct an MA(1) with $\rho_1 = 0.8$. Show why you cannot, and state the ceiling.
3. **Transfer.** Differencing a random walk gives white noise. Difference it *twice* and identify the resulting MA order and sign of $\rho_1$.

## Practice set

*Drills, output-reading and judgement calls. Short answers; the point is fluency and knowing what you are looking at.*

1. **Drill.** Compute $\rho_1$ for $\theta = 0.1, 0.5, 1.0, 2.0$ and confirm the ceiling.
2. **Drill.** For MA(2) with $\theta_1 = 0.4, \theta_2 = 0.2$, compute $\rho_1$, $\rho_2$, $\rho_3$.
3. **Read it.** A sample ACF shows 0.45 at lag 1 and nothing beyond. Which model, and what is $\theta$ roughly?
4. **Judgement.** A sample ACF shows 0.7 at lag 1 and nothing beyond. What does that rule out?

## Links

- Prev: [[10-03-ar-processes]] · Next: [[10-05-invertibility]]
