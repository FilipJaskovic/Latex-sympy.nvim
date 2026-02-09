describe("latex_sympy defaults and safety", function()
  local original_notify
  local notifications

  before_each(function()
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

    package.loaded["latex_sympy"] = nil
  end)

  it("uses minimal defaults", function()
    local mod = require("latex_sympy")
    local cfg = mod.get_config()

    assert.equals("python3", cfg.python)
    assert.is_false(cfg.auto_install)
    assert.equals(7395, cfg.port)
    assert.is_false(cfg.enable_python_eval)
    assert.equals("on_demand", cfg.server_start_mode)
    assert.is_true(cfg.notify_startup)
    assert.is_true(cfg.startup_notify_once)
    assert.is_false(cfg.notify_info)
    assert.equals(5000, cfg.timeout_ms)
    assert.is_false(cfg.preview_before_apply)
    assert.equals(160, cfg.preview_max_chars)
    assert.is_true(cfg.drop_stale_results)
    assert.is_true(cfg.default_keymaps)
    assert.equals("<leader>l", cfg.keymap_prefix)
    assert.equals("<leader>x", cfg.normal_keymap_prefix)
    assert.is_true(cfg.respect_existing_keymaps)
  end)

  it("blocks LatexSympyPython by default and avoids server start", function()
    local mod = require("latex_sympy")
    mod.activate_for_tex_buffer(0)

    vim.cmd("new")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "1 + 1" })

    mod.python({ range = 1, line1 = 1, line2 = 1 })

    local found_guard_message = false
    for _, item in ipairs(notifications) do
      if item.message:find("LatexSympyPython is disabled", 1, true) then
        found_guard_message = true
      end
    end

    assert.is_true(found_guard_message)
    assert.is_false(mod._is_server_running_for_tests())

    vim.cmd("bwipeout!")
  end)
end)
