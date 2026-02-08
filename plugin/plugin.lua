local group = vim.api.nvim_create_augroup("latex_sympy_loader", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "tex",
  callback = function(args)
    local ok, mod = pcall(require, "latex_sympy")
    if not ok then
      vim.notify("latex_sympy: failed to load module", vim.log.levels.ERROR)
      return
    end
    mod.activate_for_tex_buffer(args.buf)
  end,
  desc = "Activate latex_sympy for LaTeX buffers",
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = group,
  callback = function()
    local mod = package.loaded["latex_sympy"]
    if mod and mod.stop_server then
      pcall(mod.stop_server, { silent = true })
    end
  end,
  desc = "Stop latex_sympy server on exit",
})
