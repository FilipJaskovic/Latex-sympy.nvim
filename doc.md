# Latex-sympy.nvim Usage Guide

This file is the full usage reference for the plugin.

Use this doc when you want details (all commands, advanced op syntax, keymaps, config behavior, and troubleshooting).

## What this plugin does

`latex_sympy.nvim` evaluates selected LaTeX math using SymPy and writes results back into your buffer.

It supports:

- quick transforms (`equal`, `replace`, `numerical`, `factor`, `expand`, `matrix rref`)
- advanced operations through a generic op command (`solve`, calculus ops, matrix ops)
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

Supported ops:

- `solve [var]`
  - with equation input (`lhs = rhs`): solves equation
  - without `=`: solves expression as `expression = 0`
  - if `var` omitted: first free symbol is used
- `diff [var] [order]`
  - defaults: first free symbol, order `1`
  - one integer argument is treated as `order`
- `integrate [var] [lower] [upper]`
  - no args: indefinite integral with inferred symbol
  - one arg: indefinite integral in given variable
  - three args: definite integral `(var, lower, upper)`
- `limit <var> <point> [dir]`
  - `dir` allowed: `+`, `-`, `+-` (default `+-`)
- `series <var> <point> <order>`
  - order must be positive integer
  - big-O term is removed before returning result
- `det`
- `inv`
- `transpose`
- `rank`
- `eigenvals`
  - matrix ops require matrix input

## Alias commands

These call `LatexSympyOp` internally:

- `:LatexSympySolve[!] [var]`
- `:LatexSympyDiff[!] [var] [order]`
- `:LatexSympyIntegrate[!] [var] [lower] [upper]`
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
