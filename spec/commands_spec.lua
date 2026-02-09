local COMMAND_NAMES = {
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

describe("plugin loader", function()
  local original_notify
  local notifications

  local function command_exists(name)
    return vim.api.nvim_get_commands({})[name] ~= nil
  end

  before_each(function()
    package.loaded["plugin.plugin"] = nil
    package.loaded["latex_sympy"] = nil

    local mod = require("latex_sympy")
    mod._reset_state_for_tests()

    original_notify = vim.notify
    notifications = {}
    vim.notify = function(message, level, _)
      table.insert(notifications, { message = tostring(message), level = level })
    end
  end)

  after_each(function()
    vim.notify = original_notify

    local mod = package.loaded["latex_sympy"]
    if mod and mod._reset_state_for_tests then
      mod._reset_state_for_tests()
    end

    package.loaded["plugin.plugin"] = nil
    package.loaded["latex_sympy"] = nil
  end)

  it("does not activate on non-tex filetype", function()
    require("plugin.plugin")
    vim.api.nvim_exec_autocmds("FileType", { pattern = "markdown", modeline = false })

    local mod = require("latex_sympy")
    assert.is_false(mod._is_activated_for_tests())
    assert.is_false(command_exists("LatexSympyEqual"))
  end)

  it("activates on tex filetype and registers commands", function()
    require("plugin.plugin")

    assert.is_false(command_exists("LatexSympyEqual"))

    vim.api.nvim_exec_autocmds("FileType", { pattern = "tex", modeline = false })

    for _, name in ipairs(COMMAND_NAMES) do
      assert.is_true(command_exists(name), name .. " should be registered")
    end
  end)

  it("notifies only once per session on activation", function()
    require("plugin.plugin")

    vim.api.nvim_exec_autocmds("FileType", { pattern = "tex", modeline = false })
    vim.api.nvim_exec_autocmds("FileType", { pattern = "tex", modeline = false })

    local count = 0
    for _, item in ipairs(notifications) do
      if item.message:find("latex_sympy: active", 1, true) then
        count = count + 1
      end
    end

    assert.equals(1, count)
  end)
end)

describe("operation parsing", function()
  before_each(function()
    package.loaded["latex_sympy"] = nil
    local mod = require("latex_sympy")
    mod._reset_state_for_tests()
  end)

  after_each(function()
    local mod = package.loaded["latex_sympy"]
    if mod and mod._reset_state_for_tests then
      mod._reset_state_for_tests()
    end
    package.loaded["latex_sympy"] = nil
  end)

  it("parses solve/diff/integrate args", function()
    local mod = require("latex_sympy")

    local solve_params = mod._parse_operation_args_for_tests("solve", { "x" })
    assert.same({ var = "x" }, solve_params)

    local solve_many_params = mod._parse_operation_args_for_tests("solve", { "x", "y" })
    assert.same({ vars = { "x", "y" } }, solve_many_params)

    local diff_params = mod._parse_operation_args_for_tests("diff", { "x", "3" })
    assert.same({ var = "x", order = 3 }, diff_params)

    local diff_chain_params = mod._parse_operation_args_for_tests("diff", { "x", "2", "y", "1" })
    assert.same({ chain = { { var = "x", order = 2 }, { var = "y", order = 1 } } }, diff_chain_params)

    local integrate_params = mod._parse_operation_args_for_tests("integrate", { "x", "0", "1" })
    assert.same({ var = "x", lower = "0", upper = "1" }, integrate_params)

    local integrate_bounds = mod._parse_operation_args_for_tests("integrate", { "x", "0", "1", "y", "0", "2" })
    assert.same({
      bounds = {
        { var = "x", lower = "0", upper = "1" },
        { var = "y", lower = "0", upper = "2" },
      },
    }, integrate_bounds)
  end)

  it("parses limit and series args", function()
    local mod = require("latex_sympy")

    local limit_params = mod._parse_operation_args_for_tests("limit", { "x", "0" })
    assert.same({ var = "x", point = "0", dir = "+-" }, limit_params)

    local series_params = mod._parse_operation_args_for_tests("series", { "x", "0", "5" })
    assert.same({ var = "x", point = "0", order = 5 }, series_params)
  end)

  it("parses simplify/apart/subs args", function()
    local mod = require("latex_sympy")

    local simplify_params = mod._parse_operation_args_for_tests("simplify", {})
    assert.same({}, simplify_params)

    local apart_params = mod._parse_operation_args_for_tests("apart", { "x" })
    assert.same({ var = "x" }, apart_params)

    local subs_params = mod._parse_operation_args_for_tests("subs", { "x=2", "y=3" })
    assert.same({
      assignments = {
        { symbol = "x", value = "2" },
        { symbol = "y", value = "3" },
      },
    }, subs_params)
  end)

  it("parses nsolve/dsolve/solve_system args", function()
    local mod = require("latex_sympy")

    local nsolve_params = mod._parse_operation_args_for_tests("nsolve", { "x", "1", "2" })
    assert.same({ var = "x", guess = "1", guess2 = "2" }, nsolve_params)

    local dsolve_params = mod._parse_operation_args_for_tests("dsolve", { "y(x)" })
    assert.same({ func = "y(x)" }, dsolve_params)

    local solve_system_params = mod._parse_operation_args_for_tests("solve_system", { "x", "y" })
    assert.same({ vars = { "x", "y" } }, solve_system_params)
  end)

  it("parses equation depth args", function()
    local mod = require("latex_sympy")

    local solveset_domain_only = mod._parse_operation_args_for_tests("solveset", { "R" })
    assert.same({ domain = "R" }, solveset_domain_only)

    local solveset_full = mod._parse_operation_args_for_tests("solveset", { "x", "z" })
    assert.same({ var = "x", domain = "Z" }, solveset_full)

    local linsolve_params = mod._parse_operation_args_for_tests("linsolve", { "x", "y" })
    assert.same({ vars = { "x", "y" } }, linsolve_params)

    local nonlinsolve_params = mod._parse_operation_args_for_tests("nonlinsolve", { "x", "y" })
    assert.same({ vars = { "x", "y" } }, nonlinsolve_params)

    local rsolve_params = mod._parse_operation_args_for_tests("rsolve", { "a(n)" })
    assert.same({ func = "a(n)" }, rsolve_params)

    local diophantine_params = mod._parse_operation_args_for_tests("diophantine", { "x", "y" })
    assert.same({ vars = { "x", "y" } }, diophantine_params)
  end)

  it("parses matrix depth and number theory args", function()
    local mod = require("latex_sympy")

    local charpoly_params = mod._parse_operation_args_for_tests("charpoly", { "t" })
    assert.same({ var = "t" }, charpoly_params)

    local primerange_params = mod._parse_operation_args_for_tests("primerange", { "10", "40" })
    assert.same({ start = 10, stop = 40 }, primerange_params)

    local nullspace_params = mod._parse_operation_args_for_tests("nullspace", {})
    assert.same({}, nullspace_params)

    local mat_solve_params = mod._parse_operation_args_for_tests("mat_solve", {})
    assert.same({}, mat_solve_params)

    local isprime_params = mod._parse_operation_args_for_tests("isprime", {})
    assert.same({}, isprime_params)
  end)

  it("parses planned feature args", function()
    local mod = require("latex_sympy")

    assert.same({ var = "x" }, mod._parse_operation_args_for_tests("div", { "x" }))
    assert.same({ var = "x" }, mod._parse_operation_args_for_tests("gcd", { "x" }))
    assert.same({ var = "x" }, mod._parse_operation_args_for_tests("sqf", { "x" }))
    assert.same({ vars = { "x", "y" }, order = "grlex" }, mod._parse_operation_args_for_tests("groebner", { "x", "y", "grlex" }))
    assert.same({ var = "x" }, mod._parse_operation_args_for_tests("resultant", { "x" }))
    assert.same({ var = "k", lower = "1", upper = "n" }, mod._parse_operation_args_for_tests("summation", { "k", "1", "n" }))
    assert.same({ var = "k", lower = "1", upper = "n" }, mod._parse_operation_args_for_tests("product", { "k", "1", "n" }))

    assert.same({ n = "5", k = "2" }, mod._parse_operation_args_for_tests("binomial", { "5", "2" }))
    assert.same({ n = "5", k = "2" }, mod._parse_operation_args_for_tests("perm", { "5", "2" }))
    assert.same({ n = "5", k = "2" }, mod._parse_operation_args_for_tests("comb", { "5", "2" }))
    assert.same({ n = "8" }, mod._parse_operation_args_for_tests("partition", { "8" }))
    assert.same({ k = 2 }, mod._parse_operation_args_for_tests("subsets", { "2" }))
    assert.same({ proper = true }, mod._parse_operation_args_for_tests("divisors", { "true" }))
    assert.same({ action = "order" }, mod._parse_operation_args_for_tests("perm_group", { "order" }))
    assert.same({ action = "stabilizer", point = 0 }, mod._parse_operation_args_for_tests("perm_group", { "stabilizer", "0" }))
    assert.same({ action = "encode", n = 4 }, mod._parse_operation_args_for_tests("prufer", { "encode", "4" }))
    assert.same({ action = "decode" }, mod._parse_operation_args_for_tests("prufer", { "decode" }))
    assert.same({ action = "sequence", value = 3 }, mod._parse_operation_args_for_tests("gray", { "sequence", "3" }))
    assert.same({ action = "bin_to_gray", value = "1011" }, mod._parse_operation_args_for_tests("gray", { "bin_to_gray", "1011" }))

    assert.same({ form = "cnf" }, mod._parse_operation_args_for_tests("logic_simplify", { "cnf" }))
    assert.same({}, mod._parse_operation_args_for_tests("sat", {}))
    assert.same({}, mod._parse_operation_args_for_tests("jordan", {}))
    assert.same({}, mod._parse_operation_args_for_tests("svd", {}))
    assert.same({}, mod._parse_operation_args_for_tests("cholesky", {}))

    assert.same({
      name = "x",
      assumptions = { real = true, nonnegative = false },
    }, mod._parse_operation_args_for_tests("symbol", { "x", "real=true", "nonnegative=false" }))
    assert.same({}, mod._parse_operation_args_for_tests("symbols", {}))
    assert.same({}, mod._parse_operation_args_for_tests("symbols_reset", {}))
    assert.same({}, mod._parse_operation_args_for_tests("geometry", {}))
    assert.same({}, mod._parse_operation_args_for_tests("intersect", {}))
    assert.same({}, mod._parse_operation_args_for_tests("tangent", {}))
    assert.same({}, mod._parse_operation_args_for_tests("similar", {}))

    assert.same({ action = "simplify" }, mod._parse_operation_args_for_tests("units", { "simplify" }))
    assert.same({ action = "convert", target = "meter" }, mod._parse_operation_args_for_tests("units", { "convert", "meter" }))
    assert.same({ action = "euler_lagrange", qs = { "q(t)" } }, mod._parse_operation_args_for_tests("mechanics", { "euler_lagrange", "q(t)" }))
    assert.same({ action = "dagger" }, mod._parse_operation_args_for_tests("quantum", { "dagger" }))
    assert.same({ action = "commutator", expr2 = "B" }, mod._parse_operation_args_for_tests("quantum", { "commutator", "B" }))
    assert.same({ action = "refraction", incident = "1", n1 = "1", n2 = "2" }, mod._parse_operation_args_for_tests("optics", { "refraction", "1", "1", "2" }))
    assert.same({
      action = "lens",
      options = { focal_length = "2", u = "3" },
    }, mod._parse_operation_args_for_tests("optics", { "lens", "focal_length=2", "u=3" }))
    assert.same({ action = "simplify" }, mod._parse_operation_args_for_tests("pauli", { "simplify" }))
    assert.same({
      kind = "normal",
      name = "X",
      args = { "0", "1" },
    }, mod._parse_operation_args_for_tests("dist", { "normal", "X", "0", "1" }))
    assert.same({}, mod._parse_operation_args_for_tests("p", {}))
    assert.same({}, mod._parse_operation_args_for_tests("e", {}))
    assert.same({}, mod._parse_operation_args_for_tests("var", {}))
    assert.same({}, mod._parse_operation_args_for_tests("density", {}))
  end)

  it("returns error for invalid op args", function()
    local mod = require("latex_sympy")

    local _, err_unknown = mod._parse_operation_args_for_tests("unknown", {})
    assert.is_truthy(err_unknown)

    local _, err_series = mod._parse_operation_args_for_tests("series", { "x", "0", "bad" })
    assert.is_truthy(err_series)

    local _, err_nsolve = mod._parse_operation_args_for_tests("nsolve", { "x" })
    assert.is_truthy(err_nsolve)

    local _, err_diff = mod._parse_operation_args_for_tests("diff", { "x", "2", "0" })
    assert.is_truthy(err_diff)

    local _, err_apart = mod._parse_operation_args_for_tests("apart", { "x", "y" })
    assert.is_truthy(err_apart)

    local _, err_subs_missing = mod._parse_operation_args_for_tests("subs", {})
    assert.is_truthy(err_subs_missing)

    local _, err_subs_token = mod._parse_operation_args_for_tests("subs", { "x" })
    assert.is_truthy(err_subs_token)

    local _, err_solveset = mod._parse_operation_args_for_tests("solveset", { "x", "Q" })
    assert.is_truthy(err_solveset)

    local _, err_rsolve = mod._parse_operation_args_for_tests("rsolve", { "a(n)", "extra" })
    assert.is_truthy(err_rsolve)

    local _, err_charpoly = mod._parse_operation_args_for_tests("charpoly", { "x", "y" })
    assert.is_truthy(err_charpoly)

    local _, err_primerange_arity = mod._parse_operation_args_for_tests("primerange", { "10" })
    assert.is_truthy(err_primerange_arity)

    local _, err_primerange_type = mod._parse_operation_args_for_tests("primerange", { "a", "20" })
    assert.is_truthy(err_primerange_type)

    local _, err_groebner = mod._parse_operation_args_for_tests("groebner", {})
    assert.is_truthy(err_groebner)

    local _, err_resultant = mod._parse_operation_args_for_tests("resultant", {})
    assert.is_truthy(err_resultant)

    local _, err_subsets = mod._parse_operation_args_for_tests("subsets", { "-1" })
    assert.is_truthy(err_subsets)

    local _, err_divisors = mod._parse_operation_args_for_tests("divisors", { "maybe" })
    assert.is_truthy(err_divisors)

    local _, err_logic = mod._parse_operation_args_for_tests("logic_simplify", { "xor" })
    assert.is_truthy(err_logic)

    local _, err_symbol = mod._parse_operation_args_for_tests("symbol", { "x", "bad=true" })
    assert.is_truthy(err_symbol)

    local _, err_units = mod._parse_operation_args_for_tests("units", { "convert" })
    assert.is_truthy(err_units)

    local _, err_quantum = mod._parse_operation_args_for_tests("quantum", { "commutator" })
    assert.is_truthy(err_quantum)

    local _, err_optics = mod._parse_operation_args_for_tests("optics", { "lens", "f=2" })
    assert.is_truthy(err_optics)

    local _, err_dist = mod._parse_operation_args_for_tests("dist", { "unknown", "X" })
    assert.is_truthy(err_dist)

    local _, err_prob = mod._parse_operation_args_for_tests("p", { "x" })
    assert.is_truthy(err_prob)

    local _, err_perm_group_action = mod._parse_operation_args_for_tests("perm_group", { "bad" })
    assert.is_truthy(err_perm_group_action)

    local _, err_perm_group_point = mod._parse_operation_args_for_tests("perm_group", { "stabilizer" })
    assert.is_truthy(err_perm_group_point)

    local _, err_perm_group_point_type = mod._parse_operation_args_for_tests("perm_group", { "stabilizer", "bad" })
    assert.is_truthy(err_perm_group_point_type)

    local _, err_prufer_encode = mod._parse_operation_args_for_tests("prufer", { "encode" })
    assert.is_truthy(err_prufer_encode)

    local _, err_prufer_decode = mod._parse_operation_args_for_tests("prufer", { "decode", "4" })
    assert.is_truthy(err_prufer_decode)

    local _, err_gray_action = mod._parse_operation_args_for_tests("gray", { "bad", "101" })
    assert.is_truthy(err_gray_action)

    local _, err_gray_value = mod._parse_operation_args_for_tests("gray", { "bin_to_gray", "abc" })
    assert.is_truthy(err_gray_value)

    local _, err_gray_sequence = mod._parse_operation_args_for_tests("gray", { "sequence", "0" })
    assert.is_truthy(err_gray_sequence)
  end)

  it("includes new ops in completion with empty prefix", function()
    local mod = require("latex_sympy")
    local values = mod._completion_for_ops_for_tests("")

    assert.is_true(vim.tbl_contains(values, "simplify"))
    assert.is_true(vim.tbl_contains(values, "subs"))
    assert.is_true(vim.tbl_contains(values, "solve"))
    assert.is_true(vim.tbl_contains(values, "solve_system"))
    assert.is_true(vim.tbl_contains(values, "solveset"))
    assert.is_true(vim.tbl_contains(values, "groebner"))
    assert.is_true(vim.tbl_contains(values, "logic_simplify"))
    assert.is_true(vim.tbl_contains(values, "units"))
    assert.is_true(vim.tbl_contains(values, "dist"))
    assert.is_true(vim.tbl_contains(values, "perm_group"))
    assert.is_true(vim.tbl_contains(values, "prufer"))
    assert.is_true(vim.tbl_contains(values, "gray"))
  end)

  it("filters completion by prefix", function()
    local mod = require("latex_sympy")
    local values = mod._completion_for_ops_for_tests("s")

    assert.is_true(#values > 0)
    for _, value in ipairs(values) do
      assert.is_true(vim.startswith(value, "s"), value)
    end

    assert.is_true(vim.tbl_contains(values, "simplify"))
    assert.is_true(vim.tbl_contains(values, "solve"))
    assert.is_true(vim.tbl_contains(values, "solveset"))
    assert.is_false(vim.tbl_contains(values, "groebner"))
    assert.is_false(vim.tbl_contains(values, "dist"))
    assert.is_false(vim.tbl_contains(values, "perm_group"))
  end)

  it("maps bang to append mode", function()
    local mod = require("latex_sympy")
    assert.equals("append", mod._apply_mode_from_bang_for_tests({ bang = true }))
    assert.equals("replace", mod._apply_mode_from_bang_for_tests({ bang = false }))
  end)

  it("tracks stale requests by buffer", function()
    local mod = require("latex_sympy")
    local buf = 12

    local token_a = mod._mark_request_for_buffer_for_tests(buf)
    assert.is_false(mod._is_stale_request_for_tests(buf, token_a))

    local token_b = mod._mark_request_for_buffer_for_tests(buf)
    assert.is_true(token_b > token_a)
    assert.is_true(mod._is_stale_request_for_tests(buf, token_a))
    assert.is_false(mod._is_stale_request_for_tests(buf, token_b))
  end)

  it("normalizes empty op params to a JSON object", function()
    local mod = require("latex_sympy")
    local normalized = mod._normalize_params_for_payload_for_tests({})

    if vim.type then
      assert.equals("dict", vim.type(normalized))
    else
      local encoded = vim.fn.json_encode({ params = normalized })
      local compact = encoded:gsub("%s+", "")
      assert.is_true(compact:find([["params":{}]], 1, true) ~= nil)
      assert.is_true(compact:find("\"params\":[]", 1, true) == nil)
    end
  end)
end)

describe("default keymaps", function()
  before_each(function()
    package.loaded["latex_sympy"] = nil
    package.loaded["plugin.plugin"] = nil

    local mod = require("latex_sympy")
    mod._reset_state_for_tests()
  end)

  after_each(function()
    pcall(vim.keymap.del, "x", "<leader>le")

    local mod = package.loaded["latex_sympy"]
    if mod and mod._reset_state_for_tests then
      mod._reset_state_for_tests()
    end

    package.loaded["plugin.plugin"] = nil
    package.loaded["latex_sympy"] = nil
  end)

  it("applies leader keymaps for tex buffers", function()
    require("plugin.plugin")
    vim.api.nvim_exec_autocmds("FileType", { pattern = "tex", modeline = false })

    local visual_equal = vim.fn.maparg("<leader>le", "x", false, true)
    local visual_op = vim.fn.maparg("<leader>lo", "x", false, true)
    local visual_picker = vim.fn.maparg("<leader>lp", "x", false, true)
    local normal_status = vim.fn.maparg("<leader>xS", "n", false, true)

    assert.is_true(type(visual_equal.rhs) == "string" and visual_equal.rhs:find("LatexSympyEqual", 1, true) ~= nil)
    assert.is_true(type(visual_op.rhs) == "string" and visual_op.rhs:find("LatexSympyOp", 1, true) ~= nil)
    assert.is_true(type(visual_picker.rhs) == "string" and visual_picker.rhs:find("LatexSympyPick", 1, true) ~= nil)
    assert.is_true(type(normal_status.rhs) == "string" and normal_status.rhs:find("LatexSympyStatus", 1, true) ~= nil)
  end)

  it("respects existing mappings when configured", function()
    vim.keymap.set("x", "<leader>le", "<Cmd>echo 'keep'<CR>", { silent = true })

    local existing = vim.fn.maparg("<leader>le", "x", false, true)
    assert.is_true(tostring(existing.rhs):find("echo", 1, true) ~= nil)

    require("plugin.plugin")
    vim.api.nvim_exec_autocmds("FileType", { pattern = "tex", modeline = false })

    local preserved = vim.fn.maparg("<leader>le", "x", false, true)
    assert.is_true(tostring(preserved.rhs):find("echo", 1, true) ~= nil)
  end)

  it("can disable default keymaps", function()
    local mod = require("latex_sympy")
    mod.setup({ default_keymaps = false })
    mod.activate_for_tex_buffer(0)

    local visual_equal = vim.fn.maparg("<leader>le", "x", false, true)
    assert.is_true(visual_equal.lhs == nil or visual_equal.lhs == "")
  end)
end)

describe("picker behavior", function()
  local original_notify
  local notifications

  before_each(function()
    package.loaded["latex_sympy"] = nil
    local mod = require("latex_sympy")
    mod._reset_state_for_tests()
    mod.setup({})
    mod.activate_for_tex_buffer(0)

    original_notify = vim.notify
    notifications = {}
    vim.notify = function(message, level, _)
      table.insert(notifications, { message = tostring(message), level = level })
    end
  end)

  after_each(function()
    vim.notify = original_notify
    local mod = package.loaded["latex_sympy"]
    if mod and mod._reset_state_for_tests then
      mod._reset_state_for_tests()
    end
    package.loaded["latex_sympy"] = nil
  end)

  it("includes descriptions for picker entries", function()
    local mod = require("latex_sympy")
    local entries = mod._picker_entries_for_tests()
    assert.is_true(#entries > 0)

    for _, entry in ipairs(entries) do
      assert.is_true(type(entry.description) == "string" and entry.description ~= "", entry.label)
    end
  end)

  it("renders descriptive category rows", function()
    local mod = require("latex_sympy")
    local categories = mod._picker_categories_for_tests()
    local formatted = {}

    for _, category in ipairs(categories) do
      table.insert(formatted, mod._format_picker_item_for_tests(category))
    end

    assert.same({
      "All - Everything",
      "Core - Quick transforms (equal/replace/factor/expand/rref)",
      "Ops - Advanced SymPy operations",
      "Aliases - Shortcuts to common ops",
      "Utility - Server/status/session helpers",
    }, formatted)
  end)

  it("renders command rows with one-line descriptions and args hints", function()
    local mod = require("latex_sympy")
    local entries = mod._picker_entries_for_tests()
    local primerange_row
    local perm_group_row
    local simplify_row

    for _, entry in ipairs(entries) do
      if entry.label == "Op: primerange" then
        primerange_row = mod._format_picker_item_for_tests(entry)
      end
      if entry.label == "Op: perm_group" then
        perm_group_row = mod._format_picker_item_for_tests(entry)
      end
      if entry.label == "Op: simplify" then
        simplify_row = mod._format_picker_item_for_tests(entry)
      end
    end

    assert.is_true(type(primerange_row) == "string")
    assert.is_true(primerange_row:find("Op: primerange - List primes in an integer range", 1, true) ~= nil)
    assert.is_true(primerange_row:find("[args: <start> <stop>]", 1, true) ~= nil)
    assert.is_true(primerange_row:find("[append available]", 1, true) ~= nil)

    assert.is_true(type(perm_group_row) == "string")
    assert.is_true(perm_group_row:find("Permutation group analysis from generators", 1, true) ~= nil)
    assert.is_true(perm_group_row:find("[args: <order|orbits|is_transitive|stabilizer> [point]]", 1, true) ~= nil)

    assert.is_true(type(simplify_row) == "string")
    assert.is_true(simplify_row:find("Op: simplify - General symbolic simplification", 1, true) ~= nil)
    assert.is_true(simplify_row:find("[args:", 1, true) == nil)
    assert.is_true(simplify_row:find("[append available]", 1, true) ~= nil)
  end)

  it("does not show append marker for non-append utility commands", function()
    local mod = require("latex_sympy")
    local entries = mod._picker_entries_for_tests()
    local status_row

    for _, entry in ipairs(entries) do
      if entry.label == "Utility: Status" then
        status_row = mod._format_picker_item_for_tests(entry)
      end
    end

    assert.is_true(type(status_row) == "string")
    assert.is_true(status_row:find("[append available]", 1, true) == nil)
  end)

  it("normalizes trailing ! for LatexSympyOp and warns only once", function()
    local mod = require("latex_sympy")

    mod.op({ range = 0, line1 = 0, line2 = 0, bang = false, fargs = { "det", "!" } })

    local saw_converted_warning = false
    local saw_extra_args_error = false
    for _, item in ipairs(notifications) do
      if item.message:find("trailing ! was converted", 1, true) then
        saw_converted_warning = true
      end
      if item.message:find("does not accept extra arguments", 1, true) then
        saw_extra_args_error = true
      end
    end

    assert.is_true(saw_converted_warning)
    assert.is_false(saw_extra_args_error)

    mod.op({ range = 0, line1 = 0, line2 = 0, bang = false, fargs = { "det", "!" } })

    local converted_count = 0
    for _, item in ipairs(notifications) do
      if item.message:find("trailing ! was converted", 1, true) then
        converted_count = converted_count + 1
      end
    end
    assert.equals(1, converted_count)
  end)

  it("prompts apply mode for append-capable entries when picker bang is not set", function()
    local mod = require("latex_sympy")

    local append_opts, append_prompted = mod._resolve_picker_apply_mode_for_tests({
      label = "Op: simplify",
      bang_append = true,
    }, {
      range = 1,
      line1 = 1,
      line2 = 1,
      bang = false,
    }, "append")
    assert.is_true(append_prompted)
    assert.is_true(append_opts and append_opts.bang == true)

    local replace_opts, replace_prompted = mod._resolve_picker_apply_mode_for_tests({
      label = "Op: simplify",
      bang_append = true,
    }, {
      range = 1,
      line1 = 1,
      line2 = 1,
      bang = false,
    }, "replace")
    assert.is_true(replace_prompted)
    assert.is_true(replace_opts and replace_opts.bang == false)
  end)

  it("skips apply mode prompt for forced bang and non-append entries", function()
    local mod = require("latex_sympy")

    local forced_opts, forced_prompted = mod._resolve_picker_apply_mode_for_tests({
      label = "Op: simplify",
      bang_append = true,
    }, {
      range = 1,
      line1 = 1,
      line2 = 1,
      bang = true,
    }, "replace")
    assert.is_false(forced_prompted)
    assert.is_true(forced_opts and forced_opts.bang == true)

    local plain_opts, plain_prompted = mod._resolve_picker_apply_mode_for_tests({
      label = "Utility: Status",
      bang_append = false,
    }, {
      range = 0,
      line1 = 0,
      line2 = 0,
      bang = false,
    }, "append")
    assert.is_false(plain_prompted)
    assert.is_true(plain_opts and plain_opts.bang == false)
  end)

  it("filters picker entries by text query", function()
    local mod = require("latex_sympy")
    local entries = mod._picker_entries_for_tests()
    local filtered = mod._picker_filter_entries_for_tests(entries, "prime")

    assert.is_true(#filtered > 0)
    assert.is_true(#filtered < #entries)

    local saw_isprime = false
    local saw_primerange = false
    for _, item in ipairs(filtered) do
      if item.label == "Op: isprime" then
        saw_isprime = true
      end
      if item.label == "Op: primerange" then
        saw_primerange = true
      end
    end
    assert.is_true(saw_isprime)
    assert.is_true(saw_primerange)
  end)

  it("hides selection-only entries by default when no selection exists", function()
    local mod = require("latex_sympy")
    local entries = mod._picker_entries_for_tests()
    local contextual = mod._picker_entries_for_context_for_tests(entries, false, false)

    for _, item in ipairs(contextual) do
      assert.is_true(item.requires_selection ~= true, item.label)
    end
  end)

  it("marks unavailable rows when configured to show unavailable entries", function()
    local mod = require("latex_sympy")
    local entries = mod._picker_entries_for_tests()
    local contextual = mod._picker_entries_for_context_for_tests(entries, false, true)

    local saw_marked = false
    for _, item in ipairs(contextual) do
      if item.label == "Op: solve" then
        assert.is_true(item.unavailable == true)
        local rendered = mod._format_picker_item_for_tests(item)
        assert.is_true(rendered:find("[needs selection]", 1, true) ~= nil)
        saw_marked = true
      end
    end
    assert.is_true(saw_marked)
  end)

  it("builds guided args from value maps for representative operation families", function()
    local mod = require("latex_sympy")

    local solve_args = mod._guided_args_from_values_for_tests("solve", { vars = "x y" })
    assert.same({ "x", "y" }, solve_args)

    local summation_args = mod._guided_args_from_values_for_tests("summation", {
      var = "k",
      lower = "1",
      upper = "n",
    })
    assert.same({ "k", "1", "n" }, summation_args)

    local units_args = mod._guided_args_from_values_for_tests("units", {
      action = "convert",
      target = "meter",
    })
    assert.same({ "convert", "meter" }, units_args)

    local dist_args = mod._guided_args_from_values_for_tests("dist", {
      kind = "normal",
      name = "X",
      params = "0 1",
    })
    assert.same({ "normal", "X", "0", "1" }, dist_args)
  end)

  it("returns guided args validation error on missing required fields", function()
    local mod = require("latex_sympy")
    local _, err = mod._guided_args_from_values_for_tests("series", {
      var = "x",
      point = "0",
    })
    assert.is_true(type(err) == "string" and err ~= "")
  end)

  it("falls back to raw args prompt when guided args fail and fallback is enabled", function()
    local mod = require("latex_sympy")
    local prompts = {}
    local saw_raw_prompt = false

    mod.setup({
      picker_show_unavailable = true,
      picker_guided_args = "all",
      picker_guided_args_allow_raw = true,
      picker_select = function(items, opts, on_choice)
        if opts.prompt == "latex_sympy category" then
          on_choice(items[3]) -- Ops
          return
        end
        if opts.prompt == "latex_sympy apply mode" then
          on_choice(items[1]) -- Replace
          return
        end
        for _, item in ipairs(items) do
          if item.label == "Op: primerange" then
            on_choice(item)
            return
          end
        end
        on_choice(nil)
      end,
      picker_input = function(opts, on_confirm)
        table.insert(prompts, opts.prompt)
        if opts.prompt == "latex_sympy filter (optional):" then
          on_confirm("")
          return
        end
        if opts.prompt:find("latex_sympy arg %(primerange%)", 1, false) ~= nil then
          on_confirm(nil) -- force guided failure -> raw fallback
          return
        end
        if opts.prompt == "latex_sympy args (primerange): <start> <stop>" then
          saw_raw_prompt = true
          on_confirm("10 20")
          return
        end
        on_confirm(nil)
      end,
    })

    mod.pick({ range = 0, line1 = 0, line2 = 0, bang = false, fargs = {} })
    assert.is_true(saw_raw_prompt)
  end)

  it("uses injected picker callbacks and executes no-args utility directly", function()
    local mod = require("latex_sympy")
    local selected_prompts = {}
    local input_calls = 0

    mod.setup({
      picker_select = function(items, opts, on_choice)
        table.insert(selected_prompts, opts.prompt)
        if opts.prompt == "latex_sympy category" then
          on_choice(items[5]) -- Utility
          return
        end
        for _, item in ipairs(items) do
          if item.label == "Utility: Status" then
            on_choice(item)
            return
          end
        end
        on_choice(nil)
      end,
      picker_input = function(opts, on_confirm)
        input_calls = input_calls + 1
        if opts.prompt == "latex_sympy filter (optional):" then
          on_confirm("")
          return
        end
        on_confirm(nil)
      end,
    })

    mod.pick({ range = 0, line1 = 0, line2 = 0, bang = false, fargs = {} })

    assert.same({ "latex_sympy category", "latex_sympy command" }, selected_prompts)
    assert.equals(0, input_calls)

    local has_status = false
    for _, item in ipairs(notifications) do
      if item.message:find("Server:", 1, true) then
        has_status = true
      end
    end
    assert.is_true(has_status)
  end)

  it("prompts raw args when guided mode is disabled and reports selection error if missing", function()
    local mod = require("latex_sympy")
    local input_called = false

    mod.setup({
      picker_show_unavailable = true,
      picker_guided_args = "off",
      picker_select = function(items, opts, on_choice)
        if opts.prompt == "latex_sympy category" then
          on_choice(items[3]) -- Ops
          return
        end
        if opts.prompt == "latex_sympy apply mode" then
          on_choice(items[1]) -- Replace
          return
        end
        for _, item in ipairs(items) do
          if item.label == "Op: primerange" then
            on_choice(item)
            return
          end
        end
        on_choice(nil)
      end,
      picker_input = function(opts, on_confirm)
        if opts.prompt == "latex_sympy filter (optional):" then
          on_confirm("")
          return
        end
        if opts.prompt == "latex_sympy args (primerange): <start> <stop>" then
          input_called = true
          on_confirm("10 20")
          return
        end
        on_confirm(nil)
      end,
    })

    mod.pick({ range = 0, line1 = 0, line2 = 0, bang = false, fargs = {} })
    assert.is_true(input_called)

    local saw_selection_error = false
    for _, item in ipairs(notifications) do
      if item.message:find("No selection detected", 1, true) then
        saw_selection_error = true
      end
    end
    assert.is_true(saw_selection_error)
  end)

  it("formats and truncates success notifications", function()
    local mod = require("latex_sympy")
    mod.setup({ notify_success = true, notify_success_max_chars = 16 })

    mod._notify_success_result_for_tests("op simplify", "x + y + z + a + b + c")

    local saw_success = false
    for _, item in ipairs(notifications) do
      if item.message:find("success (op simplify):", 1, true) then
        saw_success = true
        assert.is_true(item.message:find("...", 1, true) ~= nil)
      end
    end
    assert.is_true(saw_success)
  end)

  it("suppresses success notifications when disabled", function()
    local mod = require("latex_sympy")
    mod.setup({ notify_success = false })

    mod._notify_success_result_for_tests("op simplify", "x")

    local saw_success = false
    for _, item in ipairs(notifications) do
      if item.message:find("success (", 1, true) then
        saw_success = true
      end
    end
    assert.is_false(saw_success)
  end)

  it("resolves snacks backend gracefully when unavailable", function()
    local mod = require("latex_sympy")
    local original_preload = package.preload["snacks.picker"]
    package.preload["snacks.picker"] = function()
      return {}
    end

    mod.setup({ picker_backend = "snacks", picker_select = nil })
    local backend = mod._resolved_picker_backend_for_tests()

    package.preload["snacks.picker"] = original_preload

    assert.is_true(backend == "vim_ui" or backend == "inputlist")
  end)
end)
