# Latex-sympy.nvim Usage Guide

This file is the full usage reference for the plugin.

Use this doc when you want details (all commands, advanced op syntax, keymaps, config behavior, and troubleshooting).

For implemented vs planned feature status, see [`FEATURES.md`](FEATURES.md).

## What this plugin does

`latex_sympy.nvim` evaluates selected LaTeX math using SymPy and writes results back into your buffer.

It supports:

- quick transforms (`equal`, `replace`, `numerical`, `factor`, `expand`, `matrix rref`)
- advanced operations through a generic op command (algebra, equation depth, calculus, matrix depth, number theory)
- server controls and state helpers (`status`, `start/stop/restart`, variances helpers)

## Runtime behavior

- Plugin activates only on `tex` filetype buffers.
- Commands are registered after first `tex` activation in the current Neovim session.
- Python server starts on demand by default (`server_start_mode = "on_demand"`).
- Startup message is shown once per session by default.

## Install (lazy.nvim)

```lua
{
  "owner/Latex-sympy.nvim",
  ft = "tex",
  opts = {
    python = "python3",
    auto_install = false,
    port = 7395,
    enable_python_eval = false,
    notify_startup = true,
    startup_notify_once = true,
    notify_info = false,
    server_start_mode = "on_demand",
    timeout_ms = 5000,
    preview_before_apply = false,
    preview_max_chars = 160,
    drop_stale_results = true,
    default_keymaps = true,
    keymap_prefix = "<leader>l",
    normal_keymap_prefix = "<leader>x",
    respect_existing_keymaps = true,
    picker_backend = "vim_ui",
    picker_select = nil,
    picker_input = nil,
    picker_filter_enabled = false,
    picker_filter_prompt = "latex_sympy filter (optional):",
    picker_show_unavailable = false,
    picker_guided_args = "all",
    picker_guided_args_allow_raw = true,
    notify_success = true,
    notify_success_max_chars = 120,
  },
  config = function(_, opts)
    require("latex_sympy").setup(opts)
  end,
}
```

## Input model (how commands read text)

Most math commands operate on:

- visual selection (`v`/`V`/`Ctrl-v`)
- or an Ex line range, for example:
  - `:12,14LatexSympyReplace`
  - `:%LatexSympyNumerical`

If neither selection nor range is present, command fails with:

- `No selection detected. Use visual selection or provide a range.`

## Command reference

## Core transform commands

- `:LatexSympyEqual`
  - appends ` = <result>` after selected text
- `:LatexSympyReplace`
  - replaces selected text with computed result
- `:LatexSympyNumerical`
  - replaces selection with numerical evaluation
- `:LatexSympyFactor`
  - replaces selection with factored form
- `:LatexSympyExpand`
  - replaces selection with expanded form
- `:LatexSympyMatrixRREF`
  - appends `\to <rref>` for matrix input

## Advanced op command

Syntax:

- `:LatexSympyOp[!] {op} [args...]`

Behavior:

- without `!`: replace mode
- with `!`: append mode (` = <result>`)
- if you type a trailing `!` as an argument (for example `:LatexSympyOp det !`), it is auto-converted to bang mode once and shows a syntax hint.

Supported ops:

- `simplify`
  - symbolic simplification using SymPy `simplify(...)`
- `trigsimp`
  - trigonometric simplification
- `ratsimp`
  - rational expression simplification
- `powsimp`
  - power simplification/combination
- `apart [var]`
  - partial fraction decomposition
  - if `var` omitted, SymPy chooses decomposition variable
- `subs <symbol>=<value> [<symbol>=<value> ...]`
  - substitution assignments are whitespace-separated tokens
  - example: `subs x=2 y=3`
- `solveset [var] [domain]`
  - solves expression/equation as set
  - `domain` allowed: `C`, `R`, `Z`, `N` (default `C`)
- `linsolve [var ...]`
  - solves newline/semicolon-separated linear equation systems
  - if vars omitted, they are inferred from system symbols
- `nonlinsolve [var ...]`
  - solves newline/semicolon-separated nonlinear equation systems
  - if vars omitted, they are inferred from system symbols
- `rsolve [func]`
  - solves recurrence equations
  - optional function target (for example `a(n)`)
- `diophantine [var ...]`
  - solves a single integer equation
  - if vars omitted, SymPy uses inferred symbol ordering
