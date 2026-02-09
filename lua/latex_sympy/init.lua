local M = {}

local DEFAULT_CONFIG = {
  python = "python3",
  auto_install = false,
  port = 7395,
  enable_python_eval = false,
  notify_startup = true,
  startup_notify_once = true,
  notify_info = false,
  server_start_mode = "on_demand", -- "on_demand" | "on_activate"
  timeout_ms = 5000,
  preview_before_apply = false,
  preview_max_chars = 160,
  drop_stale_results = true,
  default_keymaps = true,
  keymap_prefix = "<leader>l", -- visual mode prefix
  normal_keymap_prefix = "<leader>x",
  respect_existing_keymaps = true,
  picker_backend = "vim_ui", -- "vim_ui" | "auto" | "snacks"
  picker_select = nil, -- fun(items, opts, on_choice)
  picker_input = nil, -- fun(opts, on_confirm)
  picker_filter_enabled = false,
  picker_filter_prompt = "latex_sympy filter (optional):",
  picker_show_unavailable = false,
  picker_guided_args = "all", -- "off" | "all"
  picker_guided_args_allow_raw = true,
  notify_success = true,
  notify_success_max_chars = 120,
}

local OP_NAMES = {
  div = true,
  gcd = true,
  sqf = true,
  groebner = true,
  resultant = true,
  summation = true,
  product = true,
  binomial = true,
  perm = true,
  comb = true,
  partition = true,
  subsets = true,
  totient = true,
  mobius = true,
  divisors = true,
  logic_simplify = true,
  sat = true,
  jordan = true,
  svd = true,
  cholesky = true,
  symbol = true,
  symbols = true,
  symbols_reset = true,
  geometry = true,
  intersect = true,
  tangent = true,
  similar = true,
  units = true,
  mechanics = true,
  quantum = true,
  optics = true,
  pauli = true,
  dist = true,
  p = true,
  e = true,
  var = true,
  density = true,
  simplify = true,
  trigsimp = true,
  ratsimp = true,
  powsimp = true,
  apart = true,
  subs = true,
  solveset = true,
  linsolve = true,
  nonlinsolve = true,
  rsolve = true,
  diophantine = true,
  solve = true,
  diff = true,
  integrate = true,
  limit = true,
  series = true,
  nsolve = true,
  dsolve = true,
  solve_system = true,
  det = true,
  inv = true,
  transpose = true,
  rank = true,
  eigenvals = true,
  eigenvects = true,
  nullspace = true,
  charpoly = true,
  lu = true,
  qr = true,
  mat_solve = true,
  isprime = true,
  factorint = true,
  primerange = true,
}

local SOLVESET_DOMAINS = {
  C = true,
  R = true,
  Z = true,
  N = true,
}

local GROEBNER_ORDERS = {
  lex = true,
  grlex = true,
  grevlex = true,
}

local LOGIC_FORMS = {
  simplify = true,
  cnf = true,
  dnf = true,
}

local SYMBOL_ASSUMPTION_KEYS = {
  commutative = true,
  real = true,
  integer = true,
  positive = true,
  nonnegative = true,
}

local DIST_KINDS = {
  normal = true,
  uniform = true,
  bernoulli = true,
  binomial = true,
  hypergeometric = true,
}

local OP_ARGS_HINTS = {
  div = "[var]",
  gcd = "[var]",
  sqf = "[var]",
  groebner = "<var...> [order]",
  resultant = "<var>",
  summation = "<var> <lower> <upper>",
  product = "<var> <lower> <upper>",
  binomial = "<n> <k>",
  perm = "<n> [k]",
  comb = "<n> <k>",
  partition = "<n>",
  subsets = "[k]",
  divisors = "[proper]",
  logic_simplify = "[form]",
  symbol = "<name> [assumption=bool ...]",
  units = "simplify | convert <target>",
  mechanics = "euler_lagrange <q...>",
  quantum = "dagger | commutator <expr2>",
  optics = "lens <k=v> <k=v> | mirror <k=v> <k=v> | refraction <incident> <n1> <n2>",
  pauli = "simplify",
  dist = "<kind> <name> <params...>",
  solveset = "[var] [domain]",
  solve = "[var ...]",
  solve_system = "[var ...]",
  diff = "[var] [order] | x 2 y 1",
  integrate = "[var] [lower] [upper]",
  limit = "<var> <point> [dir]",
  series = "<var> <point> <order>",
  nsolve = "<var> <guess> [guess2]",
  dsolve = "[func]",
  rsolve = "[func]",
  diophantine = "[var ...]",
  linsolve = "[var ...]",
  nonlinsolve = "[var ...]",
  charpoly = "[var]",
  primerange = "<start> <stop>",
  apart = "[var]",
  subs = "<symbol>=<value> [<symbol>=<value> ...]",
}

local OP_DESCRIPTIONS = {
  div = "Polynomial division quotient and remainder",
  gcd = "Greatest common divisor of two expressions",
  sqf = "Square-free decomposition",
  groebner = "Groebner basis for selected polynomials",
  resultant = "Resultant of two expressions",
  summation = "Finite symbolic summation",
  product = "Finite symbolic product",
  binomial = "Binomial coefficient n choose k",
  perm = "Permutation count nPk",
  comb = "Combination count nCk",
  partition = "Partition function p(n)",
  subsets = "List subsets of selected finite set",
  totient = "Euler totient function phi(n)",
  mobius = "Mobius function mu(n)",
  divisors = "List divisors of an integer",
  logic_simplify = "Simplify boolean expression",
  sat = "Find satisfiable assignment for boolean expression",
  jordan = "Jordan form decomposition",
  svd = "Singular value decomposition",
  cholesky = "Cholesky matrix decomposition",
  symbol = "Register symbol with assumptions",
  symbols = "List registered symbols",
  symbols_reset = "Clear registered symbols",
  geometry = "Normalize geometry constructors",
  intersect = "Intersection of two geometry objects",
  tangent = "Tangent relation between two geometry objects",
  similar = "Similarity check for two geometry objects",
  units = "Unit simplify or conversion workflow",
  mechanics = "Mechanics workflow helpers",
  quantum = "Quantum helpers (dagger/commutator)",
  optics = "Gaussian optics helpers",
  pauli = "Simplify Pauli algebra expression",
  dist = "Register a random variable distribution",
  p = "Probability of selected condition",
  e = "Expected value of selected expression",
  var = "Variance of selected expression",
  density = "Density of selected expression",
  simplify = "General symbolic simplification",
  trigsimp = "Trigonometric simplification",
  ratsimp = "Rational simplification",
  powsimp = "Power simplification",
  apart = "Partial fraction decomposition",
  subs = "Substitute symbols with values",
  solveset = "Solve equation as a symbolic set",
  linsolve = "Solve linear equation system",
  nonlinsolve = "Solve nonlinear equation system",
  rsolve = "Solve recurrence relation",
  diophantine = "Solve Diophantine equation",
  solve = "Solve equation(s) for unknowns",
  diff = "Differentiate expression",
  integrate = "Integrate expression",
  limit = "Compute directional limit",
  series = "Series expansion",
  nsolve = "Numerical root solving",
  dsolve = "Solve differential equation",
  solve_system = "Solve system from equation list",
  det = "Determinant of matrix",
  inv = "Inverse of matrix",
  transpose = "Transpose of matrix",
  rank = "Rank of matrix",
  eigenvals = "Eigenvalues of matrix",
  eigenvects = "Eigenvectors of matrix",
  nullspace = "Nullspace basis of matrix",
  charpoly = "Characteristic polynomial",
  lu = "LU decomposition",
  qr = "QR decomposition",
  mat_solve = "Solve linear system from augmented matrix",
  isprime = "Primality test for integer",
  factorint = "Prime factorization map",
  primerange = "List primes in an integer range",
}

local OP_REQUIRES_ARGS = {
  resultant = true,
  summation = true,
  product = true,
  binomial = true,
  perm = true,
  comb = true,
  partition = true,
  symbol = true,
  units = true,
  mechanics = true,
  quantum = true,
  optics = true,
  pauli = true,
  dist = true,
  limit = true,
  series = true,
  nsolve = true,
  primerange = true,
}

local PICKER_GUIDED_ARGS_SCHEMA = {
  solve = {
    fields = {
      { key = "vars", prompt = "variables (space-separated)", optional = true, split = true },
    },
  },
  solve_system = {
    fields = {
      { key = "vars", prompt = "variables (space-separated)", optional = true, split = true },
    },
  },
  diff = {
    fields = {
      { key = "var", prompt = "variable", optional = true },
      { key = "order", prompt = "order (optional)", optional = true },
    },
  },
  integrate = {
    fields = {
      { key = "var", prompt = "variable", optional = true },
      { key = "lower", prompt = "lower bound (optional)", optional = true },
      { key = "upper", prompt = "upper bound (optional)", optional = true },
    },
  },
  limit = {
    fields = {
      { key = "var", prompt = "variable", optional = false },
      { key = "point", prompt = "point", optional = false },
      { key = "dir", prompt = "direction (+, -, +-)", optional = true },
    },
  },
  series = {
    fields = {
      { key = "var", prompt = "variable", optional = false },
      { key = "point", prompt = "point", optional = false },
      { key = "order", prompt = "order (positive integer)", optional = false },
    },
  },
  solveset = {
    fields = {
      { key = "var", prompt = "variable (optional)", optional = true },
      { key = "domain", prompt = "domain (C, R, Z, N; optional)", optional = true },
    },
  },
  linsolve = {
    fields = {
      { key = "vars", prompt = "variables (space-separated; optional)", optional = true, split = true },
    },
  },
  nonlinsolve = {
    fields = {
      { key = "vars", prompt = "variables (space-separated; optional)", optional = true, split = true },
    },
  },
  rsolve = {
    fields = {
      { key = "func", prompt = "target function (optional)", optional = true },
    },
  },
  diophantine = {
    fields = {
      { key = "vars", prompt = "variables (space-separated; optional)", optional = true, split = true },
    },
  },
  nsolve = {
    fields = {
      { key = "var", prompt = "variable", optional = false },
      { key = "guess", prompt = "initial guess", optional = false },
      { key = "guess2", prompt = "second guess (optional)", optional = true },
    },
  },
  dsolve = {
    fields = {
      { key = "func", prompt = "target function (optional)", optional = true },
    },
  },
  charpoly = {
    fields = {
      { key = "var", prompt = "symbol (optional)", optional = true },
    },
  },
  primerange = {
    fields = {
      { key = "start", prompt = "start (integer)", optional = false },
      { key = "stop", prompt = "stop (integer)", optional = false },
    },
  },
  apart = {
    fields = {
      { key = "var", prompt = "variable (optional)", optional = true },
    },
  },
  subs = {
    fields = {
      { key = "assignments", prompt = "assignments (e.g. x=2 y=3)", optional = false, split = true },
    },
  },
  div = {
    fields = {
      { key = "var", prompt = "variable (optional)", optional = true },
    },
  },
  gcd = {
    fields = {
      { key = "var", prompt = "variable (optional)", optional = true },
    },
  },
  sqf = {
    fields = {
      { key = "var", prompt = "variable (optional)", optional = true },
    },
  },
  groebner = {
    fields = {
      { key = "vars", prompt = "variables (space-separated)", optional = false, split = true },
      { key = "order", prompt = "order (lex, grlex, grevlex; optional)", optional = true },
    },
  },
  resultant = {
    fields = {
      { key = "var", prompt = "variable", optional = false },
    },
  },
  summation = {
    fields = {
      { key = "var", prompt = "summation variable", optional = false },
      { key = "lower", prompt = "lower bound", optional = false },
      { key = "upper", prompt = "upper bound", optional = false },
    },
  },
  product = {
    fields = {
      { key = "var", prompt = "product variable", optional = false },
      { key = "lower", prompt = "lower bound", optional = false },
      { key = "upper", prompt = "upper bound", optional = false },
    },
  },
  binomial = {
    fields = {
      { key = "n", prompt = "n", optional = false },
      { key = "k", prompt = "k", optional = false },
    },
  },
  perm = {
    fields = {
      { key = "n", prompt = "n", optional = false },
      { key = "k", prompt = "k (optional)", optional = true },
    },
  },
  comb = {
    fields = {
      { key = "n", prompt = "n", optional = false },
      { key = "k", prompt = "k", optional = false },
    },
  },
  partition = {
    fields = {
      { key = "n", prompt = "n", optional = false },
    },
  },
  subsets = {
    fields = {
      { key = "k", prompt = "subset size k (optional)", optional = true },
    },
  },
  divisors = {
    fields = {
      { key = "proper", prompt = "proper (true/false; optional)", optional = true },
    },
  },
  logic_simplify = {
    fields = {
      { key = "form", prompt = "form (simplify, cnf, dnf; optional)", optional = true },
    },
  },
  symbol = {
    fields = {
      { key = "name", prompt = "symbol name", optional = false },
      { key = "assumptions", prompt = "assumptions (e.g. real=true integer=false; optional)", optional = true, split = true },
    },
  },
  units = {
    fields = {
      { key = "action", prompt = "action (simplify or convert)", optional = false },
      { key = "target", prompt = "target unit (needed for convert)", optional = true },
    },
  },
  mechanics = {
    prefix_tokens = { "euler_lagrange" },
    fields = {
      { key = "qs", prompt = "coordinates q... (space-separated)", optional = false, split = true },
    },
  },
  quantum = {
    fields = {
      { key = "action", prompt = "action (dagger or commutator)", optional = false },
      { key = "expr2", prompt = "second expression (for commutator)", optional = true },
    },
  },
  optics = {
    fields = {
      { key = "action", prompt = "action (lens, mirror, refraction)", optional = false },
      { key = "arg1", prompt = "arg1", optional = true },
      { key = "arg2", prompt = "arg2", optional = true },
      { key = "arg3", prompt = "arg3 (optional)", optional = true },
    },
  },
  pauli = {
    prefix_tokens = { "simplify" },
    fields = {},
  },
  dist = {
    fields = {
      { key = "kind", prompt = "kind (normal, uniform, bernoulli, binomial, hypergeometric)", optional = false },
      { key = "name", prompt = "symbol name", optional = false },
      { key = "params", prompt = "distribution params (space-separated; optional)", optional = true, split = true },
    },
  },
}

