# Latex-sympy.nvim Complete Feature Reference

This document is the exhaustive feature reference.

It is intentionally dense and example-heavy. For a more practical walkthrough, use [`doc.md`](./doc.md).

Quick validation file for all major flows:

- [`tests/manual_feature_checks.tex`](./tests/manual_feature_checks.tex)

## Execution Model (applies to most features)

- Plugin activates only for `tex` filetype buffers.
- Most math commands use visual selection or an Ex range.
- Advanced operations run through `:LatexSympyOp[!]`.
- `!` means append mode (` = <result>`). Without `!`, result replaces the selection/range.
- Errors are shown as concise notifications.

## Domain Index

| Domain | Coverage | Primary entry | Notes |
|---|---|---|---|
| Core | Equal/replace/numerical/factor/expand/rref | Core commands | Fast transform workflow |
| Ops: Algebra | Simplify, decomposition, substitution, polynomial ops | `:LatexSympyOp` | Symbolic cleanup and algebra depth |
| Ops: Solvers | Equation, system, set, recurrence, DE, Diophantine | `:LatexSympyOp` | Explicit contracts by op |
| Ops: Calculus | Diff, integrate, limit, series, summation, product | `:LatexSympyOp` | Supports bounded and chained forms |
| Ops: Matrix | Matrix algebra/decomposition/solve | `:LatexSympyOp` | Matrix-only input where required |
| Ops: Number Theory + Combinatorics | Prime tools, counting, groups, Prufer, Gray | `:LatexSympyOp` | Integer/list contracts are strict |
| Ops: Logic + Symbols | Boolean simplify/SAT + symbol assumptions | `:LatexSympyOp` | Session-aware symbol registry |
| Ops: Geometry | Geometry object parsing and relations | `:LatexSympyOp` | Constructor-style object input |
| Ops: Physics | Units/mechanics/quantum/optics/pauli wrappers | `:LatexSympyOp` | Action subcommands per module |
| Ops: Probability | Distribution registry + P/E/Var/density | `:LatexSympyOp` | Session random variable registry |
| UX + Utilities | Picker, repeat, keymaps, server/state commands | Dedicated commands | Discovery, control, and diagnostics |

## Core Commands

| Feature | Syntax | Input contract | Output behavior | Example | Common edge/error |
|---|---|---|---|---|---|
| Equal | `:LatexSympyEqual` | Visual selection or range | Appends `= result` | Select `x^2+2x+1` -> `x^2+2x+1 = \left(x+1\right)^2` | Fails with no selection/range |
| Replace | `:LatexSympyReplace` | Visual selection or range | Replaces text | Select `\frac{d}{dx}(x^3+x)` -> `3x^2+1` | Fails with no selection/range |
| Numerical | `:LatexSympyNumerical` | Visual selection or range | Replaces with numeric eval | `\sin(\pi/4)+\sqrt{2}` | Non-numeric expressions may remain symbolic |
| Factor | `:LatexSympyFactor` | Visual selection or range | Replaces with factored form | `x^2+2x+1` -> `(x+1)^2` | Parse failures surface as errors |
| Expand | `:LatexSympyExpand` | Visual selection or range | Replaces with expanded form | `(x+1)^3` -> `x^3+3x^2+3x+1` | Parse failures surface as errors |
| Matrix RREF | `:LatexSympyMatrixRREF` | Matrix selection/range | Appends `\to <rref>` | `\begin{bmatrix}1&2\\3&4\end{bmatrix}` | Non-matrix input errors |

## Alias Commands (wrappers around `:LatexSympyOp`)

