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

## Example LaTeX transformations

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
Input:  \begin{bmatrix}1 & 2\\3 & 4\end{bmatrix}
Output: -2
```

## More docs

- [Usage guide (`doc.md`)](./doc.md)
- [Complete feature reference (`FEATURES.md`)](./FEATURES.md)