local function clone(tbl)
  if vim.deepcopy then
    return vim.deepcopy(tbl)
  end
  return vim.tbl_deep_extend("force", {}, tbl)
end

local function coerce_positive_int(value, fallback)
  local num = tonumber(value)
  if not num then
    return fallback
  end
  num = math.floor(num)
  if num <= 0 then
    return fallback
  end
  return num
end

local function normalize_mode(mode)
  if mode == "on_activate" then
    return "on_activate"
  end
  return "on_demand"
end

local function normalize_keymap_prefix(prefix)
  if type(prefix) ~= "string" then
    return DEFAULT_CONFIG.keymap_prefix
  end
  local value = vim.trim(prefix)
  if value == "" then
    return DEFAULT_CONFIG.keymap_prefix
  end
  return value
end

local function normalize_picker_filter_prompt(value)
  if type(value) ~= "string" then
    return DEFAULT_CONFIG.picker_filter_prompt
  end
  local prompt = vim.trim(value)
  if prompt == "" then
    return DEFAULT_CONFIG.picker_filter_prompt
  end
  return prompt
end

local function normalize_picker_guided_args(value)
  if type(value) ~= "string" then
    return DEFAULT_CONFIG.picker_guided_args
  end
  local mode = string.lower(vim.trim(value))
  if mode == "off" then
    return "off"
  end
  return "all"
end

local function normalize_error(err)
  local message = vim.trim(tostring(err or "Unknown error"))
  if message == "" then
    return "Unknown error"
  end
  if message:find("Could not resolve host", 1, true) then
    return "Network error while contacting server"
  end
  if message:find("Couldn't connect to server", 1, true) or message:find("Failed to connect", 1, true) then
    return "Server is not reachable"
  end
  if message:find("Operation timed out", 1, true) or message:find("timed out", 1, true) then
    return "Request timed out"
  end
  if message:find("Invalid JSON", 1, true) then
    return "Invalid response from server"
  end
  return message
end

local function empty_object()
  if vim.empty_dict then
    return vim.empty_dict()
  end
  return {}
end

local function normalize_params_for_payload(params)
  if type(params) ~= "table" then
    return empty_object()
  end
  if next(params) == nil then
    return empty_object()
  end
  return params
end

-- Internal state
local server_job_id = nil
local plugin_dir = nil
local intentional_stop = false
local server_ready = false
local server_starting = false
local pending_server_callbacks = {}
local last_server_stderr = ""
local auto_install_triggered = false

local current_config = clone(DEFAULT_CONFIG)
local configured = false
local activated_for_tex = false
local commands_registered = false
local startup_notified = false
local last_operation = nil
local trailing_bang_hint_notified = false
local applied_default_keymaps = {}

local request_token_counter = 0
local latest_request_token_by_buf = {}

local ns_id = vim.api.nvim_create_namespace("latex_sympy")

local LOG = {}
function LOG.info(message, opts)
  local force = type(opts) == "table" and opts.force
  if not force and not current_config.notify_info then
    return
  end
  vim.notify("latex_sympy: " .. tostring(message), vim.log.levels.INFO)
end
function LOG.warn(message)
  vim.notify("latex_sympy: " .. tostring(message), vim.log.levels.WARN)
end
function LOG.error(message)
  vim.notify("latex_sympy: " .. tostring(message), vim.log.levels.ERROR)
end

local DEFAULT_KEYMAPS = {
  x = {
    { suffix = "e", rhs = ":<C-u>LatexSympyEqual<CR>", desc = "latex_sympy equal" },
    { suffix = "r", rhs = ":<C-u>LatexSympyReplace<CR>", desc = "latex_sympy replace" },
    { suffix = "n", rhs = ":<C-u>LatexSympyNumerical<CR>", desc = "latex_sympy numerical" },
    { suffix = "f", rhs = ":<C-u>LatexSympyFactor<CR>", desc = "latex_sympy factor" },
    { suffix = "x", rhs = ":<C-u>LatexSympyExpand<CR>", desc = "latex_sympy expand" },
    { suffix = "m", rhs = ":<C-u>LatexSympyMatrixRREF<CR>", desc = "latex_sympy matrix rref" },
    { suffix = "o", rhs = ":<C-u>LatexSympyOp ", desc = "latex_sympy op" },
    { suffix = "s", rhs = ":<C-u>LatexSympySolve<CR>", desc = "latex_sympy solve" },
    { suffix = "d", rhs = ":<C-u>LatexSympyDiff<CR>", desc = "latex_sympy diff" },
    { suffix = "i", rhs = ":<C-u>LatexSympyIntegrate<CR>", desc = "latex_sympy integrate" },
    { suffix = "t", rhs = ":<C-u>LatexSympyDet<CR>", desc = "latex_sympy det" },
    { suffix = "v", rhs = ":<C-u>LatexSympyInv<CR>", desc = "latex_sympy inv" },
    { suffix = "a", rhs = ":<C-u>LatexSympyRepeat<CR>", desc = "latex_sympy repeat op" },
    { suffix = "p", rhs = ":<C-u>LatexSympyPick<CR>", desc = "latex_sympy picker" },
  },
  n = {
    { suffix = "S", rhs = "<Cmd>LatexSympyStatus<CR>", desc = "latex_sympy status" },
    { suffix = "1", rhs = "<Cmd>LatexSympyStart<CR>", desc = "latex_sympy start server" },
    { suffix = "0", rhs = "<Cmd>LatexSympyStop<CR>", desc = "latex_sympy stop server" },
    { suffix = "R", rhs = "<Cmd>LatexSympyRestart<CR>", desc = "latex_sympy restart server" },
    { suffix = "V", rhs = "<Cmd>LatexSympyVariances<CR>", desc = "latex_sympy variances" },
    { suffix = "Z", rhs = "<Cmd>LatexSympyReset<CR>", desc = "latex_sympy reset variances" },
    { suffix = "C", rhs = "<Cmd>LatexSympyToggleComplex<CR>", desc = "latex_sympy toggle complex" },
  },
}

local function json_encode(tbl)
  if vim.json and vim.json.encode then
    return vim.json.encode(tbl)
  end
  return vim.fn.json_encode(tbl)
end

local function json_decode(str)
  if vim.json and vim.json.decode then
    return vim.json.decode(str)
  end
  return vim.fn.json_decode(str)
end

local function detect_plugin_dir()
  if plugin_dir then
    return plugin_dir
  end
  local info = debug.getinfo(1, "S")
  local src = info and info.source or ""
  if vim.startswith(src, "@") then
    src = src:sub(2)
  end
  plugin_dir = vim.fn.fnamemodify(src, ":p:h:h:h")
  return plugin_dir
end

local function system_async(cmd, args, on_exit)
  if vim.system then
    vim.system(vim.list_extend({ cmd }, args or {}), { text = true }, function(res)
      local code = res.code or res.signal or 0
      on_exit(code, res.stdout or "", res.stderr or "")
    end)
    return
  end

  local output = {}
  local errout = {}
  vim.fn.jobstart(vim.list_extend({ cmd }, args or {}), {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        table.insert(output, table.concat(data, "\n"))
      end
    end,
    on_stderr = function(_, data)
      if data then
        table.insert(errout, table.concat(data, "\n"))
      end
    end,
    on_exit = function(_, code)
      on_exit(code or 0, table.concat(output, "\n"), table.concat(errout, "\n"))
    end,
  })
end

local function is_server_running()
  return server_job_id ~= nil and server_job_id > 0
end

local function flush_server_callbacks(ok, message)
  if #pending_server_callbacks == 0 then
    return
  end
  local callbacks = pending_server_callbacks
  pending_server_callbacks = {}
  for _, cb in ipairs(callbacks) do
    if cb then
      vim.schedule(function()
        cb(ok, message)
      end)
    end
  end
end

local function probe_server_health(on_result)
  local url = string.format("http://127.0.0.1:%d/health", current_config.port)
  local args = { "-sS", "--max-time", "1", url }
  system_async("curl", args, function(code, stdout, _)
    if code ~= 0 then
      on_result(false)
      return
    end
    local ok, result = pcall(json_decode, stdout)
    if not ok or type(result) ~= "table" then
      on_result(false)
      return
    end
    if result.error and result.error ~= "" then
      on_result(false)
      return
    end
    on_result(result.data == "ok")
  end)
end

local function wait_for_server_ready(on_done, attempt)
  attempt = attempt or 1
  if not is_server_running() then
    on_done(false, "Python server is not running")
    return
  end

  probe_server_health(function(ok)
    if ok then
      on_done(true)
      return
    end
    if attempt >= 30 then
      on_done(false, "Timed out waiting for latex_sympy server")
      return
    end
    vim.defer_fn(function()
      wait_for_server_ready(on_done, attempt + 1)
    end, 100)
  end)
end

local function maybe_trigger_auto_install()
  if not current_config.auto_install or auto_install_triggered then
    return
  end
  auto_install_triggered = true
  system_async(current_config.python, {
    "-m",
    "pip",
    "install",
    "--upgrade",
    "latex2sympy2",
    "Flask",
  }, function(_, _, _) end)
end