| Alias | Equivalent op form | Input contract | Output behavior | Example | Common edge/error |
|---|---|---|---|---|---|
| Solve alias | `:LatexSympySolve[!] [vars...]` -> `solve` | Selection/range | Replace or append | `:LatexSympySolve x` on `x^2-1=0` | Same parser rules as `solve` |
| Diff alias | `:LatexSympyDiff[!] [var] [order]` -> `diff` | Selection/range | Replace or append | `:LatexSympyDiff x 2` | Same parser rules as `diff` |
| Integrate alias | `:LatexSympyIntegrate[!] ...` -> `integrate` | Selection/range | Replace or append | `:LatexSympyIntegrate x 0 1` | Same parser rules as `integrate` |
| Det alias | `:LatexSympyDet[!]` -> `det` | Matrix selection/range | Replace or append | Determinant workflow | Non-matrix input errors |
| Inv alias | `:LatexSympyInv[!]` -> `inv` | Matrix selection/range | Replace or append | Inverse workflow | Singular matrix errors |

## Advanced Ops: Algebra

| Op | Syntax | Input contract | Output behavior | Example | Common edge/error |
|---|---|---|---|---|---|
| simplify | `:LatexSympyOp[!] simplify` | Selection/range | Replace or append simplified result | `(x+1)^2-(x^2+2x+1)` | Parse error on invalid expression |
| trigsimp | `:LatexSympyOp[!] trigsimp` | Selection/range | Replace or append trig simplification | `\sin(x)^2+\cos(x)^2` | Parse error on invalid expression |
| ratsimp | `:LatexSympyOp[!] ratsimp` | Selection/range | Replace or append rational simplification | `1/x + 1/y` | Parse error on invalid expression |
| powsimp | `:LatexSympyOp[!] powsimp` | Selection/range | Replace or append power simplification | `x^a x^b` | Parse error on invalid expression |
| apart | `:LatexSympyOp[!] apart [var]` | Selection/range | Replace or append partial fractions | `:LatexSympyOp apart x` on `(x+1)/(x(x+2))` | Invalid variable arg or parse error |
| subs | `:LatexSympyOp[!] subs x=2 y=3` | Selection/range + assignment tokens | Replace or append substituted expression | `x+y` with `x=2 y=3` | Invalid token format (must be `symbol=value`) |
| div | `:LatexSympyOp[!] div [var]` | Selection split into exactly 2 expressions | Replace or append division result | Select `x^2-1` and `x-1` | Errors if not exactly two expressions |
| gcd | `:LatexSympyOp[!] gcd [var]` | Selection split into exactly 2 expressions | Replace or append gcd | Select `x^2-1` and `x-1` | Errors if not exactly two expressions |
| sqf | `:LatexSympyOp[!] sqf [var]` | Selection/range | Replace or append square-free decomposition | `(x-1)^2 (x+2)` | Parse failures surface as errors |
| groebner | `:LatexSympyOp[!] groebner <vars...> [order]` | Selection split into polynomial list | Replace or append Groebner basis | Select `x^2+y ; x-y` and run `groebner x y lex` | Invalid order (`lex/grlex/grevlex` only) |
| resultant | `:LatexSympyOp[!] resultant <var>` | Selection split into exactly 2 expressions | Replace or append resultant | Select `x^2+y` and `x-y` then run `resultant x` | Requires var and exactly two expressions |

## Advanced Ops: Solvers

