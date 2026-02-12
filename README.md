# Latex Sympy Calculator (Neovim)

`latex_sympy.nvim` lets you select LaTeX math inside a `.tex` file, run SymPy on it, and write the result back into the buffer.

It is built for day-to-day LaTeX editing in Neovim: quick transforms, advanced symbolic operations, matrix workflows, solver workflows, and a picker so you can run features without memorizing every command.

## What it does

- Evaluates and transforms selected LaTeX expressions.
- Supports replace mode and append mode (`!`) for most math operations.
- Covers algebra, calculus, equation solving, matrix operations, number theory, combinatorics, geometry, logic, physics helpers, and probability helpers.
- Includes a command picker (`:LatexSympyPick`) with descriptions and guided argument prompts.
- Loads only for `tex` buffers and starts the Python server on demand.

## Quick install (lazy.nvim)

```lua
{
  "FilipJaskovic/Latex-sympy.nvim",
  ft = "tex",
  opts = {},
}
```

For full installation options (native packages, LazyVim setup, requirements, and configuration), see:

- [Full installation and configuration](./doc.md#installation)

## Try all features quickly

Use the manual test file:

- [`tests/manual_feature_checks.tex`](./tests/manual_feature_checks.tex)

It contains ready-to-run selections for core commands, advanced ops, aliases, picker flow, and utilities.

## Example Workflows

All examples below show append mode (`!`) so result is written after the original expression.

### Core 1: Simplify

$$
x^2 + 2x + 1 = \left(x + 1\right)^2
$$

```latex
% Command: :LatexSympyOp! simplify
x^2 + 2x + 1 = \left(x + 1\right)^2
```

### Core 2: Derivative

$$
\frac{d}{dx}(x^3 + x) = 3x^2 + 1
$$

```latex
% Command: :LatexSympyOp! diff x
\frac{d}{dx}(x^3 + x) = 3x^2 + 1
```

### Core 3: Definite Integral

$$
\int_0^1 x^2\,dx = \frac{1}{3}
$$

```latex
% Command: :LatexSympyOp! integrate x 0 1
\int_0^1 x^2\,dx = \frac{1}{3}
```

### Core 4: Limit

$$
\lim_{x \to 0}\frac{\sin(x)}{x} = 1
$$

```latex
% Command: :LatexSympyOp! limit x 0 +-
\frac{\sin(x)}{x} = 1
```

### Advanced 1: Groebner Basis

$$
\{x^2 + y,\; x - y\} = \{x - y,\; y^2 + y\}
$$

```latex
% Command: :LatexSympyOp! groebner x y lex
% Select both lines together
x^2 + y
x - y
= \left\{x - y,\; y^2 + y\right\}
```

### Advanced 2: Nonlinear System Solve

$$
\{x^2 - 1 = 0,\; y - 2 = 0\} = \{(-1, 2),\; (1, 2)\}
$$

```latex
% Command: :LatexSympyOp! nonlinsolve x y
% Select both lines together
x^2 - 1 = 0
y - 2 = 0
= \left\{(-1, 2),\; (1, 2)\right\}
```

### Advanced 3: LU Decomposition

$$
\begin{bmatrix}
4 & 3 \\
6 & 3
\end{bmatrix}
=
L\,U,\quad
L=\begin{bmatrix}1 & 0\\ \frac{3}{2} & 1\end{bmatrix},\;
U=\begin{bmatrix}4 & 3\\ 0 & -\frac{3}{2}\end{bmatrix}
$$

```latex
% Command: :LatexSympyOp! lu
\begin{bmatrix}4 & 3\\6 & 3\end{bmatrix}
= \left(L=\begin{bmatrix}1 & 0\\ \frac{3}{2} & 1\end{bmatrix},\; U=\begin{bmatrix}4 & 3\\ 0 & -\frac{3}{2}\end{bmatrix}\right)
```

### Advanced 4: Geometry Intersection

$$
\mathrm{Line}((0,0),(1,1)) \cap \mathrm{Line}((0,1),(1,0))
= \{(\tfrac{1}{2},\tfrac{1}{2})\}
$$

```latex
% Command: :LatexSympyOp! intersect
% Select both lines together
Line(Point(0, 0), Point(1, 1))
Line(Point(0, 1), Point(1, 0))
= \left\{\left(\frac{1}{2},\frac{1}{2}\right)\right\}
```

### Advanced 5: Probability (distribution + query)

$$
P(X > 0) = \frac{1}{2}
$$

```latex
% Setup command: :LatexSympyOp dist normal X 0 1
% Then append command: :LatexSympyOp! p
X > 0 = \frac{1}{2}
```

### Advanced 6: Quantum Commutator

$$
A = AB - BA
$$

```latex
% Command: :LatexSympyOp! quantum commutator B
A = AB - BA
```

## More docs

- [Usage guide (`doc.md`)](./doc.md)
- [Complete feature reference (`FEATURES.md`)](./FEATURES.md)