local function start_server_process()
  if is_server_running() then
    return true
  end

  local root = detect_plugin_dir()
  local server_path = vim.fn.fnamemodify(root .. "/server.py", ":p")
  if not vim.loop.fs_stat(server_path) then
    return false, "server.py not found at " .. server_path
  end

  maybe_trigger_auto_install()
  last_server_stderr = ""

  server_job_id = vim.fn.jobstart({ current_config.python, server_path }, {
    cwd = root,
    env = {
      LATEX_SYMPY_PORT = tostring(current_config.port),
      LATEX_SYMPY_ENABLE_PYTHON = current_config.enable_python_eval and "1" or "0",
    },
    on_stderr = function(_, data)
      if not data then
        return
      end
      for _, line in ipairs(data) do
        if line and line ~= "" then
          last_server_stderr = line
        end
      end
    end,
    on_exit = function(_, code)
      local stopped_intentionally = intentional_stop
      intentional_stop = false
      server_job_id = nil
      server_ready = false
      server_starting = false

      if stopped_intentionally then
        return
      end

      local message = "Python server exited"
      if code and code ~= 0 then
        message = string.format("Python server exited (code %s)", tostring(code))
      end
      if last_server_stderr ~= "" then
        message = message .. ": " .. last_server_stderr
      end
      LOG.error(message)
      flush_server_callbacks(false, message)
    end,
  })

  if server_job_id <= 0 then
    server_job_id = nil
    return false, "failed to start Python server"
  end

  return true
end

local function ensure_server_running(callback)
  if callback then
    table.insert(pending_server_callbacks, callback)
  end

  if is_server_running() and server_ready then
    flush_server_callbacks(true)
    return
  end

  if server_starting then
    return
  end

  server_starting = true
  local ok, err = start_server_process()
  if not ok then
    server_starting = false
    flush_server_callbacks(false, err)
    return
  end

  wait_for_server_ready(function(ready_ok, ready_err)
    server_starting = false
    server_ready = ready_ok
    if not ready_ok then
      M.stop_server({ silent = true, skip_flush = true })
    end
    flush_server_callbacks(ready_ok, ready_err)
  end)
end

local function timeout_seconds_string(timeout_ms)
  local timeout = coerce_positive_int(timeout_ms, DEFAULT_CONFIG.timeout_ms)
  local secs = timeout / 1000
  return string.format("%.3f", secs)
end

local function http_request(method, path, body_payload, on_success, on_error, request_opts)
  local url = string.format("http://127.0.0.1:%d%s", current_config.port, path)
  local args = { "-sS", "--max-time", timeout_seconds_string((request_opts or {}).timeout_ms), "-X", method, url }

  if method == "POST" then
    local payload = json_encode(body_payload or {})
    table.insert(args, "-H")
    table.insert(args, "Content-Type: application/json")
    table.insert(args, "-d")
    table.insert(args, payload)
  end

  system_async("curl", args, function(code, stdout, stderr)
    if code ~= 0 then
      if on_error then
        vim.schedule(function()
          if stderr and vim.trim(stderr) ~= "" then
            on_error(normalize_error(stderr))
          else
            on_error(normalize_error("HTTP error, code " .. tostring(code)))
          end
        end)
      end
      return
    end

    local ok, result = pcall(json_decode, stdout)
    if not ok or type(result) ~= "table" then
      if on_error then
        vim.schedule(function()
          on_error(normalize_error("Invalid JSON from server"))
        end)
      end
      return
    end

    if result.error and result.error ~= "" then
      if on_error then
        vim.schedule(function()
          on_error(normalize_error(result.error))
        end)
      end
      return
    end

    if on_success then
      local payload = (result.data ~= nil) and result.data or result
      vim.schedule(function()
        on_success(payload)
      end)
    end
  end)
end

local function post_data(path, data, on_success, on_error, request_opts)
  http_request("POST", path, { data = data }, on_success, on_error, request_opts)
end

local function post_json(path, payload, on_success, on_error, request_opts)
  http_request("POST", path, payload, on_success, on_error, request_opts)
end

local function get(path, on_success, on_error, request_opts)
  http_request("GET", path, nil, on_success, on_error, request_opts)
end

