describe(":LatexSympy commands", function()
  it("defines user commands", function()
    -- Ensure plugin loaded
    require("plugin.plugin")

    local cmds = vim.api.nvim_get_commands({})
    assert.truthy(cmds["LatexSympyEqual"])
    assert.truthy(cmds["LatexSympyReplace"])
    assert.truthy(cmds["LatexSympyNumerical"])
    assert.truthy(cmds["LatexSympyFactor"])
    assert.truthy(cmds["LatexSympyExpand"])
    assert.truthy(cmds["LatexSympyMatrixRREF"])
    assert.truthy(cmds["LatexSympyVariances"])
    assert.truthy(cmds["LatexSympyReset"])
    assert.truthy(cmds["LatexSympyToggleComplex"])
    assert.truthy(cmds["LatexSympyPython"])
    assert.truthy(cmds["LatexSympyStatus"])
    assert.truthy(cmds["LatexSympyRestart"])
    assert.truthy(cmds["LatexSympyStart"])
    assert.truthy(cmds["LatexSympyStop"])
  end)
end)



