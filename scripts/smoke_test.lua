local function fail(message)
  io.stderr:write("latex_sympy smoke: " .. tostring(message) .. "\n")
  os.exit(1)
end

local function assert_true(condition, message)
  if not condition then
    fail(message)
  end
end

local function assert_equals(expected, actual, label)
  if expected ~= actual then
    fail(string.format("%s expected=%s actual=%s", label, tostring(expected), tostring(actual)))
  end
end

local function command_exists(name)
  return vim.api.nvim_get_commands({})[name] ~= nil
end

local function run_smoke()
  package.loaded["plugin.plugin"] = nil
  package.loaded["latex_sympy"] = nil

  local ok_mod, mod_or_err = pcall(require, "latex_sympy")
  assert_true(ok_mod, mod_or_err)
  mod_or_err._reset_state_for_tests()

  local ok_loader, loader_or_err = pcall(require, "plugin.plugin")
  assert_true(ok_loader, loader_or_err)

  -- Non-tex buffers should not activate commands.
  vim.api.nvim_exec_autocmds("FileType", { pattern = "markdown", modeline = false })
  assert_true(not command_exists("LatexSympyOp"), "LatexSympyOp must not be registered for non-tex")
  assert_true(not command_exists("LatexSympySolve"), "LatexSympySolve must not be registered for non-tex")

  local pre_map = vim.fn.maparg("<leader>le", "x", false, true)
  assert_true(pre_map.lhs == nil or pre_map.lhs == "", "default tex keymaps must not exist before tex activation")

  -- First tex activation should register commands.
  vim.api.nvim_exec_autocmds("FileType", { pattern = "tex", modeline = false })
  assert_true(command_exists("LatexSympyReplace"), "LatexSympyReplace should be registered after tex activation")
  assert_true(command_exists("LatexSympyOp"), "LatexSympyOp should be registered after tex activation")
  assert_true(command_exists("LatexSympyPick"), "LatexSympyPick should be registered after tex activation")
  assert_true(command_exists("LatexSympySolve"), "LatexSympySolve should be registered after tex activation")
  assert_true(command_exists("LatexSympyDiff"), "LatexSympyDiff should be registered after tex activation")
  assert_true(command_exists("LatexSympyIntegrate"), "LatexSympyIntegrate should be registered after tex activation")
  assert_true(command_exists("LatexSympyDet"), "LatexSympyDet should be registered after tex activation")
  assert_true(command_exists("LatexSympyInv"), "LatexSympyInv should be registered after tex activation")
  assert_true(command_exists("LatexSympyRepeat"), "LatexSympyRepeat should be registered after tex activation")

  local op_completion = mod_or_err._completion_for_ops_for_tests("")
  assert_true(vim.tbl_contains(op_completion, "simplify"), "completion must include simplify")
  assert_true(vim.tbl_contains(op_completion, "div"), "completion must include div")
  assert_true(vim.tbl_contains(op_completion, "gcd"), "completion must include gcd")
  assert_true(vim.tbl_contains(op_completion, "sqf"), "completion must include sqf")
  assert_true(vim.tbl_contains(op_completion, "groebner"), "completion must include groebner")
  assert_true(vim.tbl_contains(op_completion, "resultant"), "completion must include resultant")
  assert_true(vim.tbl_contains(op_completion, "summation"), "completion must include summation")
  assert_true(vim.tbl_contains(op_completion, "product"), "completion must include product")
  assert_true(vim.tbl_contains(op_completion, "binomial"), "completion must include binomial")
  assert_true(vim.tbl_contains(op_completion, "perm"), "completion must include perm")
  assert_true(vim.tbl_contains(op_completion, "comb"), "completion must include comb")
  assert_true(vim.tbl_contains(op_completion, "partition"), "completion must include partition")
  assert_true(vim.tbl_contains(op_completion, "subsets"), "completion must include subsets")
  assert_true(vim.tbl_contains(op_completion, "totient"), "completion must include totient")
  assert_true(vim.tbl_contains(op_completion, "mobius"), "completion must include mobius")
  assert_true(vim.tbl_contains(op_completion, "divisors"), "completion must include divisors")
  assert_true(vim.tbl_contains(op_completion, "logic_simplify"), "completion must include logic_simplify")
  assert_true(vim.tbl_contains(op_completion, "sat"), "completion must include sat")
  assert_true(vim.tbl_contains(op_completion, "jordan"), "completion must include jordan")
  assert_true(vim.tbl_contains(op_completion, "svd"), "completion must include svd")
  assert_true(vim.tbl_contains(op_completion, "cholesky"), "completion must include cholesky")
  assert_true(vim.tbl_contains(op_completion, "symbol"), "completion must include symbol")
  assert_true(vim.tbl_contains(op_completion, "symbols"), "completion must include symbols")
  assert_true(vim.tbl_contains(op_completion, "symbols_reset"), "completion must include symbols_reset")
  assert_true(vim.tbl_contains(op_completion, "geometry"), "completion must include geometry")
  assert_true(vim.tbl_contains(op_completion, "intersect"), "completion must include intersect")
  assert_true(vim.tbl_contains(op_completion, "tangent"), "completion must include tangent")
  assert_true(vim.tbl_contains(op_completion, "similar"), "completion must include similar")
  assert_true(vim.tbl_contains(op_completion, "units"), "completion must include units")
  assert_true(vim.tbl_contains(op_completion, "mechanics"), "completion must include mechanics")
  assert_true(vim.tbl_contains(op_completion, "quantum"), "completion must include quantum")
  assert_true(vim.tbl_contains(op_completion, "optics"), "completion must include optics")
  assert_true(vim.tbl_contains(op_completion, "pauli"), "completion must include pauli")
  assert_true(vim.tbl_contains(op_completion, "dist"), "completion must include dist")
  assert_true(vim.tbl_contains(op_completion, "p"), "completion must include p")
  assert_true(vim.tbl_contains(op_completion, "e"), "completion must include e")
  assert_true(vim.tbl_contains(op_completion, "var"), "completion must include var")
  assert_true(vim.tbl_contains(op_completion, "density"), "completion must include density")
  assert_true(vim.tbl_contains(op_completion, "trigsimp"), "completion must include trigsimp")
  assert_true(vim.tbl_contains(op_completion, "ratsimp"), "completion must include ratsimp")
  assert_true(vim.tbl_contains(op_completion, "powsimp"), "completion must include powsimp")
  assert_true(vim.tbl_contains(op_completion, "apart"), "completion must include apart")
  assert_true(vim.tbl_contains(op_completion, "subs"), "completion must include subs")
  assert_true(vim.tbl_contains(op_completion, "solveset"), "completion must include solveset")
  assert_true(vim.tbl_contains(op_completion, "linsolve"), "completion must include linsolve")
  assert_true(vim.tbl_contains(op_completion, "nonlinsolve"), "completion must include nonlinsolve")
  assert_true(vim.tbl_contains(op_completion, "rsolve"), "completion must include rsolve")
  assert_true(vim.tbl_contains(op_completion, "diophantine"), "completion must include diophantine")
  assert_true(vim.tbl_contains(op_completion, "eigenvects"), "completion must include eigenvects")
  assert_true(vim.tbl_contains(op_completion, "nullspace"), "completion must include nullspace")
  assert_true(vim.tbl_contains(op_completion, "charpoly"), "completion must include charpoly")
  assert_true(vim.tbl_contains(op_completion, "lu"), "completion must include lu")
  assert_true(vim.tbl_contains(op_completion, "qr"), "completion must include qr")
  assert_true(vim.tbl_contains(op_completion, "mat_solve"), "completion must include mat_solve")
  assert_true(vim.tbl_contains(op_completion, "isprime"), "completion must include isprime")
  assert_true(vim.tbl_contains(op_completion, "factorint"), "completion must include factorint")
  assert_true(vim.tbl_contains(op_completion, "primerange"), "completion must include primerange")

  -- Verify hard defaults that must remain stable.
  local cfg = mod_or_err.get_config()
  assert_equals(5000, cfg.timeout_ms, "timeout_ms")
  assert_equals(false, cfg.preview_before_apply, "preview_before_apply")
  assert_equals(160, cfg.preview_max_chars, "preview_max_chars")
  assert_equals(true, cfg.drop_stale_results, "drop_stale_results")
  assert_equals(false, cfg.notify_info, "notify_info")
  assert_equals(true, cfg.default_keymaps, "default_keymaps")
  assert_equals("<leader>l", cfg.keymap_prefix, "keymap_prefix")
  assert_equals("<leader>x", cfg.normal_keymap_prefix, "normal_keymap_prefix")
  assert_equals(true, cfg.respect_existing_keymaps, "respect_existing_keymaps")

  local visual_equal = vim.fn.maparg("<leader>le", "x", false, true)
  local visual_op = vim.fn.maparg("<leader>lo", "x", false, true)
  local visual_picker = vim.fn.maparg("<leader>lp", "x", false, true)
  local normal_status = vim.fn.maparg("<leader>xS", "n", false, true)
  assert_true(type(visual_equal.rhs) == "string" and visual_equal.rhs:find("LatexSympyEqual", 1, true) ~= nil, "visual keymap equal")
  assert_true(type(visual_op.rhs) == "string" and visual_op.rhs:find("LatexSympyOp", 1, true) ~= nil, "visual keymap op")
  assert_true(type(visual_picker.rhs) == "string" and visual_picker.rhs:find("LatexSympyPick", 1, true) ~= nil, "visual keymap picker")
  assert_true(type(normal_status.rhs) == "string" and normal_status.rhs:find("LatexSympyStatus", 1, true) ~= nil, "normal keymap status")

  io.write("latex_sympy smoke: ok\n")
end

local ok, err = pcall(run_smoke)
if not ok then
  fail(err)
end

vim.cmd("qa!")
