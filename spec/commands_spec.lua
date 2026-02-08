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
