---
aliases: [AR, Autoregressive process]
tags: [module-1]
---

# AR processes — infinite echo

Code: `R/10-03-ar-processes.R`

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

## Exercises

1. Simulate AR(1) with $\phi = 0.9$ and with $\phi = -0.9$. Describe both series in words before looking at the ACFs, then look.
2. AR(2) with $\phi_1 = 1.6,\ \phi_2 = -0.9$: find the roots, the implied period, and confirm it in a simulation.
3. Derive $\rho_1$ for AR(2) from the Yule–Walker equations. (Use $\rho_0 = 1$, $\rho_{-1} = \rho_1$.)

## Links

- Prev: [[10-02-stationarity-and-roots]] · Next: [[10-04-ma-processes]]
