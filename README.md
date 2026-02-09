# Latex Sympy Calculator (Neovim)

`latex_sympy.nvim` evaluates selected LaTeX math using SymPy and writes the result back into your `.tex` buffer.

## What it can do

- Convert and simplify LaTeX math expressions.
- Replace selected expressions with computed results.
- Append computed results next to existing expressions.
- Run algebra operations (simplify, trigsimp, ratsimp, powsimp, apart, subs).
- Run calculus operations (solve, diff, integrate, limit, series).
- Run numeric, differential-equation, and system solving workflows.
- Run set/system solving workflows (solveset, linsolve, nonlinsolve, diophantine).
- Run matrix operations (det, inv, transpose, rank, eigenvals/eigenvects, nullspace, charpoly, LU, QR, rref).
- Run number-theory helpers (isprime, factorint, primerange).
- Evaluate numerically, factor, and expand expressions.
- Re-run the previous advanced operation on a new selection.
- Open a command picker with optional filter, guided args prompts, and raw fallback.
- Get concise success notifications with a truncated result preview after math commands.

## Example transformations

```latex
Input:  x^2 + 2x + 1
Output: \left(x + 1\right)^{2}
```

```latex
Input:  \frac{d}{dx}(x^3 + x)
Output: 3x^2 + 1
```

```latex
Input:  \int_0^1 x^2\,dx
Output: \frac{1}{3}
```

```latex
Input:  \frac{\sin(x)}{x}
Output: 1            % limit as x -> 0
```

```latex
Input:  \begin{bmatrix}1 & 2\\3 & 4\end{bmatrix}
Output: -2           % determinant
```

## Full documentation

For installation, configuration, command syntax, keybindings, and troubleshooting, see [`doc.md`](doc.md).

For implemented vs planned SymPy capabilities, see [`FEATURES.md`](FEATURES.md).