| Op | Syntax | Input contract | Output behavior | Example | Common edge/error |
|---|---|---|---|---|---|
| solve | `:LatexSympyOp[!] solve [var ...]` | Selection/range equation or expression | Replace or append solution(s) | `x^2-1=0` or `x^2-4` | Invalid var tokens or parse errors |
| solve_system | `:LatexSympyOp[!] solve_system [var ...]` | Selection split by newline/semicolon equations | Replace or append system solutions | Select `x+y=3` and `x-y=1` | Invalid equation list |
| solveset | `:LatexSympyOp[!] solveset [var] [C|R|Z|N]` | Selection/range | Replace or append solution set | `solveset x R` on `x^2-1=0` | Domain must be one of `C/R/Z/N` |
| linsolve | `:LatexSympyOp[!] linsolve [var ...]` | Selection split equation system | Replace or append linear system set result | Select two linear equations | Bad/inconsistent system format |
| nonlinsolve | `:LatexSympyOp[!] nonlinsolve [var ...]` | Selection split equation system | Replace or append nonlinear set result | Select nonlinear system equations | Bad system format or unsupported forms |
| nsolve | `:LatexSympyOp[!] nsolve <var> <guess> [guess2]` | Selection/range equation/expression | Replace or append numeric root | `nsolve x 1` on `x^2-2=0` | Missing var/guess args |
| dsolve | `:LatexSympyOp[!] dsolve [func]` | Selection/range differential equation text | Replace or append DE solution | `Derivative(y(x),x)-y(x)=0` | LaTeX derivative parsing may need SymPy form |
| rsolve | `:LatexSympyOp[!] rsolve [func]` | Selection/range recurrence equation | Replace or append recurrence solution | `a(n+1)-a(n)=0` | Invalid recurrence format |
| diophantine | `:LatexSympyOp[!] diophantine [var ...]` | Single integer equation selection | Replace or append integer-solution set | `2x+3y=5` | Requires single Diophantine equation |

## Advanced Ops: Calculus

| Op | Syntax | Input contract | Output behavior | Example | Common edge/error |
|---|---|---|---|---|---|
| diff | `:LatexSympyOp[!] diff [var] [order]` or chained | Selection/range | Replace or append derivative | `diff x 2` on `x^4+x^2` | Invalid chain/order tokens |
| integrate | `:LatexSympyOp[!] integrate [var] [lower] [upper]` (triplets allowed) | Selection/range | Replace or append integral result | `integrate x 0 1` on `x^2` | Invalid bound triplets |
| limit | `:LatexSympyOp[!] limit <var> <point> [dir]` | Selection/range | Replace or append limit | `limit x 0 +-` on `sin(x)/x` | `dir` must be `+`, `-`, or `+-` |
| series | `:LatexSympyOp[!] series <var> <point> <order>` | Selection/range | Replace or append series (without Big-O) | `series x 0 6` on `sin(x)` | Order must be positive integer |
| summation | `:LatexSympyOp[!] summation <var> <lower> <upper>` | Selection/range | Replace or append finite sum | `summation k 1 n` on `k` | Missing bounds/var args |
| product | `:LatexSympyOp[!] product <var> <lower> <upper>` | Selection/range | Replace or append finite product | `product k 1 n` on `k` | Missing bounds/var args |

## Advanced Ops: Matrix

| Op | Syntax | Input contract | Output behavior | Example | Common edge/error |
|---|---|---|---|---|---|
| det | `:LatexSympyOp[!] det` | Matrix selection/range | Replace or append scalar determinant | `[[1,2],[3,4]]` | Non-matrix input errors |
| inv | `:LatexSympyOp[!] inv` | Matrix selection/range | Replace or append inverse matrix | `[[1,2],[3,4]]` | Singular matrix errors |
| transpose | `:LatexSympyOp[!] transpose` | Matrix selection/range | Replace or append transposed matrix | `[[1,2,3],[4,5,6]]` | Non-matrix input errors |
| rank | `:LatexSympyOp[!] rank` | Matrix selection/range | Replace or append rank scalar | `[[1,2],[2,4]]` | Non-matrix input errors |
| eigenvals | `:LatexSympyOp[!] eigenvals` | Matrix selection/range | Replace or append eigenvalue map | `[[1,2],[3,4]]` | Non-matrix input errors |
| eigenvects | `:LatexSympyOp[!] eigenvects` | Matrix selection/range | Replace or append eigenvector structure | `[[2,0],[0,3]]` | Non-matrix input errors |
| nullspace | `:LatexSympyOp[!] nullspace` | Matrix selection/range | Replace or append nullspace basis | `[[1,2],[2,4]]` | Non-matrix input errors |
| charpoly | `:LatexSympyOp[!] charpoly [var]` | Matrix selection/range | Replace or append characteristic polynomial | `charpoly t` on `[[1,0],[0,2]]` | Invalid symbol arg |
| lu | `:LatexSympyOp[!] lu` | Matrix selection/range | Replace or append LU decomposition result | `[[4,3],[6,3]]` | Non-matrix input errors |
| qr | `:LatexSympyOp[!] qr` | Matrix selection/range | Replace or append QR decomposition result | `[[1,1],[1,-1]]` | Non-matrix input errors |
| mat_solve | `:LatexSympyOp[!] mat_solve` | Augmented matrix selection `[A|b]` | Replace or append solved vector/result | `[[2,1,5],[1,-1,1]]` | Malformed augmented matrix errors |
| jordan | `:LatexSympyOp[!] jordan` | Matrix selection/range | Replace or append Jordan form result | `[[2,1],[0,2]]` | Non-matrix input errors |
| svd | `:LatexSympyOp[!] svd` | Matrix selection/range | Replace or append SVD tuple | `[[1,0],[0,2]]` | Non-matrix input errors |
| cholesky | `:LatexSympyOp[!] cholesky` | Matrix selection/range | Replace or append Cholesky factor | `[[4,2],[2,3]]` | Needs symmetric positive-definite matrix |

