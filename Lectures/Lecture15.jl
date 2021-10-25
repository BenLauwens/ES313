### A Pluto.jl notebook ###
# v0.16.4

using Markdown
using InteractiveUtils

# ╔═╡ 6541fa72-1528-11eb-157a-a3e1f9aa82a0
md"""# Simulation of a Computer Network
## Router as a Queuing System

Delay/Jitter:
- Transmission
- Service
- Processing
- Waiting

Quality of Service:
- Realtime
- Lossless

Representation:
- ``A\left(t\right)``
- ``D\left(t\right)``
- ``W\left(t\right)``
- ``W_Q\left(t\right)``
- ``T_n``
- ``S_n``
- ``L_n``
- ``L_{Qn}``

## Little's Law

```math
\mathbb E\left[L\right]=\lambda\mathbb E\left[W\right]
```
```math
\mathbb E\left[L_Q\right]=\lambda\mathbb E\left[W_Q\right]
```

## Steady State Probabilities

```math
P_n=\lim_{t\rightarrow\infty}\mathbb P\left\{L(t)=n\right\}
```

Stability
```math
a_n=d_n
```

Poisson arrivals always see time averages (PASTA):
```math
P_n=a_n
```

## MM1

Exponential Arrivals / Exponential Services (``\lambda`` / ``\mu``)

Markov Chain

A technical remark: if one event occurs at an exponential rate ``\lambda``, and another independent event at an exponential rate ``\mu``, then together they occur at an exponential rate ``\lambda+\mu``.

Steady State

```math
\begin{cases}
P_0=1-\frac{\lambda}{\mu}\\
P_n=\left(1-\frac{\lambda}{\mu}\right)\left(\frac{\lambda}{\mu}\right)^n,\quad n>0
\end{cases}
```

```math
\mathbb E\left[L\right]=\frac{\lambda}{\mu-\lambda}
```

```math
\mathbb E\left[W\right]=\frac{1}{\lambda}\mathbb E\left[L\right]=\frac{1}{\mu-\lambda}
```

```math
\mathbb E\left[W_Q\right]=\mathbb E\left[W\right]-\mathbb E\left[S\right]=\frac{\lambda}{\mu\left(\mu-\lambda\right)}
```

```math
\mathbb E\left[L_Q\right]=\lambda\mathbb E\left[W_Q\right]=\frac{\lambda^2}{\mu\left(\mu-\lambda\right)}
```

Finite Capacity?

Exponential Arrivals?

Exponential Services?

Network of Queues?

## GG1

Virtual Waiting Time: ``V\left(t\right)``
```math
\mathbb E\left[V\right]=\lambda\mathbb E\left[S\right]E\left[W_Q\right]+\frac{\lambda}{2}\mathbb E\left[S^2\right]
```

## MG1

Pollaczek–Khintchine formula
```math
\mathbb E\left[W_Q\right] = \frac{\lambda\mathbb E\left[S^2\right]}{2\left(1-\lambda\mathbb E\left[S\right]\right)}
```

## Statistical Processing

Sample Mean and Sample Variance

```math
\bar X = \sum_{i=1}^n X_i
```

```math
\mathbb E\left[\bar X\right]= \mu
```

To determine the “worth” of ``\bar X`` as an estimator of the population mean ``\mu``, we consider its mean square error:
```math
\mathbb E\left[\left(\bar X - \mu\right)^2\right]= \frac{\sigma^2}{n}
```

```math
S^2=\frac{\sum_{i=1}^n\left(X-\bar x\right)^2}{n-1}
```

```math
\mathbb E\left[S^2\right]=\sigma^2
```

``n`` sufficient large: central limit theorema
```math
\mathbb P\left\{\left|X − \mu\right|>c\frac{\sigma}{\sqrt n}\right\} \approx \mathbb P\left\{\left|Z\right|>c\right\}
```
where ``Z`` is a standard normal

Runtime

Number of Runs

The Regenerative Approach

Stationnarity vs Ergodicity
"""

# ╔═╡ Cell order:
# ╟─6541fa72-1528-11eb-157a-a3e1f9aa82a0
