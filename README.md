# Latex Sympy Calculator (Neovim)

Parse LaTeX math and compute results using SymPy, directly from Neovim. This is a port of the VS Code extension "Latex Sympy Calculator" to Neovim.

## Installation

- lazy.nvim

```lua
{
  dir = "/path/to/Latex-sympy.nvim",
  config = function()
    require("latex_sympy").setup({
      python = "python3",   -- or an absolute path
      auto_install = true,   -- auto `pip install --upgrade latex2sympy2 Flask`
      port = 7395,
    })
  end,
}
```

## Requirements

- Python 3
- Python packages: `latex2sympy2`, `Flask`

Install with:

```bash
pip install latex2sympy2 Flask
```

If `auto_install` is true (default), the plugin will run:

```bash
python3 -m pip install --upgrade latex2sympy2 Flask
```

## Configuration

(Default values)

```lua
require("latex_sympy").setup({
  python = "python3",
  auto_install = true,
  port = 7395,
})
```

## Commands

All commands work on the current visual selection or a given `:<range>` of lines when applicable:

```vim
:LatexSympyEqual         " Append " = <result>" after selection
:LatexSympyReplace       " Replace selection with LaTeX result
:LatexSympyNumerical     " Replace selection with numerical value
:LatexSympyFactor        " Replace selection with factored form
:LatexSympyExpand        " Replace selection with expanded form
:LatexSympyMatrixRREF    " Append " \to <rref>" after matrix selection
:LatexSympyVariances     " Insert current variances mapping at cursor
:LatexSympyReset         " Reset current variances
:LatexSympyToggleComplex " Toggle complex-number support for variances
:LatexSympyPython        " Evaluate Python snippet; append result

:LatexSympyStatus        " Show current server/config status
:LatexSympyRestart       " Restart the Python server
:LatexSympyStart         " Start the Python server
:LatexSympyStop          " Stop the Python server
```

## Development

### Initialization

Run this line once before calling any `busted` command:

```sh
eval $(luarocks path --lua-version 5.1 --bin)
```

### Running tests

```sh
# Using the package manager
luarocks test --test-type busted
# Or manually
busted .
# Or with Make
make test
```

### Coverage

```sh
make coverage-html
```

This will generate a `luacov.stats.out` & `luacov_html/` directory.

To view:

```sh
(cd luacov_html && python -m http.server)
```

## Quickstart

1. Open a buffer with LaTeX math (e.g. `x^2 + 2x + 1`).
2. Select the text (visual mode) or use a `:<range>`.
3. Run `:LatexSympyEqual` to append `= <result>` or `:LatexSympyReplace` to replace selection.

Tip: For matrices, select the full matrix and run `:LatexSympyMatrixRREF` to append `\to <rref>`.

## Keymaps (examples)

```lua
-- Visual: append result
vim.keymap.set('v', '<leader>le', ':<C-u>LatexSympyEqual<CR>', { desc = 'latex_sympy equal' })
-- Visual: replace with result
vim.keymap.set('v', '<leader>lr', ':<C-u>LatexSympyReplace<CR>', { desc = 'latex_sympy replace' })
-- Visual: numerical value
vim.keymap.set('v', '<leader>ln', ':<C-u>LatexSympyNumerical<CR>', { desc = 'latex_sympy numerical' })
-- Visual: factor / expand
vim.keymap.set('v', '<leader>lf', ':<C-u>LatexSympyFactor<CR>', { desc = 'latex_sympy factor' })
vim.keymap.set('v', '<leader>lx', ':<C-u>LatexSympyExpand<CR>', { desc = 'latex_sympy expand' })
-- Visual: matrix RREF
vim.keymap.set('v', '<leader>lm', ':<C-u>LatexSympyMatrixRREF<CR>', { desc = 'latex_sympy rref' })
-- Normal: utilities
vim.keymap.set('n', '<leader>ls', '<cmd>LatexSympyStatus<CR>', { desc = 'latex_sympy status' })
vim.keymap.set('n', '<leader>lS', '<cmd>LatexSympyRestart<CR>', { desc = 'latex_sympy restart' })
```

## Health

- Run `:checkhealth latex_sympy` to verify prerequisites:
  - python3 found
  - latex2sympy2 installed
  - Flask installed
  - curl found (used for HTTP requests)
  - Current plugin configuration

## Troubleshooting

- Server won’t start
  - Run `:LatexSympyStatus` to see status.
  - Check `:checkhealth latex_sympy` for missing dependencies.
  - Try `:LatexSympyRestart`.
- Port already in use
  - Change `port` in `setup({ port = 7395 })` and restart: `:LatexSympyRestart`.
- python3 not found or wrong version
  - Set `python` in setup to an absolute path (e.g. a venv): `setup({ python = "/path/to/venv/bin/python" })`.
- pip install failures
  - Set `auto_install = false` and install manually: `pip install latex2sympy2 Flask`.
- curl missing
  - Install curl (macOS: `brew install curl`), or replace curl with another HTTP client in your environment.

## Security

- `:LatexSympyPython` evaluates arbitrary Python code in your configured interpreter. Only run trusted code.

## Configuration Reference

| Option       | Type    | Default    | Description                             |
|--------------|---------|------------|-----------------------------------------|
| `python`     | string  | `"python3"` | Path to Python interpreter               |
| `auto_install` | boolean | `true`      | Auto `pip install --upgrade` deps        |
| `port`       | number  | `7395`     | HTTP server port                         |

## FAQ

- Disable autostart?
  - This plugin autostarts by default. You can lazy-load it (e.g., load on a command or key) so `setup()` runs later, or call `:LatexSympyStop` after startup.
- Change port?
  - Set `port` in `setup` and run `:LatexSympyRestart`.
- Restart the server?
  - `:LatexSympyRestart`.
- Use an external Python env/venv?
  - Point `python` to the desired interpreter path in `setup`.