## Advanced Ops: Number Theory + Combinatorics

| Op | Syntax | Input contract | Output behavior | Example | Common edge/error |
|---|---|---|---|---|---|
| isprime | `:LatexSympyOp[!] isprime` | Integer selection/range | Replace or append boolean/scalar | `97` | Non-integer input errors |
| factorint | `:LatexSympyOp[!] factorint` | Integer selection/range | Replace or append factor map | `360` | Non-integer input errors |
| primerange | `:LatexSympyOp[!] primerange <start> <stop>` | Args required | Replace or append prime list | `primerange 10 20` | `start/stop` must be integers |
| totient | `:LatexSympyOp[!] totient` | Integer selection/range | Replace or append `phi(n)` | `36` | Non-integer input errors |
| mobius | `:LatexSympyOp[!] mobius` | Integer selection/range | Replace or append `mu(n)` | `30` | Non-integer input errors |
| divisors | `:LatexSympyOp[!] divisors [true|false]` | Integer selection/range | Replace or append divisor list | `divisors true` on `24` | `proper` must be `true` or `false` |
| binomial | `:LatexSympyOp[!] binomial <n> <k>` | Args required | Replace or append `n choose k` | `binomial 5 2` | Missing/invalid integer args |
| perm | `:LatexSympyOp[!] perm <n> [k]` | Args required | Replace or append permutation count | `perm 5 2` | Missing/invalid integer args |
| comb | `:LatexSympyOp[!] comb <n> <k>` | Args required | Replace or append combination count | `comb 5 2` | Missing/invalid integer args |
| partition | `:LatexSympyOp[!] partition <n>` | Args required | Replace or append partition count | `partition 8` | Missing/invalid integer arg |
| subsets | `:LatexSympyOp[!] subsets [k]` | Selected finite set/list required | Replace or append subset list | `subsets 2` on `{1,2,3}` | Invalid finite collection format |
| perm_group | `:LatexSympyOp[!] perm_group <action> [point]` | Selected generators list `[1,2,0]` per line | Replace or append group query result | `perm_group order` or `perm_group stabilizer 0` | `stabilizer` requires integer point |
| prufer | `:LatexSympyOp[!] prufer <encode|decode> [n]` | `encode`: selected edges + `n`; `decode`: selected code list | Replace or append encoded/decoded tree data | `prufer encode 4` with edge list | Invalid edge/code list formats |
| gray | `:LatexSympyOp[!] gray <sequence|bin_to_gray|gray_to_bin> <value>` | `sequence` expects positive int; others binary string | Replace or append Gray conversion/list | `gray bin_to_gray 1011` | Invalid binary string or non-positive width |

## Advanced Ops: Logic + Symbol Assumptions

