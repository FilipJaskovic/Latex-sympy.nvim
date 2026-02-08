# Latex Sympy Calculator (Neovim)

A Neovim plugin for computing selected LaTeX math with SymPy.

It works on visual selections or `:<range>` and gives you quick transform commands (`replace`, `factor`, `expand`, `numerical`, `rref`) plus a generic operation command for more advanced SymPy features.

## Install

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
    server_start_mode = "on_demand",
    timeout_ms = 5000,
    preview_before_apply = false,
    preview_max_chars = 160,
    drop_stale_results = true,
  },
  config = function(_, opts)
    require("latex_sympy").setup(opts)
  end,
}
```

## Configure

```lua
require("latex_sympy").setup({
  python = "python3",
  auto_install = false,
  port = 7395,
  enable_python_eval = false,
  server_start_mode = "on_demand", -- or "on_activate"
  timeout_ms = 5000,
  preview_before_apply = false,
  preview_max_chars = 160,
  drop_stale_results = true,
})
```

## Commands

Existing commands are still there:

- `:LatexSympyEqual`
- `:LatexSympyReplace`
- `:LatexSympyNumerical`
- `:LatexSympyFactor`
- `:LatexSympyExpand`
- `:LatexSympyMatrixRREF`
- `:LatexSympyVariances`
- `:LatexSympyReset`
- `:LatexSympyToggleComplex`
- `:LatexSympyPython` (requires `enable_python_eval = true`)
- `:LatexSympyStatus`
- `:LatexSympyStart`
- `:LatexSympyStop`
- `:LatexSympyRestart`

New generic op command:

- `:LatexSympyOp[!] {op} [args...]`
- no `!`: replace selected text with result
- with `!`: append ` = <result>` after selected text

Supported `op` values:

- `solve [var]`
- `diff [var] [order]`
- `integrate [var] [lower] [upper]`
- `limit <var> <point> [dir]`
- `series <var> <point> <order>`
- `det`
- `inv`
- `transpose`
- `rank`
- `eigenvals`

Alias commands:

- `:LatexSympySolve`
- `:LatexSympyDiff`
- `:LatexSympyIntegrate`
- `:LatexSympyDet`
- `:LatexSympyInv`

Quick examples:

- `:LatexSympyOp solve x`
- `:LatexSympyOp! diff x 2`
- `:LatexSympyOp integrate x 0 1`
- `:LatexSympyOp limit x 0 +-`
- `:LatexSympyOp series x 0 5`
- `:LatexSympyOp det`

## Keybindings

There are no default keybindings.

```lua
vim.keymap.set("v", "<localleader>le", ":<C-u>LatexSympyEqual<CR>")
vim.keymap.set("v", "<localleader>lo", ":<C-u>LatexSympyOp ")
```

## Requirements

- Python 3
- `curl`
- Python packages: `latex2sympy2`, `Flask`

```bash
python3 -m pip install latex2sympy2 Flask
```

## Check

```vim
:checkhealth latex_sympy
```
