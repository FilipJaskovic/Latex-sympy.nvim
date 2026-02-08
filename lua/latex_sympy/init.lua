local M = {}

local DEFAULT_CONFIG = {
  python = "python3",
  auto_install = false,
  port = 7395,
  enable_python_eval = false,
  notify_startup = true,
  startup_notify_once = true,
  server_start_mode = "on_demand", -- "on_demand" | "on_activate"
}

local function clone(tbl)
  if vim.deepcopy then
    return vim.deepcopy(tbl)
  end
  return vim.tbl_deep_extend("force", {}, tbl)
end

-- Internal state
local server_job_id = nil
local plugin_dir = nil
local intentional_stop = false
local server_ready = false
local server_starting = false
local pending_server_callbacks = {}
local last_server_stderr = ""
local auto_install_triggered = false

local current_config = clone(DEFAULT_CONFIG)
local configured = false
local activated_for_tex = false
local commands_registered = false
local startup_notified = false

local ns_id = vim.api.nvim_create_namespace("latex_sympy")

local LOG = {}
function LOG.info(message)
  vim.notify("latex_sympy: " .. tostring(message), vim.log.levels.INFO)
end
function LOG.warn(message)
  vim.notify("latex_sympy: " .. tostring(message), vim.log.levels.WARN)
end
function LOG.error(message)
  vim.notify("latex_sympy: " .. tostring(message), vim.log.levels.ERROR)
end

local function json_encode(tbl)
  if vim.json and vim.json.encode then
    return vim.json.encode(tbl)
  end
  return vim.fn.json_encode(tbl)
end

local function json_decode(str)
  if vim.json and vim.json.decode then
    return vim.json.decode(str)
  end
  return vim.fn.json_decode(str)
end

local function detect_plugin_dir()
  if plugin_dir then
    return plugin_dir
  end
  local info = debug.getinfo(1, "S")
  local src = info and info.source or ""
  if vim.startswith(src, "@") then
    src = src:sub(2)
  end
  plugin_dir = vim.fn.fnamemodify(src, ":p:h:h:h")
  return plugin_dir
end

local function system_async(cmd, args, on_exit)
  if vim.system then
    vim.system(vim.list_extend({ cmd }, args or {}), { text = true }, function(res)
      local code = res.code or res.signal or 0
      on_exit(code, res.stdout or "", res.stderr or "")
    end)
    return
  end
  local output = {}
  local errout = {}
  vim.fn.jobstart(vim.list_extend({ cmd }, args or {}), {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        table.insert(output, table.concat(data, "\n"))
      end
    end,
    on_stderr = function(_, data)
      if data then
        table.insert(errout, table.concat(data, "\n"))
      end
    end,
    on_exit = function(_, code)
      on_exit(code or 0, table.concat(output, "\n"), table.concat(errout, "\n"))
    end,
  })
end

local function is_server_running()
  return server_job_id ~= nil and server_job_id > 0
end

local function flush_server_callbacks(ok, message)
  if #pending_server_callbacks == 0 then
    return
  end
  local callbacks = pending_server_callbacks
  pending_server_callbacks = {}
  for _, cb in ipairs(callbacks) do
    if cb then
      vim.schedule(function()
        cb(ok, message)
      end)
    end
  end
end

local function probe_server_health(on_result)
  local url = string.format("http://127.0.0.1:%d/health", current_config.port)
  local args = { "-sS", "--max-time", "1", url }
  system_async("curl", args, function(code, stdout, _)
    if code ~= 0 then
      on_result(false)
      return
    end
    local ok, result = pcall(json_decode, stdout)
    if not ok or type(result) ~= "table" then
      on_result(false)
      return
    end
    if result.error and result.error ~= "" then
      on_result(false)
      return
    end
    on_result(result.data == "ok")
  end)
end

local function wait_for_server_ready(on_done, attempt)
  attempt = attempt or 1
  if not is_server_running() then
    on_done(false, "Python server is not running")
    return
  end

  probe_server_health(function(ok)
    if ok then
      on_done(true)
      return
    end
    if attempt >= 30 then
      on_done(false, "Timed out waiting for latex_sympy server")
      return
    end
    vim.defer_fn(function()
      wait_for_server_ready(on_done, attempt + 1)
    end, 100)
  end)
end

local function maybe_trigger_auto_install()
  if not current_config.auto_install or auto_install_triggered then
    return
  end
  auto_install_triggered = true
  system_async(current_config.python, {
    "-m",
    "pip",
    "install",
    "--upgrade",
    "latex2sympy2",
    "Flask",
  }, function(_, _, _) end)
