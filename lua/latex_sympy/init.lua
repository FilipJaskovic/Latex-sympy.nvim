local M = {}

-- Internal state
local server_job_id = nil
local server_port = 7395
local python_path = "python3"
local auto_install = true
local plugin_dir = nil
local current_config = {
  python = python_path,
  auto_install = auto_install,
  port = server_port,
}

-- Minimal logging wrapper
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
  -- src points to this file; go up to the repo root that contains server.py
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
  local job_id = vim.fn.jobstart(vim.list_extend({ cmd }, args or {}), {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then table.insert(output, table.concat(data, "\n")) end
    end,
    on_stderr = function(_, data)
      if data then table.insert(errout, table.concat(data, "\n")) end
    end,
    on_exit = function(_, code)
      on_exit(code or 0, table.concat(output, "\n"), table.concat(errout, "\n"))
    end,
  })
  return job_id
end

local function http_request(method, path, body_tbl, on_success, on_error)
  local url = string.format("http://127.0.0.1:%d%s", server_port, path)
  local args = { "-sS", "-X", method, url }
  if method == "POST" then
    local payload = json_encode({ data = body_tbl })
    table.insert(args, "-H")
    table.insert(args, "Content-Type: application/json")
    table.insert(args, "-d")
    table.insert(args, payload)
  end
  system_async("curl", args, function(code, stdout, stderr)
    if code ~= 0 or (stderr and #vim.trim(stderr) > 0) then
      if on_error then on_error(stderr ~= "" and stderr or ("HTTP error, code " .. tostring(code))) end
      return
    end
    local ok, result = pcall(json_decode, stdout)
    if not ok then
      if on_error then on_error("Invalid JSON from server") end
      return
    end
    if result and result.error and result.error ~= "" then
      if on_error then on_error(result.error) end
      return
    end
    if on_success then
      if result and result.data ~= nil then
        on_success(result.data)
      else
        on_success(result)
      end
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
  local lines = vim.api.nvim_buf_get_text(buf, start_row, start_col, end_row, end_col, {})
  return {
    buf = buf,
    start_row = start_row,
    start_col = start_col,
    end_row = end_row,
    end_col = end_col,
    text = table.concat(lines, "\n"),
  }
end

local function replace_range(range, new_text)
  local replacement = {}
  for s in tostring(new_text):gmatch("([^\n]*)\n?") do
    table.insert(replacement, s)
  end
  vim.api.nvim_buf_set_text(range.buf, range.start_row, range.start_col, range.end_row, range.end_col, replacement)
end

local function insert_after_range(range, insert_text)
  local line = vim.api.nvim_buf_get_lines(range.buf, range.end_row, range.end_row + 1, false)[1] or ""
  vim.api.nvim_buf_set_text(range.buf, range.end_row, range.end_col, range.end_row, range.end_col, { insert_text })
end

-- Public API

function M.setup(opts)
  opts = opts or {}
  local new_python = opts.python or python_path
  local new_auto_install = opts.auto_install ~= false
  local new_port = opts.port or server_port

  local must_restart = false
  if server_job_id and server_job_id > 0 then
    must_restart = (new_python ~= python_path) or (new_port ~= server_port)
  end

  python_path = new_python
  auto_install = new_auto_install
  server_port = new_port

  current_config = {
    python = python_path,
    auto_install = auto_install,
    port = server_port,
  }

  if auto_install then
    system_async(python_path, { "-m", "pip", "install", "--upgrade", "latex2sympy2", "Flask" }, function(_, _, _) end)
  end

  if must_restart then
    M.restart_server()
  else
    M.start_server()
  end
end

function M.get_config()
  return {
    python = python_path,
    auto_install = auto_install,
    port = server_port,
  }
end

function M.start_server()
  if server_job_id and server_job_id > 0 then
    return
  end
  local root = detect_plugin_dir()
  local server_path = vim.fn.fnamemodify(root .. "/server.py", ":p")
  if not vim.loop.fs_stat(server_path) then
    LOG.error("server.py not found at " .. server_path)
    return
  end
  server_job_id = vim.fn.jobstart({ python_path, server_path }, {
    cwd = root,
    env = { LATEX_SYMPY_PORT = tostring(server_port) },
    on_stderr = function(_, data)
      if data and #data > 0 then
        vim.schedule(function()
          LOG.warn("server stderr: " .. table.concat(data, "\n"))
        end)
      end
    end,
    on_exit = function(_, code)
      server_job_id = nil
      if code ~= 0 then
        vim.schedule(function()
          LOG.error("Python server exited (code " .. tostring(code) .. ")")
        end)
      end
    end,
  })
  if server_job_id <= 0 then
    LOG.error("failed to start Python server")
  end
end

function M.stop_server()
  if server_job_id and server_job_id > 0 then
    vim.fn.jobstop(server_job_id)
    server_job_id = nil
  end
end

function M.restart_server()
  M.stop_server()
  vim.defer_fn(function()
    M.start_server()
    LOG.info("Server restarted")
  end, 50)
end

-- Commands

function M.equal(opts)
  local rng, err = get_visual_range_or_lines(opts)
  if not rng then
    LOG.error(err)
    return
  end
  post("/latex", rng.text, function(data)
    insert_after_range(rng, " = " .. tostring(data))
  end, function(e)
    LOG.error(e)
  end)
end

function M.replace(opts)
  local rng, err = get_visual_range_or_lines(opts)
  if not rng then
    LOG.error(err)
    return
  end
  post("/latex", rng.text, function(data)
    replace_range(rng, tostring(data))
  end, function(e)
    LOG.error(e)
  end)
end

function M.numerical(opts)
  local rng, err = get_visual_range_or_lines(opts)
  if not rng then
    LOG.error(err)
    return
  end
  post("/numerical", rng.text, function(data)
    replace_range(rng, tostring(data))
  end, function(e)
    LOG.error(e)
  end)
end

function M.factor(opts)
  local rng, err = get_visual_range_or_lines(opts)
  if not rng then
    LOG.error(err)
    return
  end
  post("/factor", rng.text, function(data)
    replace_range(rng, tostring(data))
  end, function(e)
    LOG.error(e)
  end)
end

function M.expand(opts)
  local rng, err = get_visual_range_or_lines(opts)
  if not rng then
    LOG.error(err)
    return
  end
  post("/expand", rng.text, function(data)
    replace_range(rng, tostring(data))
  end, function(e)
    LOG.error(e)
  end)
end

function M.matrix_rref(opts)
  local rng, err = get_visual_range_or_lines(opts)
  if not rng then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
  post("/matrix-raw-echelon-form", rng.text, function(data)
    insert_after_range(rng, " \\\\to " .. tostring(data))
  end, function(e)
    LOG.error(e)
  end)
end

function M.variances()
  get("/variances", function(map)
    local lines = {}
    for k, v in pairs(map) do
      table.insert(lines, string.format("%s = %s", k, v))
    end
    local text = "\n" .. table.concat(lines, "\n")
    local pos = vim.api.nvim_win_get_cursor(0)
    local row = pos[1] - 1
    local col = pos[2]
    vim.api.nvim_buf_set_text(0, row, col, row, col, { text })
  end, function(e)
    vim.notify(e, vim.log.levels.ERROR)
  end)
end

function M.reset()
  get("/reset", function(_)
    LOG.info("Reset current variances")
  end, function(e)
    LOG.error(e)
  end)
end

function M.toggle_complex()
  get("/complex", function(res)
    local value = (res and res.value) and "On" or "Off"
    LOG.info("Toggle Complex Number to " .. value)
  end, function(e)
    LOG.error(e)
  end)
end

function M.python(opts)
  local rng, err = get_visual_range_or_lines(opts)
  if not rng then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
  http_request("POST", "/python", rng.text, function(data)
    insert_after_range(rng, " = " .. tostring(data))
  end, function(e)
    LOG.error(e)
  end)
end

-- Show current status/config
function M.status()
  local running = server_job_id and server_job_id > 0
  local lines = {
    string.format("Server: %s", running and "Running" or "Stopped"),
    string.format("Port: %s", tostring(server_port)),
    string.format("Python: %s", tostring(python_path)),
    string.format("Auto install: %s", tostring(auto_install)),
  }
  LOG.info(table.concat(lines, "\n"))
end

return M