| Op | Syntax | Input contract | Output behavior | Example | Common edge/error |
|---|---|---|---|---|---|
| logic_simplify | `:LatexSympyOp[!] logic_simplify [simplify|cnf|dnf]` | Boolean expression selection/range | Replace or append normalized boolean form | `(A & B) \| (A & ~B)` | Invalid form enum |
| sat | `:LatexSympyOp[!] sat` | Boolean expression selection/range | Replace or append satisfiable assignment/result | `A & ~A` | Malformed boolean expression |
| symbol | `:LatexSympyOp symbol <name> [assumption=bool ...]` | Args required | Registers symbol assumptions in session | `symbol x real=true integer=false` | Unknown assumption keys rejected |
| symbols | `:LatexSympyOp symbols` | No args | Returns registered symbols/assumptions | `symbols` | None |
| symbols_reset | `:LatexSympyOp symbols_reset` | No args | Clears registered symbols | `symbols_reset` | None |

## Advanced Ops: Geometry

| Op | Syntax | Input contract | Output behavior | Example | Common edge/error |
|---|---|---|---|---|---|
| geometry | `:LatexSympyOp[!] geometry` | Selected constructor expression(s) | Replace or append normalized geometry object(s) | `Point(0,0)` | Invalid constructor syntax |
| intersect | `:LatexSympyOp[!] intersect` | Exactly two geometry objects selected | Replace or append intersection result | Select two lines | Requires two valid objects |
| tangent | `:LatexSympyOp[!] tangent` | Exactly two geometry objects selected | Replace or append tangency result | Select circle and line | Requires two valid objects |
| similar | `:LatexSympyOp[!] similar` | Exactly two geometry objects selected | Replace or append similarity result | Select two polygons | Requires two valid objects |

## Advanced Ops: Physics

| Op | Syntax | Input contract | Output behavior | Example | Common edge/error |
|---|---|---|---|---|---|
| units | `:LatexSympyOp[!] units simplify` or `units convert <target>` | Selection/range + action args | Replace or append unit result | `units convert kilometer/hour` on `10*meter/second` | Missing/invalid action args |
| mechanics | `:LatexSympyOp[!] mechanics euler_lagrange <q...>` | Selection is Lagrangian expression | Replace or append Euler-Lagrange equations | `mechanics euler_lagrange q(t)` | Missing generalized coordinates |
| quantum | `:LatexSympyOp[!] quantum dagger` or `quantum commutator <expr2>` | Selection/range + action args | Replace or append quantum algebra result | `quantum commutator B` on `A` | Missing second expression for commutator |
| optics | `:LatexSympyOp[!] optics lens <k=v...>`, `mirror <k=v...>`, or `refraction <incident> <n1> <n2>` | Selection/range + action args | Replace or append optics result | `optics refraction 1 1 2` | Missing/invalid action args |
| pauli | `:LatexSympyOp[!] pauli simplify` | Selection/range | Replace or append simplified Pauli expression | `Pauli(1)*Pauli(1)` | Invalid action or expression |

## Advanced Ops: Probability

| Op | Syntax | Input contract | Output behavior | Example | Common edge/error |
|---|---|---|---|---|---|
| dist | `:LatexSympyOp dist <kind> <name> <params...>` | Args required (`normal`,`uniform`,`bernoulli`,`binomial`,`hypergeometric`) | Registers RV in session; returns registration output | `dist normal X 0 1` | Unknown distribution kind |
| p | `:LatexSympyOp[!] p` | Selection/range condition expression | Replace or append probability | `X > 0` | Requires registered RV symbols |
| e | `:LatexSympyOp[!] e` | Selection/range expression | Replace or append expectation | `X` | Requires registered RV symbols |
| var | `:LatexSympyOp[!] var` | Selection/range expression | Replace or append variance | `X` | Requires registered RV symbols |
| density | `:LatexSympyOp[!] density` | Selection/range expression | Replace or append density expression | `X` | Requires registered RV symbols |

## Picker, Repeat, and Utilities