end

local function start_server_process()
  if is_server_running() then
    return true
  end

  local root = detect_plugin_dir()
  local server_path = vim.fn.fnamemodify(root .. "/server.py", ":p")
  if not vim.loop.fs_stat(server_path) then
    return false, "server.py not found at " .. server_path
  end

  maybe_trigger_auto_install()
  last_server_stderr = ""

  server_job_id = vim.fn.jobstart({ current_config.python, server_path }, {
    cwd = root,
    env = {
      LATEX_SYMPY_PORT = tostring(current_config.port),
      LATEX_SYMPY_ENABLE_PYTHON = current_config.enable_python_eval and "1" or "0",
    },
    on_stderr = function(_, data)
      if not data then
        return
      end
      for _, line in ipairs(data) do
        if line and line ~= "" then
          last_server_stderr = line
        end
      end
    end,
    on_exit = function(_, code)
      local stopped_intentionally = intentional_stop
      intentional_stop = false
      server_job_id = nil
      server_ready = false
      server_starting = false

      if stopped_intentionally then
        return
      end

      local message = "Python server exited"
      if code and code ~= 0 then
        message = string.format("Python server exited (code %s)", tostring(code))
      end
      if last_server_stderr ~= "" then
        message = message .. ": " .. last_server_stderr
      end
      LOG.error(message)
      flush_server_callbacks(false, message)
    end,
  })

  if server_job_id <= 0 then
    local err = "failed to start Python server"
    server_job_id = nil
    return false, err
  end

  return true
end

local function ensure_server_running(callback)
  if callback then
    table.insert(pending_server_callbacks, callback)
  end

  if is_server_running() and server_ready then
    flush_server_callbacks(true)
    return
  end

  if server_starting then
    return
  end

  server_starting = true
  local ok, err = start_server_process()
  if not ok then
    server_starting = false
    flush_server_callbacks(false, err)
    return
  end

  wait_for_server_ready(function(ready_ok, ready_err)
    server_starting = false
    server_ready = ready_ok
    if not ready_ok then
      M.stop_server({ silent = true, skip_flush = true })
    end
    flush_server_callbacks(ready_ok, ready_err)
  end)
end

local function http_request(method, path, body_data, on_success, on_error)
  local url = string.format("http://127.0.0.1:%d%s", current_config.port, path)
  local args = { "-sS", "-X", method, url }

  if method == "POST" then
    local payload = json_encode({ data = body_data })
    table.insert(args, "-H")
    table.insert(args, "Content-Type: application/json")
    table.insert(args, "-d")
    table.insert(args, payload)
  end

  system_async("curl", args, function(code, stdout, stderr)
    if code ~= 0 then
      if on_error then
        vim.schedule(function()
          if stderr and vim.trim(stderr) ~= "" then
            on_error(stderr)
          else
            on_error("HTTP error, code " .. tostring(code))
          end
        end)
      end
      return
    end

    local ok, result = pcall(json_decode, stdout)
    if not ok or type(result) ~= "table" then
      if on_error then
        vim.schedule(function()
          on_error("Invalid JSON from server")
        end)
      end
      return
    end

    if result.error and result.error ~= "" then
      if on_error then
        vim.schedule(function()
          on_error(result.error)
        end)
      end
      return
    end

    if on_success then
      local payload = (result.data ~= nil) and result.data or result
      vim.schedule(function()
        on_success(payload)
      end)
    end
  end)
end

local function post(path, data, on_success, on_error)
  http_request("POST", path, data, on_success, on_error)
end

local function get(path, on_success, on_error)
  http_request("GET", path, nil, on_success, on_error)
end