local function get_visual_range_or_lines(opts)
  local buf = 0
  local start_row, start_col, end_row, end_col
  local using_marks = false

  do
    local m1 = vim.api.nvim_buf_get_mark(buf, "<")
    local m2 = vim.api.nvim_buf_get_mark(buf, ">")
    if m1 and m2 and (m1[1] ~= 0 or m2[1] ~= 0) then
      using_marks = true
      start_row, start_col = m1[1] - 1, m1[2]
      end_row, end_col = m2[1] - 1, m2[2]
    end
  end

  if not using_marks and opts and opts.range and opts.range > 0 then
    start_row = (opts.line1 or 1) - 1
    end_row = (opts.line2 or (opts.line1 or 1)) - 1
    start_col = 0
    local last_line = vim.api.nvim_buf_get_lines(buf, end_row, end_row + 1, false)[1] or ""
    end_col = #last_line
  end

  if start_row == nil then
    return nil, "No selection detected. Use visual selection or provide a range."
  end

  local line_count = vim.api.nvim_buf_line_count(buf)
  start_row = math.max(0, math.min(start_row or 0, line_count - 1))
  end_row = math.max(0, math.min(end_row or 0, line_count - 1))

  local sline = vim.api.nvim_buf_get_lines(buf, start_row, start_row + 1, false)[1] or ""
  local eline = vim.api.nvim_buf_get_lines(buf, end_row, end_row + 1, false)[1] or ""

  start_col = math.max(0, math.min(start_col or 0, #sline))
  end_col = math.max(0, math.min(end_col or 0, #eline))

  if start_row > end_row or (start_row == end_row and start_col > end_col) then
    start_row, start_col, end_row, end_col = end_row, end_col, start_row, start_col
  end

  local lines = vim.api.nvim_buf_get_text(buf, start_row, start_col, end_row, end_col, {})
  local start_mark = vim.api.nvim_buf_set_extmark(buf, ns_id, start_row, start_col, { right_gravity = false })
  local end_mark = vim.api.nvim_buf_set_extmark(buf, ns_id, end_row, end_col, { right_gravity = true })

  return {
    buf = buf,
    start_row = start_row,
    start_col = start_col,
    end_row = end_row,
    end_col = end_col,
    start_mark = start_mark,
    end_mark = end_mark,
    text = table.concat(lines, "\n"),
  }
end

local function cleanup_range_marks(range)
  if range.start_mark then
    pcall(vim.api.nvim_buf_del_extmark, range.buf, ns_id, range.start_mark)
  end
  if range.end_mark then
    pcall(vim.api.nvim_buf_del_extmark, range.buf, ns_id, range.end_mark)
  end
end

local function resolve_current_range(range)
  local sr, sc = range.start_row, range.start_col
  local er, ec = range.end_row, range.end_col

  if range.start_mark then
    local pos = vim.api.nvim_buf_get_extmark_by_id(range.buf, ns_id, range.start_mark, {})
    if pos and #pos == 2 then
      sr, sc = pos[1], pos[2]
    end
  end

  if range.end_mark then
    local pos = vim.api.nvim_buf_get_extmark_by_id(range.buf, ns_id, range.end_mark, {})
    if pos and #pos == 2 then
      er, ec = pos[1], pos[2]
    end
  end

  local line_count = vim.api.nvim_buf_line_count(range.buf)
  sr = math.max(0, math.min(sr or 0, line_count - 1))
  er = math.max(0, math.min(er or 0, line_count - 1))

  local sline = vim.api.nvim_buf_get_lines(range.buf, sr, sr + 1, false)[1] or ""
  local eline = vim.api.nvim_buf_get_lines(range.buf, er, er + 1, false)[1] or ""

  sc = math.max(0, math.min(sc or 0, #sline))
  ec = math.max(0, math.min(ec or 0, #eline))

  if sr > er or (sr == er and sc > ec) then
    sr, sc, er, ec = er, ec, sr, sc
  end

  return sr, sc, er, ec
end

local function replace_range(range, new_text)
  local replacement = {}
  for s in tostring(new_text):gmatch("([^\n]*)\n?") do
    table.insert(replacement, s)
  end

  local sr, sc, er, ec = resolve_current_range(range)
  vim.api.nvim_buf_set_text(range.buf, sr, sc, er, ec, replacement)
  cleanup_range_marks(range)
end

local function insert_after_range(range, insert_text)
  local _, _, er, ec = resolve_current_range(range)
  vim.api.nvim_buf_set_text(range.buf, er, ec, er, ec, { insert_text })
  cleanup_range_marks(range)
end

local function mark_request_for_buffer(buf)
  request_token_counter = request_token_counter + 1
  latest_request_token_by_buf[buf] = request_token_counter
  return request_token_counter
end

local function is_stale_request(buf, token)
  if not current_config.drop_stale_results then
    return false
  end
  return latest_request_token_by_buf[buf] ~= token
end

local function preview_text(text)
  local max_chars = coerce_positive_int(current_config.preview_max_chars, DEFAULT_CONFIG.preview_max_chars)
  local result = tostring(text)
  if #result <= max_chars then
    return result
  end
  if max_chars <= 3 then
    return result:sub(1, max_chars)
  end
  return result:sub(1, max_chars - 3) .. "..."
end

local function truncate_single_line(text, max_chars)
  local normalized = tostring(text or ""):gsub("%s+", " ")
  normalized = vim.trim(normalized)
  if normalized == "" then
    normalized = "(empty result)"
  end
  if #normalized <= max_chars then
    return normalized
  end
  if max_chars <= 3 then
    return normalized:sub(1, max_chars)
  end
  return normalized:sub(1, max_chars - 3) .. "..."
end

local function notify_success_result(context, result_text)
  if not current_config.notify_success then
    return
  end
  local max_chars = coerce_positive_int(current_config.notify_success_max_chars, DEFAULT_CONFIG.notify_success_max_chars)
  local preview = truncate_single_line(result_text, max_chars)
  local command_context = vim.trim(tostring(context or "command"))
  if command_context == "" then
    command_context = "command"
  end
  vim.notify(string.format("latex_sympy: success (%s): %s", command_context, preview), vim.log.levels.INFO)
end

local function request_preview_approval(result_text, on_decision)
  if not current_config.preview_before_apply then
    on_decision(true)
    return
  end
  if not vim.ui or not vim.ui.select then
    on_decision(true)
    return
  end

  local truncated = preview_text(result_text)
  vim.schedule(function()
    vim.ui.select({ "Apply", "Cancel" }, {
      prompt = "latex_sympy preview: " .. truncated,
    }, function(choice)
      on_decision(choice == "Apply")
    end)
  end)
end

local function with_server(callback)
  ensure_server_running(function(ok, err)
    if not ok then
      LOG.error(normalize_error(err or "Failed to start latex_sympy server"))
      return
    end
    callback()
  end)
end

local function run_range_request(opts, request_sender, apply_result, meta)
  local range, err = get_visual_range_or_lines(opts)
  if not range then
    LOG.error(err)
    return
  end

  local request_token = mark_request_for_buffer(range.buf)

  with_server(function()
    request_sender(range, function(data)
      if is_stale_request(range.buf, request_token) then
        cleanup_range_marks(range)
        return
      end

      local rendered = tostring(data)
      request_preview_approval(rendered, function(should_apply)
        if is_stale_request(range.buf, request_token) then
          cleanup_range_marks(range)
          return
        end

        if not should_apply then
          cleanup_range_marks(range)
          return
        end

        apply_result(range, rendered)
        notify_success_result(meta and meta.success_context, rendered)
      end)
    end, function(request_error)
      if is_stale_request(range.buf, request_token) then
        cleanup_range_marks(range)
        return
      end
      LOG.error(normalize_error(request_error))
      cleanup_range_marks(range)
    end)
  end)
end

local function parse_int(value)
  local num = tonumber(value)
  if not num then
    return nil
  end
  if math.floor(num) ~= num then
    return nil
  end
  return math.floor(num)
end

local function parse_bool_token(value)
  if type(value) ~= "string" then
    return nil
  end
  local token = string.lower(vim.trim(value))
  if token == "true" or token == "1" or token == "yes" then
    return true
  end
  if token == "false" or token == "0" or token == "no" then
    return false
  end
  return nil
end

local function parse_operation_args(op_name, args)
  local op = string.lower(tostring(op_name or ""))
  if not OP_NAMES[op] then
    return nil, "Unknown op: " .. tostring(op_name)
  end

  local params = {}
  local count = #args

  if op == "div" or op == "gcd" or op == "sqf" then
    if count > 1 then
      return nil, op .. " expects: [var]"
    end
    if count == 1 then
      params.var = args[1]
    end
    return params
  end

  if op == "groebner" then
    if count < 1 then
      return nil, "groebner expects: <var...> [order]"
    end

    local last = string.lower(vim.trim(args[count] or ""))
    local order_count = count
    if GROEBNER_ORDERS[last] and count > 1 then
      params.order = last
      order_count = count - 1
    end
    if order_count < 1 then
      return nil, "groebner expects at least one variable"
    end

    params.vars = {}
    for index = 1, order_count do
      table.insert(params.vars, args[index])
    end
    return params
  end

  if op == "resultant" then
    if count ~= 1 then
      return nil, "resultant expects: <var>"
    end
    params.var = args[1]
    return params
  end

  if op == "summation" or op == "product" then
    if count ~= 3 then
      return nil, op .. " expects: <var> <lower> <upper>"
    end
    params.var = args[1]
    params.lower = args[2]
    params.upper = args[3]
    return params
  end

  if op == "binomial" or op == "comb" then
    if count ~= 2 then
      return nil, op .. " expects: <n> <k>"
    end
    params.n = args[1]
    params.k = args[2]
    return params
  end

  if op == "perm" then
    if count ~= 1 and count ~= 2 then
      return nil, "perm expects: <n> [k]"
    end
    params.n = args[1]
    if count == 2 then
      params.k = args[2]
    end
    return params
  end

  if op == "partition" then
    if count ~= 1 then
      return nil, "partition expects: <n>"
    end
    params.n = args[1]
    return params
  end

  if op == "subsets" then
    if count > 1 then
      return nil, "subsets expects: [k]"
    end
    if count == 1 then
      local k = parse_int(args[1])
      if not k or k < 0 then
        return nil, "subsets expects a non-negative integer k"
      end
      params.k = k
    end
    return params
  end

  if op == "totient" or op == "mobius" then
    if count ~= 0 then
      return nil, op .. " does not accept extra arguments"
    end
    return params
  end

  if op == "divisors" then
    if count > 1 then
      return nil, "divisors expects: [proper]"
    end
    if count == 1 then
      local parsed = parse_bool_token(args[1])
      if parsed == nil then
        return nil, "divisors expects proper=true|false"
      end
      params.proper = parsed
    end
    return params
  end

  if op == "logic_simplify" then
    if count > 1 then
      return nil, "logic_simplify expects: [form]"
    end
    if count == 1 then
      local form = string.lower(vim.trim(args[1] or ""))
      if not LOGIC_FORMS[form] then
        return nil, "logic_simplify form must be one of: simplify, cnf, dnf"
      end
      params.form = form
    end
    return params
  end

  if op == "sat" then
    if count ~= 0 then
      return nil, "sat does not accept extra arguments"
    end
    return params
  end

  if op == "jordan" or op == "svd" or op == "cholesky" then
    if count ~= 0 then
      return nil, op .. " does not accept extra arguments"
    end
    return params
  end

  if op == "symbol" then
    if count < 1 then
      return nil, "symbol expects: <name> [assumption=bool ...]"
    end
    params.name = args[1]
    if count == 1 then
      return params
    end

    params.assumptions = {}
    for index = 2, count do
      local token = tostring(args[index] or "")
      local eq_pos = string.find(token, "=", 1, true)
      if not eq_pos or eq_pos <= 1 or eq_pos >= #token then
        return nil, "Invalid assumption token: " .. token
      end
      local key = string.lower(vim.trim(token:sub(1, eq_pos - 1)))
      if not SYMBOL_ASSUMPTION_KEYS[key] then
        return nil, "Unknown symbol assumption: " .. key
      end
      local parsed = parse_bool_token(token:sub(eq_pos + 1))
      if parsed == nil then
        return nil, "Invalid assumption value for " .. key
      end
      params.assumptions[key] = parsed
    end
    return params
  end

  if op == "symbols" or op == "symbols_reset" then
    if count ~= 0 then
      return nil, op .. " does not accept extra arguments"
    end
    return params
  end

  if op == "geometry" or op == "intersect" or op == "tangent" or op == "similar" then
    if count ~= 0 then
      return nil, op .. " does not accept extra arguments"
    end
    return params
  end

  if op == "units" then
    if count == 1 and string.lower(vim.trim(args[1] or "")) == "simplify" then
      params.action = "simplify"
      return params
    end
    if count == 2 and string.lower(vim.trim(args[1] or "")) == "convert" then
      params.action = "convert"
      params.target = args[2]
      return params
    end
    return nil, "units expects: simplify | convert <target>"
  end

  if op == "mechanics" then
    if count < 2 then
      return nil, "mechanics expects: euler_lagrange <q...>"
    end
    if string.lower(vim.trim(args[1] or "")) ~= "euler_lagrange" then
      return nil, "mechanics supports only: euler_lagrange <q...>"
    end
    params.action = "euler_lagrange"
    params.qs = {}
    for index = 2, count do
      table.insert(params.qs, args[index])
    end
    return params
  end

  if op == "quantum" then
    local action = string.lower(vim.trim(args[1] or ""))
    if count == 1 and action == "dagger" then
      params.action = "dagger"
      return params
    end
    if count == 2 and action == "commutator" then
      params.action = "commutator"
      params.expr2 = args[2]
      return params
    end
    return nil, "quantum expects: dagger | commutator <expr2>"
  end

  if op == "optics" then
    local action = string.lower(vim.trim(args[1] or ""))
    if action == "lens" or action == "mirror" then
      if count ~= 3 then
        return nil, "optics " .. action .. " expects two key=value parameters"
      end
      params.action = action
      params.options = {}
      for index = 2, 3 do
        local token = tostring(args[index] or "")
        local eq_pos = string.find(token, "=", 1, true)
        if not eq_pos or eq_pos <= 1 or eq_pos >= #token then
          return nil, "Invalid optics option: " .. token
        end
        local key = vim.trim(token:sub(1, eq_pos - 1))
        local value = vim.trim(token:sub(eq_pos + 1))
        if key == "" or value == "" then
          return nil, "Invalid optics option: " .. token
        end
        params.options[key] = value
      end
      return params
    end
    if action == "refraction" then
      if count ~= 4 then
        return nil, "optics refraction expects: <incident> <n1> <n2>"
      end
      params.action = action
      params.incident = args[2]
      params.n1 = args[3]
      params.n2 = args[4]
      return params
    end
    return nil, "optics expects: lens|mirror|refraction"
  end

  if op == "pauli" then
    if count == 1 and string.lower(vim.trim(args[1] or "")) == "simplify" then
      params.action = "simplify"
      return params
    end
    return nil, "pauli expects: simplify"
  end

  if op == "dist" then
    if count < 2 then
      return nil, "dist expects: <kind> <name> <params...>"
    end
    local kind = string.lower(vim.trim(args[1] or ""))
    if not DIST_KINDS[kind] then
      return nil, "dist kind must be one of: normal, uniform, bernoulli, binomial, hypergeometric"
    end
    params.kind = kind
    params.name = args[2]
    params.args = {}
    for index = 3, count do
      table.insert(params.args, args[index])
    end
    return params
  end

  if op == "p" or op == "e" or op == "var" or op == "density" then
    if count ~= 0 then
      return nil, op .. " does not accept extra arguments"
    end
    return params
  end

  if op == "simplify" or op == "trigsimp" or op == "ratsimp" or op == "powsimp" then
    if count ~= 0 then
      return nil, op .. " does not accept extra arguments"
    end
    return params
  end

  if op == "apart" then
    if count > 1 then
      return nil, "apart expects: [var]"
    end
    if count == 1 then
      params.var = args[1]
    end
    return params
  end

  if op == "subs" then
    if count == 0 then
      return nil, "subs expects: <symbol>=<value> [<symbol>=<value> ...]"
    end

    params.assignments = {}
    for _, token in ipairs(args) do
      local eq_pos = string.find(token, "=", 1, true)
      if not eq_pos or eq_pos <= 1 or eq_pos >= #token then
        return nil, "Invalid substitution token: " .. tostring(token)
      end

      local symbol = vim.trim(token:sub(1, eq_pos - 1))
      local value = vim.trim(token:sub(eq_pos + 1))
      if symbol == "" or value == "" then
        return nil, "Invalid substitution token: " .. tostring(token)
      end

      table.insert(params.assignments, { symbol = symbol, value = value })
    end

    return params
  end

  if op == "solveset" then
    if count > 2 then
      return nil, "solveset expects: [var] [domain]"
    end
    if count == 1 then
      local maybe_domain = string.upper(vim.trim(args[1] or ""))
      if SOLVESET_DOMAINS[maybe_domain] then
        params.domain = maybe_domain
      else
        params.var = args[1]
      end
      return params
    end
    if count == 2 then
      local domain = string.upper(vim.trim(args[2] or ""))
      if not SOLVESET_DOMAINS[domain] then
        return nil, "solveset domain must be one of: C, R, Z, N"
      end
      params.var = args[1]
      params.domain = domain
      return params
    end
    return params
  end

  if op == "linsolve" or op == "nonlinsolve" or op == "diophantine" then
    if count > 0 then
      params.vars = {}
      for _, value in ipairs(args) do
        table.insert(params.vars, value)
      end
    end
    return params
  end

  if op == "rsolve" then
    if count > 1 then
      return nil, "rsolve expects: [func]"
    end
    if count == 1 then
      params.func = args[1]
    end
    return params
  end

  if op == "charpoly" then
    if count > 1 then
      return nil, "charpoly expects: [var]"
    end
    if count == 1 then
      params.var = args[1]
    end
    return params
  end

  if op == "primerange" then
    if count ~= 2 then
      return nil, "primerange expects: <start> <stop>"
    end
    local start_value = parse_int(args[1])
    local stop_value = parse_int(args[2])
    if start_value == nil or stop_value == nil then
      return nil, "primerange expects integer bounds"
    end
    params.start = start_value
    params.stop = stop_value
    return params
  end

  if op == "eigenvects" or op == "nullspace" or op == "lu" or op == "qr" or op == "mat_solve" or op == "isprime" or op == "factorint" then
    if count ~= 0 then
      return nil, op .. " does not accept extra arguments"
    end
    return params
  end

  if op == "solve" then
    if count == 1 then
      params.var = args[1]
      return params
    end
    if count > 1 then
      params.vars = {}
      for _, value in ipairs(args) do
        table.insert(params.vars, value)
      end
      return params
    end
    return params
  end

  if op == "solve_system" then
    if count > 0 then
      params.vars = {}
      for _, value in ipairs(args) do
        table.insert(params.vars, value)
      end
    end
    return params
  end

  if op == "nsolve" then
    if count ~= 2 and count ~= 3 then
      return nil, "nsolve expects: <var> <guess> [guess2]"
    end
    params.var = args[1]
    params.guess = args[2]
    if count == 3 then
      params.guess2 = args[3]
    end
    return params
  end

  if op == "dsolve" then
    if count > 1 then
      return nil, "dsolve expects: [func]"
    end
    if count == 1 then
      params.func = args[1]
    end
    return params
  end

  if op == "diff" then
    if count == 0 then
      return params
    end

    if count == 1 then
      local maybe_order = parse_int(args[1])
      if maybe_order ~= nil then
        if maybe_order <= 0 then
          return nil, "diff order must be positive"
        end
        params.order = maybe_order
      else
        params.var = args[1]
      end
      return params
    end

    if count == 2 then
      local order = parse_int(args[2])
      if order ~= nil then
        if order <= 0 then
          return nil, "diff order must be positive"
        end
        params.var = args[1]
        params.order = order
      else
        params.chain = {
          { var = args[1], order = 1 },
          { var = args[2], order = 1 },
        }
      end
      return params
    end

    params.chain = {}
    local index = 1
    while index <= count do
      local var_name = args[index]
      if parse_int(var_name) ~= nil then
        return nil, "diff expects variable names before optional order values"
      end

      local order_value = 1
      local next_value = args[index + 1]
      local parsed_next = parse_int(next_value)
      if parsed_next ~= nil then
        if parsed_next <= 0 then
          return nil, "diff order must be positive"
        end
        order_value = parsed_next
        index = index + 2
      else
        index = index + 1
      end

      table.insert(params.chain, { var = var_name, order = order_value })
    end

    return params
  end

  if op == "integrate" then
    if count == 0 then
      return params
    end
    if count == 1 then
      params.var = args[1]
      return params
    end
    if count == 3 then
      params.var = args[1]
      params.lower = args[2]
      params.upper = args[3]
      return params
    end
    if count > 3 and count % 3 == 0 then
      params.bounds = {}
      local index = 1
      while index <= count do
        table.insert(params.bounds, {
          var = args[index],
          lower = args[index + 1],
          upper = args[index + 2],
        })
        index = index + 3
      end
      return params
    end
    return nil, "integrate expects: [var] [lower] [upper] or repeated triplets"
  end

  if op == "limit" then
    if count ~= 2 and count ~= 3 then
      return nil, "limit expects: <var> <point> [dir]"
    end
    params.var = args[1]
    params.point = args[2]
    params.dir = args[3] or "+-"
    return params
  end

  if op == "series" then
    if count ~= 3 then
      return nil, "series expects: <var> <point> <order>"
    end
    local order = parse_int(args[3])
    if not order or order <= 0 then
      return nil, "series order must be a positive integer"
    end
    params.var = args[1]
    params.point = args[2]
    params.order = order
    return params
  end

  if count ~= 0 then
    return nil, op .. " does not accept extra arguments"
  end
  return params
end

local function apply_mode_from_bang(opts)
  if opts and opts.bang then
    return "append"
  end
  return "replace"
end

local function run_operation(op_name, params, opts)
  local op = string.lower(tostring(op_name or ""))
  if not OP_NAMES[op] then
    LOG.error("Unknown op: " .. tostring(op_name))
    return
  end

  local mode = apply_mode_from_bang(opts)
  last_operation = {
    op = op,
    params = clone(params or {}),
  }
  local payload = {
    op = op,
    params = normalize_params_for_payload(params or {}),
  }

  run_range_request(opts, function(range, on_success, on_error)
    payload.data = range.text
    post_json("/op", payload, on_success, on_error, { timeout_ms = current_config.timeout_ms })
  end, function(range, result)
    if mode == "append" then
      insert_after_range(range, " = " .. result)
    else
      replace_range(range, result)
    end
  end, { success_context = "op " .. op })
end

local TRANSFORM_ACTIONS = {
  equal = {
    path = "/latex",
    apply = function(range, data)
      insert_after_range(range, " = " .. tostring(data))
    end,
  },
  replace = {
    path = "/latex",
    apply = function(range, data)
      replace_range(range, tostring(data))
    end,
  },
  numerical = {
    path = "/numerical",
    apply = function(range, data)
      replace_range(range, tostring(data))
    end,
  },
  factor = {
    path = "/factor",
    apply = function(range, data)
      replace_range(range, tostring(data))
    end,
  },
  expand = {
    path = "/expand",
    apply = function(range, data)
      replace_range(range, tostring(data))
    end,
  },
  matrix_rref = {
    path = "/matrix-raw-echelon-form",
    apply = function(range, data)
      insert_after_range(range, " \\\\to " .. tostring(data))
    end,
  },
}

local function run_transform(action_name, opts)
  local action = TRANSFORM_ACTIONS[action_name]
  if not action then
    LOG.error("Unknown action: " .. tostring(action_name))
    return
  end

  run_range_request(opts, function(range, on_success, on_error)
    post_data(action.path, range.text, on_success, on_error, { timeout_ms = current_config.timeout_ms })
  end, function(range, result)
    action.apply(range, result)
  end, { success_context = "core " .. action_name })
end

local function keymap_record_key(bufnr, mode, lhs)
  return table.concat({ tostring(bufnr), mode, lhs }, "::")
end

local function remember_applied_default_keymap(bufnr, mode, lhs)
  applied_default_keymaps[keymap_record_key(bufnr, mode, lhs)] = {
    bufnr = bufnr,
    mode = mode,
    lhs = lhs,
  }
end

local function clear_applied_default_keymaps()
  for _, entry in pairs(applied_default_keymaps) do
    pcall(vim.keymap.del, entry.mode, entry.lhs, { buffer = entry.bufnr })
  end
  applied_default_keymaps = {}
end

local function keymap_exists(bufnr, mode, lhs)
  local ok_buf, buf_maps = pcall(vim.api.nvim_buf_get_keymap, bufnr, mode)
  if ok_buf and type(buf_maps) == "table" then
    for _, map in ipairs(buf_maps) do
      if map.lhs == lhs then
        return true
      end
    end
  end

  local ok_global, global_maps = pcall(vim.api.nvim_get_keymap, mode)
  if ok_global and type(global_maps) == "table" then
    for _, map in ipairs(global_maps) do
      if map.lhs == lhs then
        return true
      end
    end
  end

  return false
end

local function maybe_set_default_keymap(bufnr, mode, lhs, rhs, desc)
  if current_config.respect_existing_keymaps and keymap_exists(bufnr, mode, lhs) then
    return
  end

  vim.keymap.set(mode, lhs, rhs, {
    buffer = bufnr,
    silent = true,
    desc = desc,
  })
  remember_applied_default_keymap(bufnr, mode, lhs)
end

local function apply_default_keymaps(bufnr)
  if not current_config.default_keymaps then
    return
  end

  local visual_prefix = normalize_keymap_prefix(current_config.keymap_prefix)
  local normal_prefix = normalize_keymap_prefix(current_config.normal_keymap_prefix)
  for _, mode in ipairs({ "x", "n" }) do
    local prefix = (mode == "x") and visual_prefix or normal_prefix
    local entries = DEFAULT_KEYMAPS[mode] or {}
    for _, entry in ipairs(entries) do
      maybe_set_default_keymap(bufnr, mode, prefix .. entry.suffix, entry.rhs, entry.desc)
    end
  end
end

local function command_names()
  return {
    "LatexSympyEqual",
    "LatexSympyReplace",
    "LatexSympyNumerical",
    "LatexSympyFactor",
    "LatexSympyExpand",
    "LatexSympyMatrixRREF",
    "LatexSympyVariances",
    "LatexSympyReset",
    "LatexSympyToggleComplex",
    "LatexSympyPython",
    "LatexSympyStatus",
    "LatexSympyRestart",
    "LatexSympyStart",
    "LatexSympyStop",
    "LatexSympyOp",
    "LatexSympyPick",
    "LatexSympyRepeat",
    "LatexSympySolve",
    "LatexSympyDiff",
    "LatexSympyIntegrate",
    "LatexSympyDet",
    "LatexSympyInv",
  }
end

local function completion_for_ops(arg_lead)
  local values = vim.tbl_keys(OP_NAMES)
  table.sort(values)
  local out = {}
  for _, value in ipairs(values) do
    if arg_lead == "" or vim.startswith(value, arg_lead) then
      table.insert(out, value)
    end
  end
  return out
end

local function normalize_trailing_bang_opts(opts)
  local normalized_opts = opts or {}
  if normalized_opts.bang then
    return normalized_opts
  end

  local fargs = normalized_opts.fargs or {}
  if fargs[#fargs] ~= "!" then
    return normalized_opts
  end

  if not trailing_bang_hint_notified then
    trailing_bang_hint_notified = true
    LOG.warn("Use :LatexSympyOp! {op} (trailing ! was converted).")
  end

  normalized_opts = clone(normalized_opts)
  normalized_opts.fargs = {}
  for index = 1, #fargs - 1 do
    table.insert(normalized_opts.fargs, fargs[index])
  end
  normalized_opts.bang = true
  return normalized_opts
end

local function run_alias_operation(op_name, opts)
  local normalized_opts = normalize_trailing_bang_opts(opts)
  local params, err = parse_operation_args(op_name, normalized_opts.fargs or {})
  if not params then
    LOG.error(err)
    return
  end
  run_operation(op_name, params, normalized_opts)
end

local function normalize_picker_backend(value)
  local backend = string.lower(vim.trim(tostring(value or "")))
  if backend == "snacks" then
    return "snacks"
  end
  if backend == "auto" then
    return "auto"
  end
  return "vim_ui"
end

local function split_args_input(raw)
  local text = vim.trim(tostring(raw or ""))
  if text == "" then
    return {}
  end
  return vim.fn.split(text, "\\s\\+", false)
end

local function has_selection_or_range(opts)
  if opts and opts.range and opts.range > 0 then
    return true
  end
  local m1 = vim.api.nvim_buf_get_mark(0, "<")
  local m2 = vim.api.nvim_buf_get_mark(0, ">")
  return (m1 and m2 and (m1[1] ~= 0 or m2[1] ~= 0)) and true or false
end

local function snacks_select_available()
  local snacks = rawget(_G, "Snacks")
  if snacks and snacks.picker and type(snacks.picker.select) == "function" then
    return true
  end
  local ok, mod = pcall(require, "snacks.picker")
  return ok and mod and type(mod.select) == "function"
end

local function try_snacks_select(items, opts, on_choice)
  local snacks = rawget(_G, "Snacks")
  if snacks and snacks.picker and type(snacks.picker.select) == "function" then
    snacks.picker.select(items, opts or {}, on_choice)
    return true
  end

  local ok, mod = pcall(require, "snacks.picker")
  if ok and mod and type(mod.select) == "function" then
    mod.select(items, opts or {}, on_choice)
    return true
  end
  return false
end

local function inputlist_select(items, opts, on_choice)
  local lines = { (opts and opts.prompt) or "latex_sympy picker" }
  for index, item in ipairs(items) do
    local label = opts and opts.format_item and opts.format_item(item) or tostring(item)
    table.insert(lines, string.format("%d. %s", index, label))
  end
  local selected = tonumber(vim.fn.inputlist(lines))
  if not selected or selected < 1 or selected > #items then
    on_choice(nil)
    return
  end
  on_choice(items[selected])
end

local function get_picker_select()
  if type(current_config.picker_select) == "function" then
    return function(items, opts, on_choice)
      current_config.picker_select(items, opts or {}, on_choice)
    end
  end

  local backend = normalize_picker_backend(current_config.picker_backend)
  if backend == "snacks" then
    return function(items, opts, on_choice)
      if try_snacks_select(items, opts, on_choice) then
        return
      end
      if vim.ui and type(vim.ui.select) == "function" then
        vim.ui.select(items, opts or {}, on_choice)
        return
      end
      inputlist_select(items, opts, on_choice)
    end
  end

  if backend == "auto" then
    return function(items, opts, on_choice)
      if try_snacks_select(items, opts, on_choice) then
        return
      end
      if vim.ui and type(vim.ui.select) == "function" then
        vim.ui.select(items, opts or {}, on_choice)
        return
      end
      inputlist_select(items, opts, on_choice)
    end
  end

  if vim.ui and type(vim.ui.select) == "function" then
    return function(items, opts, on_choice)
      vim.ui.select(items, opts or {}, on_choice)
    end
  end

  return inputlist_select
end

local function get_picker_input()
  if type(current_config.picker_input) == "function" then
    return function(opts, on_confirm)
      current_config.picker_input(opts or {}, on_confirm)
    end
  end
  if vim.ui and type(vim.ui.input) == "function" then
    return function(opts, on_confirm)
      vim.ui.input(opts or {}, on_confirm)
    end
  end
  return function(opts, on_confirm)
    local prompt = (opts and opts.prompt) or ""
    local default = (opts and opts.default) or ""
    local value = vim.fn.input(prompt .. " ", default)
    if value == nil or value == "" then
      on_confirm(nil)
      return
    end
    on_confirm(value)
  end
end

local function copy_picker_opts(opts, override)
  local result = {
    range = opts and opts.range or 0,
    line1 = opts and opts.line1 or nil,
    line2 = opts and opts.line2 or nil,
    bang = opts and opts.bang or false,
    fargs = {},
  }
  if override then
    for key, value in pairs(override) do
      result[key] = value
    end
  end
  return result
end

local function shallow_copy(tbl)
  local out = {}
  for key, value in pairs(tbl or {}) do
    out[key] = value
  end
  return out
end

local function build_picker_categories()
  return {
    { value = "all", label = "All", description = "Everything" },
    { value = "core", label = "Core", description = "Quick transforms (equal/replace/factor/expand/rref)" },
    { value = "op", label = "Ops", description = "Advanced SymPy operations" },
    { value = "alias", label = "Aliases", description = "Shortcuts to common ops" },
    { value = "utility", label = "Utility", description = "Server/status/session helpers" },
  }
end

local function format_picker_item_row(item)
  local label = tostring(item and item.label or "")
  local description = vim.trim(tostring(item and item.description or ""))
  local row = label
  if description ~= "" then
    row = string.format("%s - %s", row, description)
  end
  local hint = vim.trim(tostring(item and item.args_hint or ""))
  local include_hint = item and (item.requires_args == true or item.show_args_hint == true or item.accepts_args == true)
  if include_hint and hint ~= "" then
    row = string.format("%s [args: %s]", row, hint)
  end
  if item and item.bang_append == true then
    row = row .. " [append available]"
  end
  if item and item.unavailable then
    row = row .. " [needs selection]"
  end
  return row
end

local function build_picker_entries()
  local entries = {
    {
      kind = "core",
      label = "Core: Equal",
      description = "Append '= result' next to selection",
      requires_selection = true,
      run = function(ctx)
        M.equal(copy_picker_opts(ctx.opts, { bang = false }))
      end,
    },
    {
      kind = "core",
      label = "Core: Replace",
      description = "Replace selection with computed result",
      requires_selection = true,
      run = function(ctx)
        M.replace(copy_picker_opts(ctx.opts, { bang = false }))
      end,
    },
    {
      kind = "core",
      label = "Core: Numerical",
      description = "Evaluate selection numerically",
      requires_selection = true,
      run = function(ctx)
        M.numerical(copy_picker_opts(ctx.opts, { bang = false }))
      end,
    },
    {
      kind = "core",
      label = "Core: Factor",
      description = "Factor selected expression",
      requires_selection = true,
      run = function(ctx)
        M.factor(copy_picker_opts(ctx.opts, { bang = false }))
      end,
    },
    {
      kind = "core",
      label = "Core: Expand",
      description = "Expand selected expression",
      requires_selection = true,
      run = function(ctx)
        M.expand(copy_picker_opts(ctx.opts, { bang = false }))
      end,
    },
    {
      kind = "core",
      label = "Core: Matrix RREF",
      description = "Compute row-reduced echelon form",
      requires_selection = true,
      run = function(ctx)
        M.matrix_rref(copy_picker_opts(ctx.opts, { bang = false }))
      end,
    },
  }

  local op_names = vim.tbl_keys(OP_NAMES)
  table.sort(op_names)
  for _, op_name in ipairs(op_names) do
    table.insert(entries, {
      kind = "op",
      label = "Op: " .. op_name,
      description = OP_DESCRIPTIONS[op_name] or ("Run " .. op_name .. " on selection"),
      op_name = op_name,
      requires_selection = true,
      requires_args = OP_REQUIRES_ARGS[op_name] == true,
      accepts_args = OP_ARGS_HINTS[op_name] ~= nil,
      bang_append = true,
      args_hint = OP_ARGS_HINTS[op_name] or "[args...]",
      run = function(ctx, args)
        local params, err = parse_operation_args(op_name, args or {})
        if not params then
          LOG.error(err)
          return
        end
        run_operation(op_name, params, copy_picker_opts(ctx.opts, { bang = ctx.opts.bang }))
      end,
    })
  end

  table.insert(entries, {
    kind = "alias",
    label = "Alias: Solve",
    description = "Alias for op solve",
    requires_selection = true,
    accepts_args = true,
    bang_append = true,
    guided_key = "solve",
    args_hint = "[var ...]",
    show_args_hint = true,
    run = function(ctx, args)
      run_alias_operation("solve", copy_picker_opts(ctx.opts, { bang = ctx.opts.bang, fargs = args or {} }))
    end,
  })
  table.insert(entries, {
    kind = "alias",
    label = "Alias: Diff",
    description = "Alias for op diff",
    requires_selection = true,
    accepts_args = true,
    bang_append = true,
    guided_key = "diff",
    args_hint = "[var] [order]",
    show_args_hint = true,
    run = function(ctx, args)
      run_alias_operation("diff", copy_picker_opts(ctx.opts, { bang = ctx.opts.bang, fargs = args or {} }))
    end,
  })
  table.insert(entries, {
    kind = "alias",
    label = "Alias: Integrate",
    description = "Alias for op integrate",
    requires_selection = true,
    accepts_args = true,
    bang_append = true,
    guided_key = "integrate",
    args_hint = "[var] [lower] [upper]",
    show_args_hint = true,
    run = function(ctx, args)
      run_alias_operation("integrate", copy_picker_opts(ctx.opts, { bang = ctx.opts.bang, fargs = args or {} }))
    end,
  })
  table.insert(entries, {
    kind = "alias",
    label = "Alias: Det",
    description = "Alias for op det",
    requires_selection = true,
    bang_append = true,
    run = function(ctx)
      run_alias_operation("det", copy_picker_opts(ctx.opts, { bang = ctx.opts.bang, fargs = {} }))
    end,
  })
  table.insert(entries, {
    kind = "alias",
    label = "Alias: Inv",
    description = "Alias for op inv",
    requires_selection = true,
    bang_append = true,
    run = function(ctx)
      run_alias_operation("inv", copy_picker_opts(ctx.opts, { bang = ctx.opts.bang, fargs = {} }))
    end,
  })

  table.insert(entries, {
    kind = "utility",
    label = "Utility: Repeat",
    description = "Repeat last advanced operation",
    requires_selection = true,
    bang_append = true,
    run = function(ctx)
      M.repeat_op(copy_picker_opts(ctx.opts, { bang = ctx.opts.bang }))
    end,
  })
  table.insert(entries, {
    kind = "utility",
    label = "Utility: Variances",
    description = "Insert tracked variances at cursor",
    run = function()
      M.variances()
    end,
  })
  table.insert(entries, {
    kind = "utility",
    label = "Utility: Reset",
    description = "Reset variances and session state",
    run = function()
      M.reset()
    end,
  })
  table.insert(entries, {
    kind = "utility",
    label = "Utility: Toggle Complex",
    description = "Toggle complex-number mode for variances",
    run = function()
      M.toggle_complex()
    end,
  })
  table.insert(entries, {
    kind = "utility",
    label = "Utility: Python Eval",
    description = "Evaluate selected Python snippet",
    requires_selection = true,
    run = function(ctx)
      M.python(copy_picker_opts(ctx.opts, { bang = false }))
    end,
  })
  table.insert(entries, {
    kind = "utility",
    label = "Utility: Status",
    description = "Show server and config status",
    run = function()
      M.status()
    end,
  })
  table.insert(entries, {
    kind = "utility",
    label = "Utility: Start Server",
    description = "Start backend server",
    run = function()
      M.start_server()
    end,
  })
  table.insert(entries, {
    kind = "utility",
    label = "Utility: Stop Server",
    description = "Stop backend server",
    run = function()
      M.stop_server()
    end,
  })
  table.insert(entries, {
    kind = "utility",
    label = "Utility: Restart Server",
    description = "Restart backend server",
    run = function()
      M.restart_server()
    end,
  })

  return entries
end

local function picker_entries_for_category(entries, category_value)
  if category_value == "all" then
    return entries
  end
  local filtered = {}
  for _, entry in ipairs(entries) do
    if entry.kind == category_value then
      table.insert(filtered, entry)
    end
  end
  return filtered
end

local function picker_entries_for_context(entries, selection_available, show_unavailable)
  local filtered = {}
  for _, entry in ipairs(entries) do
    if not entry.requires_selection or selection_available then
      table.insert(filtered, entry)
    elseif show_unavailable then
      local copy = shallow_copy(entry)
      copy.unavailable = true
      table.insert(filtered, copy)
    end
  end
  return filtered
end

local function picker_filter_score(entry, query)
  local text = string.lower(vim.trim(query or ""))
  if text == "" then
    return 0
  end

  local fields = {
    string.lower(tostring(entry.label or "")),
    string.lower(tostring(entry.description or "")),
    string.lower(tostring(entry.op_name or "")),
    string.lower(tostring(entry.args_hint or "")),
  }

  local best = nil
  for _, field in ipairs(fields) do
    if field ~= "" then
      if vim.startswith(field, text) then
        best = math.min(best or 1, 1)
      elseif field:find(text, 1, true) then
        best = math.min(best or 2, 2)
      end
    end
  end
  return best
end

local function picker_filter_entries(entries, query)
  local text = vim.trim(tostring(query or ""))
  if text == "" then
    return entries
  end

  local ranked = {}
  for index, entry in ipairs(entries) do
    local score = picker_filter_score(entry, text)
    if score then
      table.insert(ranked, {
        entry = entry,
        score = score,
        index = index,
      })
    end
  end

  table.sort(ranked, function(a, b)
    if a.score ~= b.score then
      return a.score < b.score
    end
    return a.index < b.index
  end)

  local filtered = {}
  for _, item in ipairs(ranked) do
    table.insert(filtered, item.entry)
  end
  return filtered
end

local function prompt_raw_args(entry, input_fn, on_done)
  local hint = entry.args_hint or "[args...]"
  local context = entry.op_name or entry.guided_key or entry.label or "command"
  input_fn({
    prompt = string.format("latex_sympy args (%s): %s", context, hint),
    default = "",
  }, function(input_value)
    if input_value == nil then
      on_done(nil, true)
      return
    end
    local raw = vim.trim(tostring(input_value))
    if raw == "" then
      on_done({}, false)
      return
    end
    on_done(split_args_input(raw), false)
  end)
end

local function guided_schema_for_entry(entry)
  local key = entry.guided_key or entry.op_name
  if not key then
    return nil, nil
  end
  return PICKER_GUIDED_ARGS_SCHEMA[key], key
end

local function guided_args_from_values(schema, values)
  local args = {}
  for _, token in ipairs(schema.prefix_tokens or {}) do
    table.insert(args, token)
  end

  for _, field in ipairs(schema.fields or {}) do
    local text = vim.trim(tostring((values or {})[field.key] or ""))
    if text == "" then
      if not field.optional then
        return nil, "Missing required argument: " .. tostring(field.key)
      end
    elseif field.split then
      local chunks = split_args_input(text)
      if #chunks == 0 and not field.optional then
        return nil, "Missing required argument: " .. tostring(field.key)
      end
      for _, chunk in ipairs(chunks) do
        table.insert(args, chunk)
      end
    else
      table.insert(args, text)
    end
  end

  return args
end

local function collect_guided_args(entry, input_fn, on_done)
  local schema, schema_key = guided_schema_for_entry(entry)
  if not schema then
    on_done(nil, "No guided args schema for " .. tostring(schema_key or entry.op_name or entry.label))
    return
  end

  local values = {}
  local fields = schema.fields or {}
  local index = 1

  local function finish()
    local args, err = guided_args_from_values(schema, values)
    if not args then
      on_done(nil, err)
      return
    end
    on_done(args, nil)
  end

  local function prompt_next()
    if index > #fields then
      finish()
      return
    end

    local field = fields[index]
    index = index + 1

    local context = entry.op_name or entry.guided_key or entry.label or "args"
    input_fn({
      prompt = string.format("latex_sympy arg (%s): %s", context, tostring(field.prompt or field.key)),
      default = field.default or "",
    }, function(input_value)
      local text = vim.trim(tostring(input_value or ""))
      if text == "" and not field.optional then
        on_done(nil, "Missing required argument: " .. tostring(field.key))
        return
      end
      values[field.key] = text
      prompt_next()
    end)
  end

  prompt_next()
end

local function resolve_picker_args(entry, input_fn, on_done)
  local wants_guided = current_config.picker_guided_args == "all" and entry.accepts_args == true
  if wants_guided then
    collect_guided_args(entry, input_fn, function(guided_args, guided_err)
      if guided_args then
        on_done(guided_args)
        return
      end

      if not current_config.picker_guided_args_allow_raw then
        if guided_err then
          LOG.error(guided_err)
        end
        return
      end

      prompt_raw_args(entry, input_fn, function(raw_args, cancelled)
        if cancelled then
          return
        end
        on_done(raw_args or {})
      end)
    end)
    return
  end

  if entry.requires_args then
    prompt_raw_args(entry, input_fn, function(raw_args, cancelled)
      if cancelled then
        return
      end
      on_done(raw_args or {})
    end)
    return
  end

  on_done({})
end

local function run_picker_entry(entry, opts, args)
  if entry.requires_selection and not has_selection_or_range(opts) then
    LOG.error("No selection detected. Use visual selection or provide a range.")
    return
  end

  local resolved_args = {}
  if type(args) == "table" then
    resolved_args = args
  elseif type(args) == "string" then
    resolved_args = split_args_input(args)
  end
  entry.run({ opts = opts or {} }, resolved_args)
end

local function resolve_picker_apply_mode(entry, opts, select_fn, on_done)
  local base_opts = copy_picker_opts(opts or {})
  if not entry or not entry.bang_append then
    on_done(base_opts)
    return
  end

  if base_opts.bang then
    on_done(base_opts)
    return
  end

  local mode_items = {
    { value = "replace", label = "Replace", description = "Replace selection with result" },
    { value = "append", label = "Append (!)", description = "Append = <result> after selection" },
  }

  select_fn(mode_items, {
    prompt = "latex_sympy apply mode",
    format_item = function(item)
      return format_picker_item_row(item)
    end,
  }, function(choice)
    if not choice then
      return
    end

    local resolved = copy_picker_opts(base_opts)
    if choice.value == "append" then
      resolved.bang = true
    end
    on_done(resolved)
  end)
end

local function open_picker(opts)
  local select_fn = get_picker_select()
  local input_fn = get_picker_input()
  local entries = build_picker_entries()
  local categories = build_picker_categories()

  select_fn(categories, {
    prompt = "latex_sympy category",
    format_item = function(item)
      return format_picker_item_row(item)
    end,
  }, function(category)
    if not category then
      return
    end

    local scoped_entries = picker_entries_for_category(entries, category.value)
    if #scoped_entries == 0 then
      LOG.warn("No picker entries available for category")
      return
    end

    local selection_available = has_selection_or_range(opts)
    local contextual_entries = picker_entries_for_context(scoped_entries, selection_available, current_config.picker_show_unavailable)
    if #contextual_entries == 0 then
      LOG.warn("No picker entries available in current context")
      return
    end

    local show_commands = function(filter_query)
      local filtered_entries = picker_filter_entries(contextual_entries, filter_query)
      if #filtered_entries == 0 then
        LOG.warn("No picker entries match filter")
        return
      end

      select_fn(filtered_entries, {
        prompt = "latex_sympy command",
        format_item = function(item)
          return format_picker_item_row(item)
        end,
      }, function(entry)
        if not entry then
          return
        end

        resolve_picker_apply_mode(entry, opts, select_fn, function(execution_opts)
          resolve_picker_args(entry, input_fn, function(resolved_args)
            run_picker_entry(entry, execution_opts, resolved_args)
          end)
        end)
      end)
    end

    if not current_config.picker_filter_enabled then
      show_commands("")
      return
    end

    input_fn({
      prompt = current_config.picker_filter_prompt,
      default = "",
    }, function(filter_value)
      local query = vim.trim(tostring(filter_value or ""))
      show_commands(query)
    end)
  end)
end

local function create_commands()
  if commands_registered then
    return
  end

  for _, name in ipairs(command_names()) do
    pcall(vim.api.nvim_del_user_command, name)
  end

  vim.api.nvim_create_user_command("LatexSympyEqual", function(opts)
    M.equal(opts)
  end, { range = true, desc = "Append = <result> for selected LaTeX" })

  vim.api.nvim_create_user_command("LatexSympyReplace", function(opts)
    M.replace(opts)
  end, { range = true, desc = "Replace selection with LaTeX result" })

  vim.api.nvim_create_user_command("LatexSympyNumerical", function(opts)
    M.numerical(opts)
  end, { range = true, desc = "Replace selection with numerical result" })

  vim.api.nvim_create_user_command("LatexSympyFactor", function(opts)
    M.factor(opts)
  end, { range = true, desc = "Replace selection with factored expression" })

  vim.api.nvim_create_user_command("LatexSympyExpand", function(opts)
    M.expand(opts)
  end, { range = true, desc = "Replace selection with expanded expression" })

  vim.api.nvim_create_user_command("LatexSympyMatrixRREF", function(opts)
    M.matrix_rref(opts)
  end, { range = true, desc = "Append \\to <rref> for matrix selection" })

  vim.api.nvim_create_user_command("LatexSympyOp", function(opts)
    M.op(opts)
  end, {
    range = true,
    bang = true,
    nargs = "+",
    complete = function(arg_lead)
      return completion_for_ops(arg_lead)
    end,
    desc = "Run advanced SymPy operation on selected LaTeX",
  })

  vim.api.nvim_create_user_command("LatexSympyPick", function(opts)
    M.pick(opts)
  end, {
    range = true,
    bang = true,
    nargs = 0,
    desc = "Open latex_sympy command picker",
  })

  vim.api.nvim_create_user_command("LatexSympyRepeat", function(opts)
    M.repeat_op(opts)
  end, {
    range = true,
    bang = true,
    nargs = 0,
    desc = "Repeat last LatexSympyOp/alias operation",
  })

  vim.api.nvim_create_user_command("LatexSympySolve", function(opts)
    run_alias_operation("solve", opts)
  end, {
    range = true,
    bang = true,
    nargs = "?",
    desc = "Solve selected expression/equation",
  })

  vim.api.nvim_create_user_command("LatexSympyDiff", function(opts)
    run_alias_operation("diff", opts)
  end, {
    range = true,
    bang = true,
    nargs = "*",
    desc = "Differentiate selected expression",
  })

  vim.api.nvim_create_user_command("LatexSympyIntegrate", function(opts)
    run_alias_operation("integrate", opts)
  end, {
    range = true,
    bang = true,
    nargs = "*",
    desc = "Integrate selected expression",
  })

  vim.api.nvim_create_user_command("LatexSympyDet", function(opts)
    run_alias_operation("det", opts)
  end, {
    range = true,
    bang = true,
    nargs = 0,
    desc = "Compute matrix determinant",
  })

  vim.api.nvim_create_user_command("LatexSympyInv", function(opts)
    run_alias_operation("inv", opts)
  end, {
    range = true,
    bang = true,
    nargs = 0,
    desc = "Compute matrix inverse",
  })

  vim.api.nvim_create_user_command("LatexSympyVariances", function()
    M.variances()
  end, { desc = "Insert current variances mapping at cursor" })

  vim.api.nvim_create_user_command("LatexSympyReset", function()
    M.reset()
  end, { desc = "Reset current variances" })

  vim.api.nvim_create_user_command("LatexSympyToggleComplex", function()
    M.toggle_complex()
  end, { desc = "Toggle complex numbers for variances" })

  vim.api.nvim_create_user_command("LatexSympyPython", function(opts)
    M.python(opts)
  end, { range = true, desc = "Evaluate Python snippet and append = <result>" })

  vim.api.nvim_create_user_command("LatexSympyStatus", function()
    M.status()
  end, { desc = "Show latex_sympy server/config status" })

  vim.api.nvim_create_user_command("LatexSympyRestart", function()
    M.restart_server()
  end, { desc = "Restart the latex_sympy Python server" })

  vim.api.nvim_create_user_command("LatexSympyStart", function()
    M.start_server()
  end, { desc = "Start the latex_sympy Python server" })

  vim.api.nvim_create_user_command("LatexSympyStop", function()
    M.stop_server()
  end, { desc = "Stop the latex_sympy Python server" })

  commands_registered = true
end

local function maybe_notify_startup()
  if not current_config.notify_startup then
    return
  end
  if current_config.startup_notify_once and startup_notified then
    return
  end
  LOG.info("active", { force = true })
  startup_notified = true
end

function M.setup(opts)
  opts = opts or {}

  local next_config = clone(current_config)
  if not configured then
    next_config = clone(DEFAULT_CONFIG)
  end

  next_config.python = opts.python or next_config.python
  if opts.auto_install ~= nil then
    next_config.auto_install = opts.auto_install
  end
  next_config.port = opts.port or next_config.port
  if opts.enable_python_eval ~= nil then
    next_config.enable_python_eval = opts.enable_python_eval
  end
  if opts.notify_startup ~= nil then
    next_config.notify_startup = opts.notify_startup
  end
  if opts.startup_notify_once ~= nil then
    next_config.startup_notify_once = opts.startup_notify_once
  end
  if opts.notify_info ~= nil then
    next_config.notify_info = opts.notify_info
  end
  if opts.server_start_mode ~= nil then
    next_config.server_start_mode = normalize_mode(opts.server_start_mode)
  end
  if opts.timeout_ms ~= nil then
    next_config.timeout_ms = coerce_positive_int(opts.timeout_ms, DEFAULT_CONFIG.timeout_ms)
  end
  if opts.preview_before_apply ~= nil then
    next_config.preview_before_apply = opts.preview_before_apply
  end
  if opts.preview_max_chars ~= nil then
    next_config.preview_max_chars = coerce_positive_int(opts.preview_max_chars, DEFAULT_CONFIG.preview_max_chars)
  end
  if opts.drop_stale_results ~= nil then
    next_config.drop_stale_results = opts.drop_stale_results
  end
  if opts.default_keymaps ~= nil then
    next_config.default_keymaps = opts.default_keymaps
  end
  if opts.keymap_prefix ~= nil then
    local prefix = normalize_keymap_prefix(opts.keymap_prefix)
    next_config.keymap_prefix = prefix
    if opts.normal_keymap_prefix == nil then
      next_config.normal_keymap_prefix = prefix
    end
  end
  if opts.normal_keymap_prefix ~= nil then
    next_config.normal_keymap_prefix = normalize_keymap_prefix(opts.normal_keymap_prefix)
  end
  if opts.respect_existing_keymaps ~= nil then
    next_config.respect_existing_keymaps = opts.respect_existing_keymaps
  end
  if opts.picker_backend ~= nil then
    next_config.picker_backend = normalize_picker_backend(opts.picker_backend)
  end
  if opts.picker_select ~= nil then
    if opts.picker_select == false then
      next_config.picker_select = nil
    else
      next_config.picker_select = opts.picker_select
    end
  end
  if opts.picker_input ~= nil then
    if opts.picker_input == false then
      next_config.picker_input = nil
    else
      next_config.picker_input = opts.picker_input
    end
  end
  if opts.picker_filter_enabled ~= nil then
    next_config.picker_filter_enabled = opts.picker_filter_enabled
  end
  if opts.picker_filter_prompt ~= nil then
    next_config.picker_filter_prompt = normalize_picker_filter_prompt(opts.picker_filter_prompt)
  end
  if opts.picker_show_unavailable ~= nil then
    next_config.picker_show_unavailable = opts.picker_show_unavailable
  end
  if opts.picker_guided_args ~= nil then
    next_config.picker_guided_args = normalize_picker_guided_args(opts.picker_guided_args)
  end
  if opts.picker_guided_args_allow_raw ~= nil then
    next_config.picker_guided_args_allow_raw = opts.picker_guided_args_allow_raw
  end
  if opts.notify_success ~= nil then
    next_config.notify_success = opts.notify_success
  end
  if opts.notify_success_max_chars ~= nil then
    next_config.notify_success_max_chars = coerce_positive_int(opts.notify_success_max_chars, DEFAULT_CONFIG.notify_success_max_chars)
  end

  local needs_restart = is_server_running() and (
    next_config.python ~= current_config.python or
    next_config.port ~= current_config.port or
    next_config.enable_python_eval ~= current_config.enable_python_eval
  )

  current_config = next_config
  configured = true

  if needs_restart then
    M.restart_server()
  elseif activated_for_tex and current_config.server_start_mode == "on_activate" and not is_server_running() then
    with_server(function() end)
  end
end

function M.get_config()
  return clone(current_config)
end

function M.activate_for_tex_buffer(bufnr)
  if not configured then
    M.setup({})
  end

  activated_for_tex = true
  create_commands()
  apply_default_keymaps(bufnr or 0)
  maybe_notify_startup()

  if current_config.server_start_mode == "on_activate" then
    with_server(function() end)
  end
end

function M.start_server()
  with_server(function()
    LOG.info("server started")
  end)
end

function M.stop_server(opts)
  local silent = type(opts) == "table" and opts.silent
  local skip_flush = type(opts) == "table" and opts.skip_flush

  if is_server_running() then
    intentional_stop = true
    vim.fn.jobstop(server_job_id)
    server_job_id = nil
  end

  server_ready = false
  server_starting = false

  if not skip_flush then
    flush_server_callbacks(false, "Server stopped")
  end

  if not silent then
    LOG.info("server stopped")
  end
end

function M.restart_server()
  M.stop_server({ silent = true })
  with_server(function()
    LOG.info("server restarted")
  end)
end

function M.equal(opts)
  run_transform("equal", opts)
end

function M.replace(opts)
  run_transform("replace", opts)
end

function M.numerical(opts)
  run_transform("numerical", opts)
end

function M.factor(opts)
  run_transform("factor", opts)
end

function M.expand(opts)
  run_transform("expand", opts)
end

function M.matrix_rref(opts)
  run_transform("matrix_rref", opts)
end

function M.op(opts)
  local normalized_opts = normalize_trailing_bang_opts(opts)
  local fargs = normalized_opts.fargs or {}
  if #fargs < 1 then
    LOG.error("Usage: :LatexSympyOp[!] {op} [args]")
    return
  end
  local op_name = string.lower(fargs[1])
  local args = {}
  for index = 2, #fargs do
    table.insert(args, fargs[index])
  end
  local params, err = parse_operation_args(op_name, args)
  if not params then
    LOG.error(err)
    return
  end
  run_operation(op_name, params, normalized_opts)
end

function M.pick(opts)
  open_picker(opts or {})
end

function M.repeat_op(opts)
  if not last_operation then
    LOG.error("No previous LatexSympyOp operation to repeat")
    return
  end

  run_operation(last_operation.op, clone(last_operation.params or {}), opts or {})
end

function M.solve(opts)
  run_alias_operation("solve", opts)
end

function M.diff(opts)
  run_alias_operation("diff", opts)
end

function M.integrate(opts)
  run_alias_operation("integrate", opts)
end

function M.det(opts)
  run_alias_operation("det", opts)
end

function M.inv(opts)
  run_alias_operation("inv", opts)
end

function M.variances()
  with_server(function()
    get("/variances", function(map)
      local values = map or {}
      local keys = {}
      for key, _ in pairs(values) do
        table.insert(keys, tostring(key))
      end
      table.sort(keys)

      local lines = { "" }
      for _, key in ipairs(keys) do
        table.insert(lines, string.format("%s = %s", key, tostring(values[key])))
      end

      local cursor = vim.api.nvim_win_get_cursor(0)
      local row = cursor[1] - 1
      local col = cursor[2]
      vim.api.nvim_buf_set_text(0, row, col, row, col, lines)
    end, function(err)
      LOG.error(normalize_error(err))
    end, { timeout_ms = current_config.timeout_ms })
  end)
end

function M.reset()
  with_server(function()
    get("/reset", function(_)
      LOG.info("variances reset")
    end, function(err)
      LOG.error(normalize_error(err))
    end, { timeout_ms = current_config.timeout_ms })
  end)
end

function M.toggle_complex()
  with_server(function()
    get("/complex", function(res)
      local enabled = res and res.value
      LOG.info("complex numbers: " .. (enabled and "on" or "off"))
    end, function(err)
      LOG.error(normalize_error(err))
    end, { timeout_ms = current_config.timeout_ms })
  end)
end

function M.python(opts)
  if not current_config.enable_python_eval then
    LOG.error("LatexSympyPython is disabled. Enable with require('latex_sympy').setup({ enable_python_eval = true })")
    return
  end

  run_range_request(opts, function(range, on_success, on_error)
    post_data("/python", range.text, on_success, on_error, { timeout_ms = current_config.timeout_ms })
  end, function(range, result)
    insert_after_range(range, " = " .. tostring(result))
  end, { success_context = "python eval" })
end

function M.status()
  local lines = {
    string.format("Activated for tex: %s", tostring(activated_for_tex)),
    string.format("Server: %s", is_server_running() and "Running" or "Stopped"),
    string.format("Port: %s", tostring(current_config.port)),
    string.format("Python: %s", tostring(current_config.python)),
    string.format("Auto install: %s", tostring(current_config.auto_install)),
    string.format("Server start mode: %s", tostring(current_config.server_start_mode)),
    string.format("Python eval enabled: %s", tostring(current_config.enable_python_eval)),
    string.format("Timeout (ms): %s", tostring(current_config.timeout_ms)),
    string.format("Preview before apply: %s", tostring(current_config.preview_before_apply)),
    string.format("Drop stale results: %s", tostring(current_config.drop_stale_results)),
    string.format("Notify info: %s", tostring(current_config.notify_info)),
    string.format("Default keymaps: %s", tostring(current_config.default_keymaps)),
    string.format("Visual keymap prefix: %s", tostring(current_config.keymap_prefix)),
    string.format("Normal keymap prefix: %s", tostring(current_config.normal_keymap_prefix)),
    string.format("Respect existing keymaps: %s", tostring(current_config.respect_existing_keymaps)),
    string.format("Picker backend: %s", tostring(current_config.picker_backend)),
    string.format("Custom picker select: %s", tostring(type(current_config.picker_select) == "function")),
    string.format("Custom picker input: %s", tostring(type(current_config.picker_input) == "function")),
    string.format("Picker filter enabled: %s", tostring(current_config.picker_filter_enabled)),
    string.format("Picker filter prompt: %s", tostring(current_config.picker_filter_prompt)),
    string.format("Picker show unavailable: %s", tostring(current_config.picker_show_unavailable)),
    string.format("Picker guided args: %s", tostring(current_config.picker_guided_args)),
    string.format("Picker guided args raw fallback: %s", tostring(current_config.picker_guided_args_allow_raw)),
    string.format("Notify success: %s", tostring(current_config.notify_success)),
    string.format("Notify success max chars: %s", tostring(current_config.notify_success_max_chars)),
  }
  LOG.info(table.concat(lines, "\n"), { force = true })
end

-- Test helpers
function M._reset_state_for_tests()
  M.stop_server({ silent = true })
  clear_applied_default_keymaps()

  for _, name in ipairs(command_names()) do
    pcall(vim.api.nvim_del_user_command, name)
  end

  plugin_dir = nil
  intentional_stop = false
  server_ready = false
  server_starting = false
  pending_server_callbacks = {}
  last_server_stderr = ""
  auto_install_triggered = false

  request_token_counter = 0
  latest_request_token_by_buf = {}

  current_config = clone(DEFAULT_CONFIG)
  configured = false
  activated_for_tex = false
  commands_registered = false
  startup_notified = false
  last_operation = nil
  trailing_bang_hint_notified = false
end

function M._is_activated_for_tests()
  return activated_for_tex
end

function M._is_server_running_for_tests()
  return is_server_running()
end

function M._startup_notified_for_tests()
  return startup_notified
end

function M._parse_operation_args_for_tests(op_name, args)
  return parse_operation_args(op_name, args)
end

function M._apply_mode_from_bang_for_tests(opts)
  return apply_mode_from_bang(opts)
end

function M._mark_request_for_buffer_for_tests(buf)
  return mark_request_for_buffer(buf)
end

function M._is_stale_request_for_tests(buf, token)
  return is_stale_request(buf, token)
end

function M._normalize_params_for_payload_for_tests(params)
  return normalize_params_for_payload(params)
end

function M._completion_for_ops_for_tests(arg_lead)
  return completion_for_ops(arg_lead or "")
end

function M._default_keymaps_for_tests()
  return clone(DEFAULT_KEYMAPS)
end

function M._picker_entries_for_tests()
  return build_picker_entries()
end

function M._picker_entries_for_context_for_tests(entries, selection_available, show_unavailable)
  return picker_entries_for_context(entries or {}, selection_available == true, show_unavailable == true)
end

function M._picker_filter_entries_for_tests(entries, query)
  return picker_filter_entries(entries or {}, query or "")
end

function M._picker_categories_for_tests()
  return build_picker_categories()
end

function M._format_picker_item_for_tests(item)
  return format_picker_item_row(item)
end

function M._guided_args_from_values_for_tests(guided_key, values)
  local schema = PICKER_GUIDED_ARGS_SCHEMA[guided_key]
  if not schema then
    return nil, "No guided args schema for " .. tostring(guided_key)
  end
  return guided_args_from_values(schema, values or {})
end

function M._truncate_single_line_for_tests(text, max_chars)
  return truncate_single_line(text, max_chars)
end

function M._notify_success_result_for_tests(context, result_text)
  notify_success_result(context, result_text)
end

function M._normalize_trailing_bang_opts_for_tests(opts)
  return normalize_trailing_bang_opts(opts or {})
end

function M._run_picker_entry_for_tests(label, opts, raw_args)
  local entries = build_picker_entries()
  for _, entry in ipairs(entries) do
    if entry.label == label then
      run_picker_entry(entry, opts or {}, raw_args or "")
      return true
    end
  end
  return false
end

function M._resolve_picker_apply_mode_for_tests(entry, opts, selection_value)
  local prompted = false
  local resolved_opts = nil

  resolve_picker_apply_mode(entry or {}, opts or {}, function(items, _, on_choice)
    prompted = true
    if selection_value == nil then
      on_choice(nil)
      return
    end
    for _, item in ipairs(items or {}) do
      if item.value == selection_value then
        on_choice(item)
        return
      end
    end
    on_choice(items and items[1] or nil)
  end, function(value)
    resolved_opts = value
  end)

  return resolved_opts, prompted
end

function M._resolved_picker_backend_for_tests()
  if type(current_config.picker_select) == "function" then
    return "custom"
  end
  local backend = normalize_picker_backend(current_config.picker_backend)
  local has_vim_ui = vim.ui and type(vim.ui.select) == "function"
  if backend == "snacks" then
    if snacks_select_available() then
      return "snacks"
    end
    return has_vim_ui and "vim_ui" or "inputlist"
  end
  if backend == "auto" then
    if snacks_select_available() then
      return "snacks"
    end
    return has_vim_ui and "vim_ui" or "inputlist"
  end
  return has_vim_ui and "vim_ui" or "inputlist"
end

return M
