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

function M.check()
  vim.health.start("latex_sympy")

  local ok_python = vim.fn.executable("python3") == 1
  if ok_python then
    _ok("python3 found")
  else
    _error("python3 not found on PATH")
  end

  local ok_curl = vim.fn.executable("curl") == 1
  if ok_curl then
    _ok("curl found")
  else
    _warn("curl not found on PATH; HTTP requests will fail")
  end

  -- Check pip packages
  if ok_python then
    local handle = io.popen("python3 -c 'import importlib;print(1 if importlib.util.find_spec(" .. string.format("%q", "latex2sympy2") .. ") else 0)'")
    local latex2sympy_installed = handle and handle:read("*a") or "0"
    if handle then handle:close() end

    local handle2 = io.popen("python3 -c 'import importlib;print(1 if importlib.util.find_spec(" .. string.format("%q", "flask") .. ") else 0)'")
    local flask_installed = handle2 and handle2:read("*a") or "0"
    if handle2 then handle2:close() end

    if vim.trim(latex2sympy_installed) == "1" then
      _ok("latex2sympy2 installed")
    else
      _warn("latex2sympy2 not found. It will be auto-installed if auto_install=true")
    end

    if vim.trim(flask_installed) == "1" then
      _ok("Flask installed")
    else
      _warn("Flask not found. It will be auto-installed if auto_install=true")
    end
  end

  -- Show config
  local ok_cfg, mod = pcall(require, "latex_sympy")
  if ok_cfg and mod.get_config then
    local cfg = mod.get_config()
    _ok(string.format("Configured python=%s, port=%s, auto_install=%s", tostring(cfg.python), tostring(cfg.port), tostring(cfg.auto_install)))
  else
    _warn("Could not load latex_sympy config")
  end
end

return M