- `solve [var ...]`
  - with equation input (`lhs = rhs`): solves equation
  - without `=`: solves expression as `expression = 0`
  - supports multiple variables (`solve x y`)
  - if variables omitted: first free symbol is used
- `solve_system [var ...]`
  - solves newline/semicolon-separated equations from the selected text
  - if variables are omitted, they are inferred from equation symbols
- `diff [var] [order]` or chained form `diff x 2 y 1`
  - defaults: first free symbol, order `1`
  - one integer argument is treated as `order`
- `integrate [var] [lower] [upper]` or repeated triplets
  - no args: indefinite integral with inferred symbol
  - one arg: indefinite integral in given variable
  - three args: definite integral `(var, lower, upper)`
  - repeated triplets: `integrate x 0 1 y 0 2`
- `limit <var> <point> [dir]`
  - `dir` allowed: `+`, `-`, `+-` (default `+-`)
- `series <var> <point> <order>`
  - order must be positive integer
  - big-O term is removed before returning result
- `nsolve <var> <guess> [guess2]`
  - numeric root solving
- `dsolve [func]`
  - differential equation solving, optional function target (for example `y(x)`)
  - derivative-heavy equations are most reliable with SymPy-style input, e.g. `Derivative(y(x), x) - y(x) = 0`
- `det`
- `inv`
- `transpose`
- `rank`
- `eigenvals`
  - matrix ops require matrix input
- `eigenvects`
  - matrix eigenvector decomposition
- `nullspace`
  - matrix nullspace basis
- `charpoly [var]`
  - characteristic polynomial in `var` (default `lambda`)
- `lu`
  - LU decomposition output (`L`, `U`, permutation data)
- `qr`
  - QR decomposition output (`Q`, `R`)
- `mat_solve`
  - solves augmented matrix `[A|b]` (last column is RHS vector)
- `isprime`
  - primality test for integer input
- `factorint`
  - integer prime factorization map
- `primerange <start> <stop>`
  - list primes in range `[start, stop)`
- `div [var]`
  - polynomial division of two selected expressions (selection must contain exactly two expressions split by newline or `;`)
- `gcd [var]`
  - polynomial gcd of two selected expressions
- `sqf [var]`
  - square-free decomposition
- `groebner <var...> [order]`
  - Grobner basis for selected polynomial list (split by newline or `;`)
  - `order` allowed: `lex`, `grlex`, `grevlex`
- `resultant <var>`
  - resultant of two selected expressions
- `summation <var> <lower> <upper>`
  - symbolic finite summation
- `product <var> <lower> <upper>`
  - symbolic finite product
- `binomial <n> <k>`
- `perm <n> [k]`
- `comb <n> <k>`
- `partition <n>`
- `subsets [k]`
  - selected text must be a finite set/list (or newline/semicolon-separated values)
- `totient`
- `mobius`
- `divisors [proper]`
  - `proper` accepts `true|false` (default `false`)
- `logic_simplify [form]`
  - `form` allowed: `simplify`, `cnf`, `dnf`
- `sat`
  - SAT model check for selected boolean expression
- `jordan`
- `svd`
- `cholesky`
  - matrix-only ops
- `symbol <name> [assumption=bool ...]`
  - registers symbol assumptions for parser/session
  - allowed assumptions: `commutative`, `real`, `integer`, `positive`, `nonnegative`
- `symbols`
  - show registered symbol assumptions
- `symbols_reset`
  - clear registered symbol assumptions
- `geometry`
  - parse/normalize selected geometry constructors (`Point(...)`, `Line(...)`, ...)
- `intersect`
- `tangent`
- `similar`
  - geometry comparisons on exactly two selected geometry objects
- `units simplify`
- `units convert <target>`
  - unit simplification/conversion via SymPy units module
- `mechanics euler_lagrange <q...>`
  - Euler-Lagrange equations from selected Lagrangian expression
- `quantum dagger`
- `quantum commutator <expr2>`
- `optics lens <k=v> <k=v>`
- `optics mirror <k=v> <k=v>`
- `optics refraction <incident> <n1> <n2>`
- `pauli simplify`
- `dist <kind> <name> <params...>`
  - supported kinds: `normal`, `uniform`, `bernoulli`, `binomial`, `hypergeometric`
  - registers RV in server session
