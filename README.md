# Latex Sympy Calculator (Neovim)

A Neovim plugin for computing selected LaTeX math with SymPy.

It works on visual selections or `:<range>` and gives you quick transform commands (`replace`, `factor`, `expand`, `numerical`, `rref`) plus a generic operation command for more advanced SymPy features.

For full usage details, see [`doc.md`](doc.md).

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
    notify_info = false,
    server_start_mode = "on_demand",
    timeout_ms = 5000,
    preview_before_apply = false,
    preview_max_chars = 160,
    drop_stale_results = true,
    default_keymaps = true,
    keymap_prefix = "<leader>x",
    respect_existing_keymaps = true,
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
  notify_startup = true,
  startup_notify_once = true,
  notify_info = false,
  server_start_mode = "on_demand", -- or "on_activate"
  timeout_ms = 5000,
  preview_before_apply = false,
  preview_max_chars = 160,
  drop_stale_results = true,
  default_keymaps = true,
  keymap_prefix = "<leader>x",
  respect_existing_keymaps = true,
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
- `:LatexSympyRepeat[!]`

Quick examples:

- `:LatexSympyOp solve x`
- `:LatexSympyOp! diff x 2`
- `:LatexSympyOp integrate x 0 1`
- `:LatexSympyOp limit x 0 +-`
- `:LatexSympyOp series x 0 5`
- `:LatexSympyOp det`

## Keybindings

Default keymaps are enabled for `tex` buffers and use `<leader>x...`.

- Visual: `<leader>xe` equal, `<leader>xr` replace, `<leader>xn` numerical, `<leader>xf` factor, `<leader>xx` expand
- Visual: `<leader>xm` rref, `<leader>xo` op prompt, `<leader>xs` solve, `<leader>xd` diff, `<leader>xi` integrate
- Visual: `<leader>xt` det, `<leader>xv` inv, `<leader>xa` repeat last op
- Normal: `<leader>xS` status, `<leader>x1` start, `<leader>x0` stop, `<leader>xR` restart
- Normal: `<leader>xV` variances, `<leader>xZ` reset, `<leader>xC` toggle complex

```lua
-- Disable default keymaps:
require("latex_sympy").setup({
  default_keymaps = false,
})

-- Or keep defaults and choose a different prefix:
require("latex_sympy").setup({
  keymap_prefix = "<leader>s",
})
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
