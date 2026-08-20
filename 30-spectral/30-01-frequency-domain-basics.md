---
aliases: [Frequency domain, Frequency, Euler's formula]
tags: [module-3]
---

# Frequency-domain basics

Code: [[code-30-01-frequency-domain-basics|`R/30-01-frequency-domain-basics.R`]]

Everything so far has been in the **time domain**: what does today owe to yesterday. This module switches to the **frequency domain**: what mixture of cycles is this series made of. Same information, different coordinates — and in the new coordinates, seasonal adjustment becomes almost trivially statable.

## Two units, and the confusion between them

| Unit | Range | Period | Used by |
|---|---|---|---|
| **radians per period**, $\omega$ | $0$ to $\pi$ | $2\pi/\omega$ | theory, SEATS papers |
| **cycles per period**, $f$ | $0$ to $0.5$ | $1/f$ | R's `spec.pgram`, most plots |

$\omega = 2\pi f$. Both appear constantly and authors rarely say which they mean; the giveaway is the axis maximum, $\pi \approx 3.14$ versus $0.5$. This vault states the unit every time.

## The frequencies that matter for monthly data

| $k$ | $f = k/12$ | $\omega = 2\pi k/12$ | Period | Meaning |
|---|---|---|---|---|
| — | 0 | 0 | $\infty$ | **the trend** |
| 1 | 0.0833 | 0.524 | 12 months | the annual cycle |
| 2 | 0.1667 | 1.047 | 6 months | first harmonic |
| 3 | 0.25 | 1.571 | 4 months | |
| 4 | 0.3333 | 2.094 | 3 months | |
| 5 | 0.4167 | 2.618 | 2.4 months | |
| 6 | 0.5 | 3.142 | 2 months | **Nyquist** |

**Learn this table.** Every plot in Modules 3 to 5 has these six vertical lines on it, and "seasonality" means "power concentrated at exactly these frequencies".

### Quarterly data: two, not six

The count is not universal — it is $\lfloor s/2 \rfloor$ for period $s$. Monthly gives six; quarterly gives **two**:

| $k$ | $f = k/4$ | $\omega = 2\pi k/4$ | Period | Meaning |
|---|---|---|---|---|
| — | 0 | 0 | $\infty$ | **the trend** |
| 1 | 0.25 | 1.571 | 4 quarters | the annual cycle |
| 2 | 0.5 | 3.142 | 2 quarters | **Nyquist**, and seasonal |

This matters from Module 2 onward: `UKgas` and `JohnsonJohnson` are quarterly, and they are the two series that **fail** sliding spans in [[50-04-sliding-spans]]. Part of the reason is right here — a quarterly series has a quarter as many observations, and only two seasonal frequencies to pin the pattern down.

> [!warning] $f$ is per *sampling interval*, not per year
> $f = 0.25$ appears in **both** tables and means different things: four **months** for monthly data, four **quarters** — a full year — for quarterly. The frequency axis knows nothing about calendars. Always ask what one time unit is before reading a period off a spectrum.

Note also that for even $s$ the last seasonal frequency *is* the Nyquist frequency ($k = s/2$), which is why $\nu_S(\pi) = 1$ in [[40-06-wk-filters-for-the-airline-model]] rather than being some in-between value — $\omega = \pi$ is genuinely seasonal, not a boundary artefact.

Two facts about the endpoints:

- $\omega = 0$ is the trend. Not "low frequency" — literally zero frequency, an infinite-period cycle.
- $\omega = \pi$ is the **Nyquist frequency**, period 2, alternating up-down-up-down. Nothing faster is observable in monthly data: a cycle of period 1.5 months, sampled monthly, is indistinguishable from a slower one. That is **aliasing**, and it is why the axis stops at $\pi$.

## Why the seasonal has six frequencies, not one

A seasonal pattern is generally not a pure sine. It is any repeating shape with period 12 — and Fourier says an arbitrary period-12 shape decomposes into a sine of period 12 plus **harmonics** at periods 6, 4, 3, 2.4 and 2.

That is why $1 - B^{12}$ has twelve roots and not two ([[10-06-differencing]]), and why every seasonal filter has six notches and not one ([[20-05-the-x11-iteration]]). A sharp December spike needs the high harmonics; a smooth sinusoidal season barely uses them.

![[30-01-harmonics.png]]

A pure sine and a spikier period-12 shape. Both repeat annually; only the second needs the harmonics.

## Complex exponentials, if they are rusty

$$e^{i\theta} = \cos\theta + i\sin\theta$$

Read $e^{i\theta}$ as **a point on the unit circle at angle $\theta$**, and multiplying by it as **rotating by $\theta$**. Then $e^{-i\omega j}$ is "rotate backwards by $\omega$, $j$ times".

Why bother, when the data is real? Because a cycle has both an **amplitude** and a **phase**, and tracking two real numbers through algebra is miserable while tracking one complex number is easy. $|re^{i\varphi}| = r$ recovers the amplitude and $\arg$ recovers the phase, exactly the gain/phase split of [[20-01-moving-averages-as-filters]].

The three identities used in this module:

$$|e^{i\theta}| = 1, \qquad \overline{e^{i\theta}} = e^{-i\theta}, \qquad |w|^2 = w\bar w$$

The last one is the workhorse: $|\theta(e^{-i\omega})|^2 = \theta(e^{-i\omega})\,\theta(e^{i\omega})$, which in operator notation is written $\theta(B)\theta(F)$. **That is where the $B$ and $F$ pairing in SEATS comes from** — it is a squared modulus, nothing more exotic.

## The one substitution

Throughout Modules 3 and 4:

$$B \longrightarrow e^{-i\omega}$$

A polynomial in the lag operator becomes a complex-valued function of frequency. Filters, models and components all become ordinary functions you can plot. Everything else follows.

## Exercises

1. Plot $\sin(2\pi t/12)$ and $\sin(2\pi t/12) + 0.3\sin(2\pi t/3)$. Both are seasonal with period 12. Which needs harmonics?
2. Sample a cycle of period 1.5 months at monthly intervals. What period does it appear to have? (Aliasing.)
3. Confirm numerically that $|1 - 0.8e^{-i\omega}|^2 = (1-0.8e^{-i\omega})(1-0.8e^{i\omega})$ is real for every $\omega$.

## Links

- Next: [[30-02-spectral-density]]
- Foundations: [[20-01-moving-averages-as-filters]], [[10-06-differencing]]