- `p`
- `e`
- `var`
- `density`
  - probability/expectation/variance/density over selected expression (can use registered `dist` RVs)

## Command picker

- `:LatexSympyPick[!]`
  - opens a staged picker (`Category` -> `Command` by default)
  - optional filter stage can be enabled: (`Category` -> `Filter` -> `Command`)
  - categories are descriptive:
    - `All - Everything`
    - `Core - Quick transforms (equal/replace/factor/expand/rref)`
    - `Ops - Advanced SymPy operations`
    - `Aliases - Shortcuts to common ops`
  - `Utility - Server/status/session helpers`
  - every row is shown as `name - purpose`
  - rows that need required args include `[args: ...]`
  - append-capable rows include `[append available]`
  - selecting an append-capable row prompts `Replace` or `Append (!)`, unless picker was opened with `!` (forced append)
  - filter query matches label, description, op name, and args hint (case-insensitive)
  - selection-required rows are hidden when no selection/range exists (default behavior)
  - optional config can show them as `[needs selection]`
  - guided args mode prompts per argument field for arg-capable ops
  - raw args fallback stays available when guided args are enabled
  - forwards `!` to op/alias executions (append mode where supported)
  - ignores `!` for non-op commands

## Success notifications

- result-producing math commands show concise success notifications by default:
  - core transforms
  - `LatexSympyOp`, aliases, and repeat
  - `LatexSympyPython`
- notification includes command context and truncated result preview

## Alias commands

These call `LatexSympyOp` internally:

- `:LatexSympySolve[!] [var ...]`
- `:LatexSympyDiff[!] [var] [order]` (also supports chained form)
- `:LatexSympyIntegrate[!] [var] [lower] [upper]` (also supports repeated triplets)
- `:LatexSympyDet[!]`
- `:LatexSympyInv[!]`

## Repeat last advanced operation

- `:LatexSympyRepeat[!]`
  - repeats the last `LatexSympyOp`/alias operation with the same op + args
  - applies to current selection/range
  - supports `!` append mode
  - if no previous op exists: shows a clear error

## Utility commands

- `:LatexSympyVariances`
  - inserts current variances map at cursor
- `:LatexSympyReset`
  - resets variances map
  - clears session symbol assumptions (`symbol`) and registered random variables (`dist`)
- `:LatexSympyToggleComplex`
  - toggles complex-number behavior for variances
- `:LatexSympyPython`
  - evaluates selected Python snippet and appends result
  - disabled by default; requires `enable_python_eval = true`
- `:LatexSympyStatus`
  - shows plugin/server/config status
- `:LatexSympyStart`
  - starts backend server
- `:LatexSympyStop`
  - stops backend server
- `:LatexSympyRestart`
  - restarts backend server

## Default keymaps

Keymaps are:

- enabled by default
- buffer-local
- applied only in `tex` buffers
- skipped if mapping already exists and `respect_existing_keymaps = true`

Prefix default:

- visual: `<leader>l`
- normal: `<leader>x`

Visual mode mappings:

- `<leader>le` -> `LatexSympyEqual`
- `<leader>lr` -> `LatexSympyReplace`
- `<leader>ln` -> `LatexSympyNumerical`
- `<leader>lf` -> `LatexSympyFactor`
- `<leader>lx` -> `LatexSympyExpand`
- `<leader>lm` -> `LatexSympyMatrixRREF`
- `<leader>lo` -> `LatexSympyOp` (opens command-line for args)
- `<leader>ls` -> `LatexSympySolve`
- `<leader>ld` -> `LatexSympyDiff`
- `<leader>li` -> `LatexSympyIntegrate`
- `<leader>lt` -> `LatexSympyDet`
- `<leader>lv` -> `LatexSympyInv`
- `<leader>la` -> `LatexSympyRepeat`
- `<leader>lp` -> `LatexSympyPick`

Normal mode mappings:

- `<leader>xS` -> `LatexSympyStatus`
- `<leader>x1` -> `LatexSympyStart`
- `<leader>x0` -> `LatexSympyStop`
- `<leader>xR` -> `LatexSympyRestart`
- `<leader>xV` -> `LatexSympyVariances`
- `<leader>xZ` -> `LatexSympyReset`
- `<leader>xC` -> `LatexSympyToggleComplex`

