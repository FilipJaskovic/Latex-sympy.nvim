# SymPy Feature Inventory

This file tracks what `latex_sympy.nvim` supports today and what is deferred.

## Implemented Features

| Category | Feature | User Entry | Backend Support | Since | Status | Notes |
|---|---|---|---|---|---|---|
| Core transforms | Equal/replace/numerical/factor/expand/rref | `:LatexSympyEqual`, `:LatexSympyReplace`, `:LatexSympyNumerical`, `:LatexSympyFactor`, `:LatexSympyExpand`, `:LatexSympyMatrixRREF` | `/latex`, `/numerical`, `/factor`, `/expand`, `/matrix-raw-echelon-form` | 0.1.0 | Implemented | Core selection transforms |
| Advanced op | Generic dispatcher and repeat | `:LatexSympyOp[!]`, `:LatexSympyRepeat[!]` | `/op` | 0.2.0 | Implemented | Replace/append flow with repeat |
| Algebra | simplify/trigsimp/ratsimp/powsimp/apart/subs | `LatexSympyOp simplify|trigsimp|ratsimp|powsimp|apart|subs` | `/op` | 0.3.1 | Implemented (unreleased) | Includes tokenized substitutions |
| Equation solving | solveset/linsolve/nonlinsolve/rsolve/diophantine/solve/solve_system/nsolve/dsolve | `LatexSympyOp solveset|linsolve|nonlinsolve|rsolve|diophantine|solve|solve_system|nsolve|dsolve` | `/op` | 0.4.0 | Implemented (unreleased) | Domain/arg validation included |
| Calculus | diff/integrate/limit/series/summation/product | `LatexSympyOp diff|integrate|limit|series|summation|product` | `/op` | 0.8.0 | Implemented (unreleased) | Includes chained diff and repeated integration bounds |
| Matrix | det/inv/transpose/rank/eigenvals/eigenvects/nullspace/charpoly/lu/qr/mat_solve/jordan/svd/cholesky | `LatexSympyOp ...` | `/op` | 0.8.0 | Implemented (unreleased) | Matrix input contracts enforced |
| Algebra depth | div/gcd/sqf/groebner/resultant | `LatexSympyOp div|gcd|sqf|groebner|resultant` | `/op` | 0.8.0 | Implemented (unreleased) | `div/gcd/resultant` use two-expression selection |
| Combinatorics | binomial/perm/comb/partition/subsets | `LatexSympyOp binomial|perm|comb|partition|subsets` | `/op` | 0.8.0 | Implemented (unreleased) | `subsets` works on finite list/set selection |
| Number theory | isprime/factorint/primerange/totient/mobius/divisors | `LatexSympyOp isprime|factorint|primerange|totient|mobius|divisors` | `/op` | 0.8.0 | Implemented (unreleased) | Integer/range validation included |
| Logic | simplify/cnf/dnf + satisfiable checks | `LatexSympyOp logic_simplify|sat` | `/op` | 0.8.0 | Implemented (unreleased) | `form`: `simplify|cnf|dnf` |
| Symbol assumptions | session symbol registration/list/reset | `LatexSympyOp symbol|symbols|symbols_reset` | `/op` | 0.8.0 | Implemented (unreleased) | Supports `commutative, real, integer, positive, nonnegative` |
| Geometry | geometry/intersect/tangent/similar | `LatexSympyOp geometry|intersect|tangent|similar` | `/op` | 0.8.0 | Implemented (unreleased) | Constructor-based geometry parsing |
| Physics | units/mechanics/quantum/optics/pauli wrappers | `LatexSympyOp units|mechanics|quantum|optics|pauli` | `/op` | 0.8.0 | Implemented (unreleased) | Action-based subcommands per domain |
| Probability | dist registration + P/E/Var/density | `LatexSympyOp dist|p|e|var|density` | `/op` | 0.8.0 | Implemented (unreleased) | Session RV registry integrated |
| Core parser | Fallback parser hardening for function-heavy syntax | no API change | parser helpers + `/op` | 0.8.0 | Implemented (unreleased) | LaTeX parse with sympify fallback and module-aware locals |
| Symbol model | Noncommutative/assumption-aware symbols | `LatexSympyOp symbol x commutative=false` | `/op` | 0.8.0 | Implemented (unreleased) | Noncommutativity supported through assumptions |
| UX | Command picker | `:LatexSympyPick[!]` | Lua command layer | 0.8.1 | Implemented (unreleased) | All-command picker with pluggable backend (`vim_ui`, `auto`, `snacks`) |
| UX/Safety | startup once, stale-drop, timeout/preview controls, opt-in python eval | `setup({...})` + utility commands | Lua + `/python` gate | 0.2.x | Implemented | Minimal defaults with explicit opt-in risk surface |

## Planned Features

| Category | Feature | Planned Syntax | Priority | Target | Status | Notes |
|---|---|---|---|---|---|---|
| n/a | n/a | n/a | n/a | n/a | None | All previously planned roadmap rows are now implemented or moved to backlog |

## Maybe / Backlog

| Feature | Reason | Status |
|---|---|---|
| Rich expression history panel | Useful, but outside minimal plugin surface | Backlog |
| Additional alias commands for every op | Avoiding command surface bloat is still policy | Backlog |
| Permutation groups / Prufer / Gray codes | Lower demand vs current symbolic workflow priorities | Backlog |
| Cipher/crypto helpers | Implementable, but weak fit for latex-first symbolic workflow | Backlog |

## Policy

- Update this file in every feature PR.
- Sync `CHANGELOG.md`, `doc/news.txt`, and `doc.md` when status changes.
- Keep command surface minimal: extend `:LatexSympyOp` first, add aliases only by clear usage demand.
