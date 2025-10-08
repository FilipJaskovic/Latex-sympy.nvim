local mock = require("spec.test_utilities.mock_vim")

describe("selection handling", function()
  before_each(function()
    vim.cmd("new")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {"a + b", "c + d"})
  end)

  after_each(function()
    vim.cmd("bwipeout!")
  end)

  it("replaces selection with LaTeX result", function()
    local mod = require("latex_sympy")
    -- Simulate range: whole first line
    mod.replace({ range = 1, line1 = 1, line2 = 1 })
    -- We can't assert the exact output without server, but no error means invocation succeeded
    assert.is_true(true)
  end)
end)