Disable or change defaults:

```lua
require("latex_sympy").setup({
  default_keymaps = false,
})

require("latex_sympy").setup({
  keymap_prefix = "<leader>s",
  normal_keymap_prefix = "<leader>n",
})
```

## Configuration reference

- `python` (`"python3"`)
  - python executable used to run server and optional auto-install
- `auto_install` (`false`)
  - auto-install required python packages on first server start
- `port` (`7395`)
  - localhost port for backend server
- `enable_python_eval` (`false`)
  - enables `:LatexSympyPython`
- `notify_startup` (`true`)
  - show startup message on activation
- `startup_notify_once` (`true`)
  - show startup message once per session
- `notify_info` (`false`)
  - show routine info notifications (start/stop/reset etc.)
- `server_start_mode` (`"on_demand"`)
  - `"on_demand"`: start on first request
  - `"on_activate"`: start when first `tex` buffer activates plugin
- `timeout_ms` (`5000`)
  - request timeout for curl/http calls
- `preview_before_apply` (`false`)
  - ask `Apply/Cancel` before writing result
- `preview_max_chars` (`160`)
  - preview truncation length
- `drop_stale_results` (`true`)
  - ignore out-of-order old async responses
- `default_keymaps` (`true`)
  - auto-register default keymaps for `tex` buffers
- `keymap_prefix` (`"<leader>l"`)
  - visual-mode prefix used by default keymap set
- `normal_keymap_prefix` (`"<leader>x"`)
  - normal-mode prefix used by default keymap set
- `respect_existing_keymaps` (`true`)
  - do not override existing user mappings
- `picker_backend` (`"vim_ui"`)
  - picker backend: `"vim_ui"`, `"auto"`, `"snacks"`
- `picker_select` (`nil`)
  - optional picker override callback: `function(items, opts, on_choice)`
- `picker_input` (`nil`)
  - optional input override callback: `function(opts, on_confirm)`
- `picker_filter_enabled` (`false`)
  - prompt for an optional text filter before command selection
- `picker_filter_prompt` (`"latex_sympy filter (optional):"`)
  - filter input prompt text
- `picker_show_unavailable` (`false`)
  - when `true`, keep selection-required rows visible as `[needs selection]`
- `picker_guided_args` (`"all"`)
  - `"all"`: guided arg prompts for arg-capable entries
  - `"off"`: disable guided args and use raw args prompt only
- `picker_guided_args_allow_raw` (`true`)
  - allow fallback to raw args prompt if guided collection fails/cancelled
- `notify_success` (`true`)
  - show success notifications for result-producing commands
- `notify_success_max_chars` (`120`)
  - max characters in success result preview text

## Requirements

- Python 3
- `curl`
- Python packages:
  - `latex2sympy2`
  - `Flask`

Install:

```bash
python3 -m pip install latex2sympy2 Flask
```

Health check:

```vim
:checkhealth latex_sympy
```

## Troubleshooting

- Error: `LatexSympyPython is disabled...`
  - enable with:
  - `require("latex_sympy").setup({ enable_python_eval = true })`

- Error: `'params' must be an object` (usually old client payload behavior)
  - update plugin to latest version
  - this version sends empty params correctly as `{}` and server accepts legacy `[]` compatibility only when empty

- Error while using `dsolve` with derivative LaTeX
  - use SymPy-style derivative equation text in the selection:
  - `Derivative(y(x), x) - y(x) = 0`

- Error: `Server is not reachable` / timeout
  - run `:LatexSympyStatus`
  - run `:LatexSympyStart`
  - confirm `python`, `curl`, and python dependencies are installed
  - check port collisions and firewall rules

- No commands in non-tex files
  - expected behavior; plugin is filetype-scoped to `tex`

## Manual test file

Use:

- `tests/manual_feature_checks.tex`

It includes ready-to-run examples for:

- core transforms
- all advanced ops
- aliases
- repeat-op flow
- utility commands

## Keeping this doc up to date (important)

Whenever features change, update this file in the same PR:

1. Add/remove command entries in the command reference.
2. Update advanced op signatures and argument rules.
3. Update keymap table if defaults/prefix change.
4. Update config defaults and descriptions.
5. Add a troubleshooting note for any new common failure case.
6. If adding new operations, also update `tests/manual_feature_checks.tex`.
