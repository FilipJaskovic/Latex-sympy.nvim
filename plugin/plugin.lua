local latex_sympy = require("latex_sympy")

-- Autostart server on startup with defaults; users can call setup() in their config to override
latex_sympy.setup()

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    pcall(latex_sympy.stop_server)
  end,
  desc = "Stop latex_sympy server on exit",
})

-- User commands
vim.api.nvim_create_user_command("LatexSympyEqual", function(opts)
  latex_sympy.equal(opts)
end, { range = true, desc = "Append = <result> for selected LaTeX" })

vim.api.nvim_create_user_command("LatexSympyReplace", function(opts)
  latex_sympy.replace(opts)
end, { range = true, desc = "Replace selection with LaTeX result" })

vim.api.nvim_create_user_command("LatexSympyNumerical", function(opts)
  latex_sympy.numerical(opts)
end, { range = true, desc = "Replace selection with numerical result" })

vim.api.nvim_create_user_command("LatexSympyFactor", function(opts)
  latex_sympy.factor(opts)
end, { range = true, desc = "Replace selection with factored expression" })

vim.api.nvim_create_user_command("LatexSympyExpand", function(opts)
  latex_sympy.expand(opts)
end, { range = true, desc = "Replace selection with expanded expression" })

vim.api.nvim_create_user_command("LatexSympyMatrixRREF", function(opts)
  latex_sympy.matrix_rref(opts)
end, { range = true, desc = "Append \\to <rref> for matrix selection" })

vim.api.nvim_create_user_command("LatexSympyVariances", function()
  latex_sympy.variances()
end, { desc = "Insert current variances mapping at cursor" })

vim.api.nvim_create_user_command("LatexSympyReset", function()
  latex_sympy.reset()
end, { desc = "Reset current variances" })

vim.api.nvim_create_user_command("LatexSympyToggleComplex", function()
  latex_sympy.toggle_complex()
end, { desc = "Toggle complex numbers for variances" })

vim.api.nvim_create_user_command("LatexSympyPython", function(opts)
  latex_sympy.python(opts)
end, { range = true, desc = "Evaluate Python snippet and append = <result>" })

vim.api.nvim_create_user_command("LatexSympyStatus", function()
  latex_sympy.status()
end, { desc = "Show latex_sympy server/config status" })

vim.api.nvim_create_user_command("LatexSympyRestart", function()
  latex_sympy.restart_server()
end, { desc = "Restart the latex_sympy Python server" })

vim.api.nvim_create_user_command("LatexSympyStart", function()
  latex_sympy.start_server()
end, { desc = "Start the latex_sympy Python server" })

vim.api.nvim_create_user_command("LatexSympyStop", function()
  latex_sympy.stop_server()
end, { desc = "Stop the latex_sympy Python server" })


