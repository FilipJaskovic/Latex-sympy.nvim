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

    local diff_params = mod._parse_operation_args_for_tests("diff", { "x", "3" })
    assert.same({ var = "x", order = 3 }, diff_params)

    local integrate_params = mod._parse_operation_args_for_tests("integrate", { "x", "0", "1" })
    assert.same({ var = "x", lower = "0", upper = "1" }, integrate_params)
  end)

  it("parses limit and series args", function()
    local mod = require("latex_sympy")

    local limit_params = mod._parse_operation_args_for_tests("limit", { "x", "0" })
    assert.same({ var = "x", point = "0", dir = "+-" }, limit_params)

    local series_params = mod._parse_operation_args_for_tests("series", { "x", "0", "5" })
    assert.same({ var = "x", point = "0", order = 5 }, series_params)
  end)

  it("returns error for invalid op args", function()
    local mod = require("latex_sympy")

    local _, err_unknown = mod._parse_operation_args_for_tests("unknown", {})
    assert.is_truthy(err_unknown)

    local _, err_series = mod._parse_operation_args_for_tests("series", { "x", "0", "bad" })
    assert.is_truthy(err_series)
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
      assert.is_true(encoded:find([["params":{}]], 1, true) ~= nil)
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
    pcall(vim.keymap.del, "x", "<leader>xe")

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

    local visual_equal = vim.fn.maparg("<leader>xe", "x", false, true)
    local visual_op = vim.fn.maparg("<leader>xo", "x", false, true)
    local normal_status = vim.fn.maparg("<leader>xS", "n", false, true)

    assert.is_true(type(visual_equal.rhs) == "string" and visual_equal.rhs:find("LatexSympyEqual", 1, true) ~= nil)
    assert.is_true(type(visual_op.rhs) == "string" and visual_op.rhs:find("LatexSympyOp", 1, true) ~= nil)
    assert.is_true(type(normal_status.rhs) == "string" and normal_status.rhs:find("LatexSympyStatus", 1, true) ~= nil)
  end)

  it("respects existing mappings when configured", function()
    vim.keymap.set("x", "<leader>xe", "<Cmd>echo 'keep'<CR>", { silent = true })
    require("plugin.plugin")
    vim.api.nvim_exec_autocmds("FileType", { pattern = "tex", modeline = false })

    local preserved = vim.fn.maparg("<leader>xe", "x", false, true)
    assert.is_true(tostring(preserved.rhs):find("echo", 1, true) ~= nil)
  end)

  it("can disable default keymaps", function()
    local mod = require("latex_sympy")
    mod.setup({ default_keymaps = false })
    mod.activate_for_tex_buffer(0)

    local visual_equal = vim.fn.maparg("<leader>xe", "x", false, true)
    assert.is_true(visual_equal.lhs == nil or visual_equal.lhs == "")
  end)
end)
