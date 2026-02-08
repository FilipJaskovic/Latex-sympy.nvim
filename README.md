# Latex Sympy Calculator (Neovim)

A Neovim plugin for computing selected LaTeX math with SymPy.

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
  server_start_mode = "on_demand", -- or "on_activate"
})
```

Options:

- `python`: Python interpreter path
- `auto_install`: auto-install `latex2sympy2` and `Flask`
- `port`: local server port
- `enable_python_eval`: enable `:LatexSympyPython` (off by default)
- `notify_startup`: show startup message
- `startup_notify_once`: show startup message once per session
- `server_start_mode`: `on_demand` or `on_activate`

## Commands

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

## Keybindings

There are no default keybindings.

Example with `<localleader>`:

```lua
vim.keymap.set("v", "<localleader>le", ":<C-u>LatexSympyEqual<CR>", { desc = "latex sympy equal" })
vim.keymap.set("v", "<localleader>lr", ":<C-u>LatexSympyReplace<CR>", { desc = "latex sympy replace" })
vim.keymap.set("v", "<localleader>ln", ":<C-u>LatexSympyNumerical<CR>", { desc = "latex sympy numerical" })
vim.keymap.set("v", "<localleader>lf", ":<C-u>LatexSympyFactor<CR>", { desc = "latex sympy factor" })
vim.keymap.set("v", "<localleader>lx", ":<C-u>LatexSympyExpand<CR>", { desc = "latex sympy expand" })
vim.keymap.set("v", "<localleader>lm", ":<C-u>LatexSympyMatrixRREF<CR>", { desc = "latex sympy rref" })
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
