# Changelog

## Unreleased

- No changes yet.

## 0.9.0 - 2026-02-09

- Added combinatorics structure operations to `:LatexSympyOp`:
  - `perm_group <order|orbits|is_transitive|stabilizer> [point]`
  - `prufer <encode|decode> [n]`
  - `gray <sequence|bin_to_gray|gray_to_bin> <value>`
- Added strict parser/backend validation for list-based permutation, edge, code, and binary-string contracts.
- Expanded automated test coverage:
  - full Lua suite (`make test`) now passes
  - release gate (`make test-ci`) remains green
- Reworked docs for clearer audience split:
  - `README.md` simplified for GitHub landing + quick install
  - `doc.md` expanded installation section (lazy.nvim, native packages, LazyVim)
  - `FEATURES.md` converted into exhaustive feature reference with examples
- Added explicit link paths in docs to:
  - `tests/manual_feature_checks.tex`
  - full installation section in `doc.md`
  - complete feature reference in `FEATURES.md`

## 0.8.1 - 2026-02-09

- Added `:LatexSympyPick[!]` command picker to browse and run all plugin commands.
- Added picker UX hardening:
  - optional text filter stage (`Category -> Filter -> Command`, disabled by default)
  - context-aware visibility for selection-required commands
  - guided arg prompts for arg-capable entries with raw fallback
  - picker rows now mark append-capable commands with `[append available]`
  - append-capable picker entries now prompt for apply mode (`Replace` / `Append (!)`)
  - trailing `!` in direct op/alias args is auto-converted to bang mode with a one-time syntax hint
  - configurable picker behavior:
    - `picker_filter_enabled`
    - `picker_filter_prompt`
    - `picker_show_unavailable`
    - `picker_guided_args`
    - `picker_guided_args_allow_raw`
- Added success-result notifications for result-producing math commands:
  - configurable via `notify_success` and `notify_success_max_chars`
  - includes command context + truncated result preview
- Added pluggable picker backend config:
  - `picker_backend = "vim_ui" | "auto" | "snacks"`
  - `picker_select` and `picker_input` callback overrides
- Added default visual keymap for picker:
  - `<leader>lp` (tex buffers only, respects existing mappings)
- Added full planned feature roadmap coverage through `:LatexSympyOp` and `/op`:
  - Algebra depth: `div`, `gcd`, `sqf`, `groebner`, `resultant`
  - Calculus add-ons: `summation`, `product`
  - Combinatorics: `binomial`, `perm`, `comb`, `partition`, `subsets`
  - Number theory expansion: `totient`, `mobius`, `divisors`
  - Logic: `logic_simplify`, `sat`
  - Matrix extras: `jordan`, `svd`, `cholesky`
  - Symbol assumptions: `symbol`, `symbols`, `symbols_reset`
  - Geometry: `geometry`, `intersect`, `tangent`, `similar`
  - Physics wrappers: `units`, `mechanics`, `quantum`, `optics`, `pauli`
  - Probability workflows: `dist`, `p`, `e`, `var`, `density`
- Added strict parser/backend contracts for each new op (arity, enums, types, required params).
- Added server session registries for symbol assumptions and probability distributions.
- Updated reset behavior to clear variances plus session symbol/distribution state.
- Expanded test coverage:
  - Python `/op` happy/error-path tests for new op families
  - Lua parser/completion tests for new syntax
  - smoke/parser scripts updated to assert new op registration/completion
- Synced docs and feature inventory:
  - `doc.md` command reference
  - `tests/manual_feature_checks.tex` runnable examples
  - `FEATURES.md` implemented/planned/backlog status update

## 0.2.1 - 2026-02-09

- Added `:LatexSympyRepeat[!]` to rerun the last advanced operation with current selection/range.
- Improved default UX:
  - default keymaps enabled for `tex` buffers
  - split prefixes for defaults (`<leader>l` visual, `<leader>x` normal)
  - routine info notifications disabled by default (`notify_info = false`)
- Fixed advanced-op payload compatibility:
  - Lua client now encodes empty op params as JSON object (`{}`)
  - server accepts legacy empty-list params (`[]`) and rejects non-empty list params
- Added/expanded docs:
  - concise capability-focused README
  - detailed usage guide in `doc.md`
  - manual feature check file in `tests/manual_feature_checks.tex`
- Added and updated regression tests for keymaps, params serialization, and op compatibility.

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
