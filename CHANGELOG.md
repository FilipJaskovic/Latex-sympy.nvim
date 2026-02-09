# Changelog

## 0.2.0 - 2026-02-09

- Added generic operation command `:LatexSympyOp[!]` with calculus and matrix ops:
  - `solve`, `diff`, `integrate`, `limit`, `series`
  - `det`, `inv`, `transpose`, `rank`, `eigenvals`
- Added op aliases:
  - `:LatexSympySolve`
  - `:LatexSympyDiff`
  - `:LatexSympyIntegrate`
  - `:LatexSympyDet`
  - `:LatexSympyInv`
- Added reliability/config controls:
  - `timeout_ms`
  - `preview_before_apply`
  - `preview_max_chars`
  - `drop_stale_results`
- Added backend `/op` endpoint and kept existing endpoints backward compatible.
- Added/updated tests for new operations and default safety behavior.
- Hardening updates for release:
  - CI workflow for Python tests and Neovim smoke checks
  - HTTPS dependency clone URLs in `Makefile`
  - Release checklist documentation
  - No breaking runtime command/API changes in this milestone

## 0.1.0 - 2025-10-08

- Initial release of Latex Sympy Calculator (Neovim)
  - LaTeX to LaTeX via `latex2sympy2`
  - Numerical evaluation, factor, expand
  - Matrix RREF
  - Variances map, reset, toggle complex
  - Python eval
