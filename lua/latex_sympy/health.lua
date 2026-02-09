local M = {}

local function _ok(msg)
  vim.health.ok(msg)
end

local function _warn(msg)
  vim.health.warn(msg)
end

local function _error(msg)
  vim.health.error(msg)
end

local function has_python_module(python, module_name)
  local cmd = {
    python,
    "-c",
    "import importlib.util; print(1 if importlib.util.find_spec(" .. string.format("%q", module_name) .. ") else 0)",
  }
  local output = vim.fn.system(cmd)
  return vim.v.shell_error == 0 and vim.trim(output) == "1"
end

function M.check()
  vim.health.start("latex_sympy")

  local cfg = {
    python = "python3",
    auto_install = false,
    port = 7395,
    enable_python_eval = false,
    notify_info = false,
    server_start_mode = "on_demand",
    timeout_ms = 5000,
    preview_before_apply = false,
    preview_max_chars = 160,
    drop_stale_results = true,
    default_keymaps = true,
    keymap_prefix = "<leader>x",
    respect_existing_keymaps = true,
  }

  local ok_cfg, mod = pcall(require, "latex_sympy")
  if ok_cfg and mod.get_config then
    cfg = mod.get_config()
  end

  local python = cfg.python or "python3"
  local ok_python = vim.fn.executable(python) == 1
  if ok_python then
    _ok(string.format("Python found: %s", tostring(python)))
  else
    _error(string.format("Python not found or not executable: %s", tostring(python)))
  end

  local ok_curl = vim.fn.executable("curl") == 1
  if ok_curl then
    _ok("curl found")
  else
    _warn("curl not found on PATH; HTTP requests will fail")
  end

  if ok_python then
    if has_python_module(python, "latex2sympy2") then
      _ok("latex2sympy2 installed")
    else
      _warn("latex2sympy2 not found")
    end

    if has_python_module(python, "flask") then
      _ok("Flask installed")
    else
      _warn("Flask not found")
    end
  end

  _ok(string.format(
    "Configured python=%s, port=%s, auto_install=%s, start_mode=%s, python_eval=%s, timeout_ms=%s, preview=%s, drop_stale_results=%s, notify_info=%s, default_keymaps=%s, keymap_prefix=%s, respect_existing_keymaps=%s",
    tostring(cfg.python),
    tostring(cfg.port),
    tostring(cfg.auto_install),
    tostring(cfg.server_start_mode),
    tostring(cfg.enable_python_eval),
    tostring(cfg.timeout_ms),
    tostring(cfg.preview_before_apply),
    tostring(cfg.drop_stale_results),
    tostring(cfg.notify_info),
    tostring(cfg.default_keymaps),
    tostring(cfg.keymap_prefix),
    tostring(cfg.respect_existing_keymaps)
  ))
end

return M