| Feature | Syntax | Input contract | Output behavior | Example | Common edge/error |
|---|---|---|---|---|---|
| Command picker | `:LatexSympyPick[!]` | None (selection needed only for selected command kinds) | Interactive command selection and execution | Pick `Ops -> integrate` and run with guided args | Selection-required entries are hidden by default with no selection |
| Repeat last op | `:LatexSympyRepeat[!]` | Prior op must exist + current selection/range | Re-runs last advanced op/alias | Run after `solve`, then select new equation | Errors if no prior op exists |
| Status | `:LatexSympyStatus` | None | Prints runtime/server/config status | Server diagnostics | None |
| Start/Stop/Restart | `:LatexSympyStart`, `:LatexSympyStop`, `:LatexSympyRestart` | None | Controls backend server lifecycle | Recover from failed server state | Port conflicts may still fail start |
| Variances dump | `:LatexSympyVariances` | None | Inserts variances map at cursor | Inspect stored variances | None |
| Reset state | `:LatexSympyReset` | None | Clears variances + symbol + distribution session state | Reset between workflows | None |
| Toggle complex | `:LatexSympyToggleComplex` | None | Toggles complex-mode handling in server session | Switch real/complex assumptions quickly | Affects subsequent evaluations |
| Python eval (opt-in) | `:LatexSympyPython` | Selection/range, and `enable_python_eval=true` | Evaluates selected Python expression | `1 + 1` | Disabled by default for safety |

## Default Keymaps (tex buffers only)

These are applied when `default_keymaps = true` and `respect_existing_keymaps = true`.

| Mode | Mapping | Runs |
|---|---|---|
| Visual | `<leader>le` | `LatexSympyEqual` |
| Visual | `<leader>lr` | `LatexSympyReplace` |
| Visual | `<leader>ln` | `LatexSympyNumerical` |
| Visual | `<leader>lf` | `LatexSympyFactor` |
| Visual | `<leader>lx` | `LatexSympyExpand` |
| Visual | `<leader>lm` | `LatexSympyMatrixRREF` |
| Visual | `<leader>lo` | `LatexSympyOp` |
| Visual | `<leader>ls` | `LatexSympySolve` |
| Visual | `<leader>ld` | `LatexSympyDiff` |
| Visual | `<leader>li` | `LatexSympyIntegrate` |
| Visual | `<leader>lt` | `LatexSympyDet` |
| Visual | `<leader>lv` | `LatexSympyInv` |
| Visual | `<leader>la` | `LatexSympyRepeat` |
| Visual | `<leader>lp` | `LatexSympyPick` |
| Normal | `<leader>xS` | `LatexSympyStatus` |
| Normal | `<leader>x1` | `LatexSympyStart` |
| Normal | `<leader>x0` | `LatexSympyStop` |
| Normal | `<leader>xR` | `LatexSympyRestart` |
| Normal | `<leader>xV` | `LatexSympyVariances` |
| Normal | `<leader>xZ` | `LatexSympyReset` |
| Normal | `<leader>xC` | `LatexSympyToggleComplex` |

## Runtime and Safety Defaults

| Feature | Default | Behavior |
|---|---|---|
| Filetype activation | `tex` only | Commands are registered on first `tex` buffer activation |
| Server start mode | `on_demand` | Server starts when first command needs it |
| Startup notify once | `true` | Small activation message once per session |
| Python eval gate | `enable_python_eval=false` | `:LatexSympyPython` blocked until explicitly enabled |
| Success notifications | `notify_success=true` | One concise success toast with truncated result preview |
| Request timeout | `timeout_ms=5000` | Prevents hanging requests |
| Stale result drop | `drop_stale_results=true` | Older async responses ignored when superseded |
| Picker filter stage | `picker_filter_enabled=false` | Disabled by default so users can browse full command list |

## Maintenance Policy

- Update this file in every feature PR.
- Keep examples runnable and aligned with `tests/manual_feature_checks.tex`.
- When command behavior changes, sync `README.md`, `doc.md`, `CHANGELOG.md`, and `doc/news.txt` in the same PR.