local function get_visual_range_or_lines(opts)
  local buf = 0
  local start_row, start_col, end_row, end_col
  local using_marks = false

  do
    local m1 = vim.api.nvim_buf_get_mark(buf, "<")
    local m2 = vim.api.nvim_buf_get_mark(buf, ">")
    if m1 and m2 and (m1[1] ~= 0 or m2[1] ~= 0) then
      using_marks = true
      start_row, start_col = m1[1] - 1, m1[2]
      end_row, end_col = m2[1] - 1, m2[2]
    end
  end

  if not using_marks and opts and opts.range and opts.range > 0 then
    start_row = (opts.line1 or 1) - 1
    end_row = (opts.line2 or (opts.line1 or 1)) - 1
    start_col = 0
    local last_line = vim.api.nvim_buf_get_lines(buf, end_row, end_row + 1, false)[1] or ""
    end_col = #last_line
  end

  if start_row == nil then
    return nil, "No selection detected. Use visual selection or provide a range."
  end

  local line_count = vim.api.nvim_buf_line_count(buf)
  start_row = math.max(0, math.min(start_row or 0, line_count - 1))
  end_row = math.max(0, math.min(end_row or 0, line_count - 1))

  local sline = vim.api.nvim_buf_get_lines(buf, start_row, start_row + 1, false)[1] or ""
  local eline = vim.api.nvim_buf_get_lines(buf, end_row, end_row + 1, false)[1] or ""

  start_col = math.max(0, math.min(start_col or 0, #sline))
  end_col = math.max(0, math.min(end_col or 0, #eline))

  if start_row > end_row or (start_row == end_row and start_col > end_col) then
    start_row, start_col, end_row, end_col = end_row, end_col, start_row, start_col
  end

  local lines = vim.api.nvim_buf_get_text(buf, start_row, start_col, end_row, end_col, {})
  local start_mark = vim.api.nvim_buf_set_extmark(buf, ns_id, start_row, start_col, { right_gravity = false })
  local end_mark = vim.api.nvim_buf_set_extmark(buf, ns_id, end_row, end_col, { right_gravity = true })

  return {
    buf = buf,
    start_row = start_row,
    start_col = start_col,
    end_row = end_row,
    end_col = end_col,
    start_mark = start_mark,
    end_mark = end_mark,
    text = table.concat(lines, "\n"),
  }
end

local function cleanup_range_marks(range)
  if range.start_mark then
    pcall(vim.api.nvim_buf_del_extmark, range.buf, ns_id, range.start_mark)
  end
  if range.end_mark then
    pcall(vim.api.nvim_buf_del_extmark, range.buf, ns_id, range.end_mark)
  end
end

local function resolve_current_range(range)
  local sr, sc = range.start_row, range.start_col
  local er, ec = range.end_row, range.end_col

  if range.start_mark then
    local pos = vim.api.nvim_buf_get_extmark_by_id(range.buf, ns_id, range.start_mark, {})
    if pos and #pos == 2 then
      sr, sc = pos[1], pos[2]
    end
  end

  if range.end_mark then
    local pos = vim.api.nvim_buf_get_extmark_by_id(range.buf, ns_id, range.end_mark, {})
    if pos and #pos == 2 then
      er, ec = pos[1], pos[2]
    end
  end

  local line_count = vim.api.nvim_buf_line_count(range.buf)
  sr = math.max(0, math.min(sr or 0, line_count - 1))
  er = math.max(0, math.min(er or 0, line_count - 1))

  local sline = vim.api.nvim_buf_get_lines(range.buf, sr, sr + 1, false)[1] or ""
  local eline = vim.api.nvim_buf_get_lines(range.buf, er, er + 1, false)[1] or ""

  sc = math.max(0, math.min(sc or 0, #sline))
  ec = math.max(0, math.min(ec or 0, #eline))

  if sr > er or (sr == er and sc > ec) then
    sr, sc, er, ec = er, ec, sr, sc
  end

  return sr, sc, er, ec
end

local function replace_range(range, new_text)
  local replacement = {}
  for s in tostring(new_text):gmatch("([^\n]*)\n?") do
    table.insert(replacement, s)
  end

  local sr, sc, er, ec = resolve_current_range(range)
  vim.api.nvim_buf_set_text(range.buf, sr, sc, er, ec, replacement)
  cleanup_range_marks(range)
end

local function insert_after_range(range, insert_text)
  local _, _, er, ec = resolve_current_range(range)
  vim.api.nvim_buf_set_text(range.buf, er, ec, er, ec, { insert_text })
  cleanup_range_marks(range)
end

local function run_with_server(callback)
  ensure_server_running(function(ok, err)
    if not ok then
      LOG.error(err or "Failed to start latex_sympy server")
      return
    end
    callback()
  end)
end

local TRANSFORM_ACTIONS = {
  equal = {
    path = "/latex",
    apply = function(range, data)
      insert_after_range(range, " = " .. tostring(data))
    end,
  },
  replace = {
    path = "/latex",
    apply = function(range, data)
      replace_range(range, tostring(data))
    end,
  },
  numerical = {
    path = "/numerical",
    apply = function(range, data)
      replace_range(range, tostring(data))
    end,
  },
  factor = {
    path = "/factor",
    apply = function(range, data)
      replace_range(range, tostring(data))
    end,
  },
  expand = {
    path = "/expand",
    apply = function(range, data)
      replace_range(range, tostring(data))
    end,
  },
  matrix_rref = {
    path = "/matrix-raw-echelon-form",
    apply = function(range, data)
      insert_after_range(range, " \\\\to " .. tostring(data))
    end,
  },
}

local function run_transform(action_name, opts)
  local action = TRANSFORM_ACTIONS[action_name]
  if not action then
    LOG.error("Unknown action: " .. tostring(action_name))
    return
  end

  local range, err = get_visual_range_or_lines(opts)
  if not range then
    LOG.error(err)
    return
  end

  run_with_server(function()
    post(action.path, range.text, function(data)
      action.apply(range, data)
    end, function(req_err)
      LOG.error(req_err)
      cleanup_range_marks(range)
    end)
  end)
end

local function create_commands()
  if commands_registered then
    return
  end

  local names = {
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
  for _, name in ipairs(names) do
    pcall(vim.api.nvim_del_user_command, name)
  end

  vim.api.nvim_create_user_command("LatexSympyEqual", function(opts)
    M.equal(opts)
  end, { range = true, desc = "Append = <result> for selected LaTeX" })

  vim.api.nvim_create_user_command("LatexSympyReplace", function(opts)
    M.replace(opts)
  end, { range = true, desc = "Replace selection with LaTeX result" })

  vim.api.nvim_create_user_command("LatexSympyNumerical", function(opts)
    M.numerical(opts)
  end, { range = true, desc = "Replace selection with numerical result" })

  vim.api.nvim_create_user_command("LatexSympyFactor", function(opts)
    M.factor(opts)
  end, { range = true, desc = "Replace selection with factored expression" })

  vim.api.nvim_create_user_command("LatexSympyExpand", function(opts)
    M.expand(opts)
  end, { range = true, desc = "Replace selection with expanded expression" })

  vim.api.nvim_create_user_command("LatexSympyMatrixRREF", function(opts)
    M.matrix_rref(opts)
  end, { range = true, desc = "Append \\to <rref> for matrix selection" })

  vim.api.nvim_create_user_command("LatexSympyVariances", function()
    M.variances()
  end, { desc = "Insert current variances mapping at cursor" })

  vim.api.nvim_create_user_command("LatexSympyReset", function()
    M.reset()
  end, { desc = "Reset current variances" })

  vim.api.nvim_create_user_command("LatexSympyToggleComplex", function()
    M.toggle_complex()
  end, { desc = "Toggle complex numbers for variances" })

  vim.api.nvim_create_user_command("LatexSympyPython", function(opts)
    M.python(opts)
  end, { range = true, desc = "Evaluate Python snippet and append = <result>" })

  vim.api.nvim_create_user_command("LatexSympyStatus", function()
    M.status()
  end, { desc = "Show latex_sympy server/config status" })

  vim.api.nvim_create_user_command("LatexSympyRestart", function()
    M.restart_server()
  end, { desc = "Restart the latex_sympy Python server" })

  vim.api.nvim_create_user_command("LatexSympyStart", function()
    M.start_server()
  end, { desc = "Start the latex_sympy Python server" })

  vim.api.nvim_create_user_command("LatexSympyStop", function()
    M.stop_server()
  end, { desc = "Stop the latex_sympy Python server" })

  commands_registered = true
end

local function maybe_notify_startup()
  if not current_config.notify_startup then
    return
  end
  if current_config.startup_notify_once and startup_notified then
    return
  end
  LOG.info("active")
  startup_notified = true
end

local function normalized_mode(mode)
  if mode == "on_activate" then
    return "on_activate"
  end
  return "on_demand"
end

function M.setup(opts)
  opts = opts or {}

  local next_config = clone(current_config)
  if not configured then
    next_config = clone(DEFAULT_CONFIG)
  end

  next_config.python = opts.python or next_config.python
  if opts.auto_install ~= nil then
    next_config.auto_install = opts.auto_install
  end
  next_config.port = opts.port or next_config.port
  if opts.enable_python_eval ~= nil then
    next_config.enable_python_eval = opts.enable_python_eval
  end
  if opts.notify_startup ~= nil then
    next_config.notify_startup = opts.notify_startup
  end
  if opts.startup_notify_once ~= nil then
    next_config.startup_notify_once = opts.startup_notify_once
  end
  if opts.server_start_mode ~= nil then
    next_config.server_start_mode = normalized_mode(opts.server_start_mode)
  end

  local needs_restart = is_server_running() and (
    next_config.python ~= current_config.python or
    next_config.port ~= current_config.port or
    next_config.enable_python_eval ~= current_config.enable_python_eval
  )

  current_config = next_config
  configured = true

  if needs_restart then
    M.restart_server()
  elseif activated_for_tex and current_config.server_start_mode == "on_activate" and not is_server_running() then
    run_with_server(function() end)
  end
end

function M.get_config()
  return clone(current_config)
end

function M.activate_for_tex_buffer(_)
  if not configured then
    M.setup({})
  end

  activated_for_tex = true
  create_commands()
  maybe_notify_startup()

  if current_config.server_start_mode == "on_activate" then
    run_with_server(function() end)
  end
end

function M.start_server()
  run_with_server(function()
    LOG.info("server started")
  end)
end

function M.stop_server(opts)
  local silent = type(opts) == "table" and opts.silent
  local skip_flush = type(opts) == "table" and opts.skip_flush

  if is_server_running() then
    intentional_stop = true
    vim.fn.jobstop(server_job_id)
    server_job_id = nil
  end

  server_ready = false
  server_starting = false

  if not skip_flush then
    flush_server_callbacks(false, "Server stopped")
  end

  if not silent then
    LOG.info("server stopped")
  end
end

function M.restart_server()
  M.stop_server({ silent = true })
  run_with_server(function()
    LOG.info("server restarted")
  end)
end

function M.equal(opts)
  run_transform("equal", opts)
end

function M.replace(opts)
  run_transform("replace", opts)
end

function M.numerical(opts)
  run_transform("numerical", opts)
end

function M.factor(opts)
  run_transform("factor", opts)
end

function M.expand(opts)
  run_transform("expand", opts)
end

function M.matrix_rref(opts)
  run_transform("matrix_rref", opts)
end

function M.variances()
  run_with_server(function()
    get("/variances", function(map)
      local values = map or {}
      local keys = {}
      for k, _ in pairs(values) do
        table.insert(keys, tostring(k))
      end
      table.sort(keys)

      local lines = { "" }
      for _, key in ipairs(keys) do
        table.insert(lines, string.format("%s = %s", key, tostring(values[key])))
      end

      local cursor = vim.api.nvim_win_get_cursor(0)
      local row = cursor[1] - 1
      local col = cursor[2]
      vim.api.nvim_buf_set_text(0, row, col, row, col, lines)
    end, function(err)
      LOG.error(err)
    end)
  end)
end

function M.reset()
  run_with_server(function()
    get("/reset", function(_)
      LOG.info("variances reset")
    end, function(err)
      LOG.error(err)
    end)
  end)
end

function M.toggle_complex()
  run_with_server(function()
    get("/complex", function(res)
      local enabled = res and res.value
      LOG.info("complex numbers: " .. (enabled and "on" or "off"))
    end, function(err)
      LOG.error(err)
    end)
  end)
end

function M.python(opts)
  if not current_config.enable_python_eval then
    LOG.error("LatexSympyPython is disabled. Enable with require('latex_sympy').setup({ enable_python_eval = true })")
    return
  end

  local range, err = get_visual_range_or_lines(opts)
  if not range then
    LOG.error(err)
    return
  end

  run_with_server(function()
    post("/python", range.text, function(data)
      insert_after_range(range, " = " .. tostring(data))
    end, function(req_err)
      LOG.error(req_err)
      cleanup_range_marks(range)
    end)
  end)
end

function M.status()
  local lines = {
    string.format("Activated for tex: %s", tostring(activated_for_tex)),
    string.format("Server: %s", is_server_running() and "Running" or "Stopped"),
    string.format("Port: %s", tostring(current_config.port)),
    string.format("Python: %s", tostring(current_config.python)),
    string.format("Auto install: %s", tostring(current_config.auto_install)),
    string.format("Server start mode: %s", tostring(current_config.server_start_mode)),
    string.format("Python eval enabled: %s", tostring(current_config.enable_python_eval)),
  }
  LOG.info(table.concat(lines, "\n"))
end

-- Test helpers
function M._reset_state_for_tests()
  M.stop_server({ silent = true })

  local all_commands = {
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
  for _, name in ipairs(all_commands) do
    pcall(vim.api.nvim_del_user_command, name)
  end

  plugin_dir = nil
  intentional_stop = false
  server_ready = false
  server_starting = false
  pending_server_callbacks = {}
  last_server_stderr = ""
  auto_install_triggered = false

  current_config = clone(DEFAULT_CONFIG)
  configured = false
  activated_for_tex = false
  commands_registered = false
  startup_notified = false
end

function M._is_activated_for_tests()
  return activated_for_tex
end

function M._is_server_running_for_tests()
  return is_server_running()
end

function M._startup_notified_for_tests()
  return startup_notified
end

return M
