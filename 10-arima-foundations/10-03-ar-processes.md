---
aliases: [AR, Autoregressive process]
tags: [module-1]
---

# AR processes — infinite echo

Code: [[code-10-03-ar-processes|`R/10-03-ar-processes.R`]]

$$\phi(B) z_t = a_t \quad\Longleftrightarrow\quad z_t = \phi_1 z_{t-1} + \cdots + \phi_p z_{t-p} + a_t$$

with $a_t$ white noise: mean 0, variance $\sigma_a^2$, uncorrelated across $t$.

## The mental picture

Today is a weighted memory of the recent past, plus a fresh shock. Because yesterday was itself a weighted memory of *its* past, a single shock echoes forever, decaying. Make that literal by inverting:

$$z_t = \frac{1}{\phi(B)}a_t = \psi(B)a_t = \sum_{j\ge 0}\psi_j a_{t-j}$$

For AR(1), $\psi_j = \phi^j$: the shock from $j$ periods ago still contributes $\phi^j$. With $\phi = 0.8$, a shock is at 33% after 5 periods and 11% after 10.

> **Every stationary AR is an MA($\infty$).** Hold onto this — it is half of [[10-08-arma-duality]].

## Autocovariances: the Yule–Walker equations

Multiply $z_t = \sum \phi_i z_{t-i} + a_t$ by $z_{t-k}$ and take expectations. Since $a_t$ is uncorrelated with anything dated $t-k$ for $k \ge 1$:

$$\gamma_k = \phi_1\gamma_{k-1} + \cdots + \phi_p\gamma_{k-p}, \qquad k \ge 1$$

Divide by $\gamma_0$:

$$\rho_k = \phi_1\rho_{k-1} + \cdots + \phi_p\rho_{k-p}$$

**The ACF of an AR obeys the same difference equation as the process itself.** So it decays the same way the process forgets — geometrically for real roots, as a damped sine wave for complex roots. It decays but never truncates.

For $k = 0$ you get the extra term $\sigma_a^2$, giving for AR(1): $\gamma_0 = \sigma_a^2/(1-\phi^2)$ and $\rho_k = \phi^{|k|}$.

## The identifying signature

|  | ACF | PACF |
|---|---|---|
| AR($p$) | decays (geometric or damped sine) | **cuts off after lag $p$** |

The PACF cutoff is the whole reason PACF exists. Details and the intuition in [[10-07-acf-and-pacf]].

## Complex roots → pseudo-cycles

An AR(2) with complex roots produces a damped oscillation of period $2\pi/\arccos\!\big(\phi_1/(2\sqrt{-\phi_2})\big)$. This matters for seasonal adjustment: a *stationary* AR(2) with a period near 12 gives a seasonal-ish wiggle that **wanders in amplitude and phase**, unlike a deterministic sine. Real seasonality behaves like this, which is exactly why deterministic seasonal dummies are usually the wrong model.

Play with this in the script — it is the most useful intuition in the note.

![[10-03-ar-paths.png]]

*Drawn by [[figure-index#10-03-ar-paths.png|`make-figures.R`]] — code and every other figure in the [[figure-index|figure appendix]].*

The same model at three values of $\phi$, same random seed. As $\phi \to 1$ the series stops returning to its mean promptly and starts wandering: at 0.5 it crosses zero constantly, at 0.99 it drifts for hundreds of periods at a time. Nothing about the *equation* changes — only one number — but the character of the data changes completely. That wandering is what a unit root looks like from the outside.

## Numerically

Watch the memory decay.

For an AR(1), the weight on a shock $j$ periods back is $\phi^j$. That is the whole model:

<!-- run -->
```r
psi <- function(phi, n = 10) phi^(0:n)
round(rbind(`phi=0.5` = psi(0.5), `phi=0.9` = psi(0.9)), 4)
```
```text
        [,1] [,2] [,3]  [,4]   [,5]   [,6]   [,7]   [,8]   [,9]  [,10]  [,11]
phi=0.5    1  0.5 0.25 0.125 0.0625 0.0312 0.0156 0.0078 0.0039 0.0020 0.0010
phi=0.9    1  0.9 0.81 0.729 0.6561 0.5905 0.5314 0.4783 0.4305 0.3874 0.3487
```
<!-- end -->

The theoretical ACF of an AR(1) is also $\phi^k$. Simulate and compare — this is the sanity check to build the habit of:

<!-- run -->
```r
set.seed(1)
x <- arima.sim(list(ar = 0.7), n = 2000)
round(rbind(sample = acf(x, lag.max = 6, plot = FALSE)$acf[-1],
            theory = 0.7^(1:6)), 3)
```
```text
        [,1]  [,2]  [,3] [,4]  [,5]  [,6]
sample 0.693 0.488 0.344 0.25 0.190 0.138
theory 0.700 0.490 0.343 0.24 0.168 0.118
```
<!-- end -->

## Exercises

*Solutions: [[solutions#10-03-ar-processes|worked answers]] in the solutions appendix.*

1. Simulate AR(1) with $\phi = 0.9$ and with $\phi = -0.9$. Describe both series in words before looking at the ACFs, then look.
2. AR(2) with $\phi_1 = 1.6,\ \phi_2 = -0.9$: find the roots, the implied period, and confirm it in a simulation.
3. Derive $\rho_1$ for AR(2) from the Yule–Walker equations. (Use $\rho_0 = 1$, $\rho_{-1} = \rho_1$.)

## Going further

*Harder, and different in kind: predict before you run, break things on purpose, and move the idea to a series it was not built on.*

1. **Predict first.** Sketch what you expect the ACF of an AR(2) with $\phi_1 = 0, \phi_2 = 0.8$ to look like, then compute it. Why does it have that shape?
2. **Break it.** Simulate an AR(1) with $|\phi| > 1$ for 100 points. What happens, and why is the stationarity condition not merely a technicality?
3. Fit an AR(1) to a series you simulated as AR(2). What $\phi$ comes back, and how does the residual ACF reveal the misspecification?

## Links

- Prev: [[10-02-stationarity-and-roots]] · Next: [[10-04-ma-processes]]
