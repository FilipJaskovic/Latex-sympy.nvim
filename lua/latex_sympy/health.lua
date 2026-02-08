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
    notify_startup = true,
    startup_notify_once = true,
    server_start_mode = "on_demand",
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
    "Configured python=%s, port=%s, auto_install=%s, server_start_mode=%s, enable_python_eval=%s",
    tostring(cfg.python),
    tostring(cfg.port),
    tostring(cfg.auto_install),
    tostring(cfg.server_start_mode),
    tostring(cfg.enable_python_eval)
  ))
end

return M
