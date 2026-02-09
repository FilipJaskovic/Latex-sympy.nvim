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
  assert_true(command_exists("LatexSympySolve"), "LatexSympySolve should be registered after tex activation")
  assert_true(command_exists("LatexSympyDiff"), "LatexSympyDiff should be registered after tex activation")
  assert_true(command_exists("LatexSympyIntegrate"), "LatexSympyIntegrate should be registered after tex activation")
  assert_true(command_exists("LatexSympyDet"), "LatexSympyDet should be registered after tex activation")
  assert_true(command_exists("LatexSympyInv"), "LatexSympyInv should be registered after tex activation")
  assert_true(command_exists("LatexSympyRepeat"), "LatexSympyRepeat should be registered after tex activation")

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
  local normal_status = vim.fn.maparg("<leader>xS", "n", false, true)
  assert_true(type(visual_equal.rhs) == "string" and visual_equal.rhs:find("LatexSympyEqual", 1, true) ~= nil, "visual keymap equal")
  assert_true(type(visual_op.rhs) == "string" and visual_op.rhs:find("LatexSympyOp", 1, true) ~= nil, "visual keymap op")
  assert_true(type(normal_status.rhs) == "string" and normal_status.rhs:find("LatexSympyStatus", 1, true) ~= nil, "normal keymap status")

  io.write("latex_sympy smoke: ok\n")
end

local ok, err = pcall(run_smoke)
if not ok then
  fail(err)
end

vim.cmd("qa!")
