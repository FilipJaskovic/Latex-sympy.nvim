local function fail(message)
  io.stderr:write("latex_sympy parser: " .. tostring(message) .. "\n")
  os.exit(1)
end

local function assert_true(condition, message)
  if not condition then
    fail(message)
  end
end

local function assert_same(expected, actual, label)
  local equal
  if vim.deep_equal then
    equal = vim.deep_equal(expected, actual)
  else
    local function deep_equal(a, b)
      if type(a) ~= type(b) then
        return false
      end
      if type(a) ~= "table" then
        return a == b
      end
      for key, value in pairs(a) do
        if not deep_equal(value, b[key]) then
          return false
        end
      end
      for key, _ in pairs(b) do
        if a[key] == nil then
          return false
        end
      end
      return true
    end
    equal = deep_equal(expected, actual)
  end

  if not equal then
    fail(string.format("%s mismatch", label))
  end
end

local function assert_parse_ok(mod, op, args, expected, label)
  local parsed, err = mod._parse_operation_args_for_tests(op, args)
  assert_true(err == nil, string.format("%s unexpected err: %s", label, tostring(err)))
  assert_same(expected, parsed, label)
end

local function assert_parse_err(mod, op, args, label)
  local _, err = mod._parse_operation_args_for_tests(op, args)
  assert_true(type(err) == "string" and err ~= "", label .. " expected parse error")
end

local function run_parser_checks()
  package.loaded["latex_sympy"] = nil
  local ok_mod, mod_or_err = pcall(require, "latex_sympy")
  assert_true(ok_mod, mod_or_err)
  local mod = mod_or_err
  mod._reset_state_for_tests()

  assert_parse_ok(mod, "solveset", { "R" }, { domain = "R" }, "solveset-domain-only")
  assert_parse_ok(mod, "solveset", { "x", "N" }, { var = "x", domain = "N" }, "solveset-var-domain")
  assert_parse_ok(mod, "linsolve", { "x", "y" }, { vars = { "x", "y" } }, "linsolve-vars")
  assert_parse_ok(mod, "nonlinsolve", { "x", "y" }, { vars = { "x", "y" } }, "nonlinsolve-vars")
  assert_parse_ok(mod, "rsolve", { "a(n)" }, { func = "a(n)" }, "rsolve-func")
  assert_parse_ok(mod, "diophantine", { "x", "y" }, { vars = { "x", "y" } }, "diophantine-vars")
  assert_parse_ok(mod, "charpoly", { "t" }, { var = "t" }, "charpoly-var")
  assert_parse_ok(mod, "primerange", { "10", "40" }, { start = 10, stop = 40 }, "primerange-bounds")
  assert_parse_ok(mod, "groebner", { "x", "y", "lex" }, { vars = { "x", "y" }, order = "lex" }, "groebner")
  assert_parse_ok(mod, "resultant", { "x" }, { var = "x" }, "resultant")
  assert_parse_ok(mod, "subsets", { "2" }, { k = 2 }, "subsets")
  assert_parse_ok(mod, "logic_simplify", { "cnf" }, { form = "cnf" }, "logic-simplify")
  assert_parse_ok(mod, "units", { "simplify" }, { action = "simplify" }, "units-simplify")
  assert_parse_ok(mod, "dist", { "normal", "X", "0", "1" }, { kind = "normal", name = "X", args = { "0", "1" } }, "dist")

  assert_parse_ok(mod, "eigenvects", {}, {}, "eigenvects-empty")
  assert_parse_ok(mod, "nullspace", {}, {}, "nullspace-empty")
  assert_parse_ok(mod, "lu", {}, {}, "lu-empty")
  assert_parse_ok(mod, "qr", {}, {}, "qr-empty")
  assert_parse_ok(mod, "mat_solve", {}, {}, "mat_solve-empty")
  assert_parse_ok(mod, "isprime", {}, {}, "isprime-empty")
  assert_parse_ok(mod, "factorint", {}, {}, "factorint-empty")

  assert_parse_err(mod, "solveset", { "x", "Q" }, "solveset-invalid-domain")
  assert_parse_err(mod, "rsolve", { "a(n)", "extra" }, "rsolve-invalid-arity")
  assert_parse_err(mod, "charpoly", { "x", "y" }, "charpoly-invalid-arity")
  assert_parse_err(mod, "primerange", { "10" }, "primerange-invalid-arity")
  assert_parse_err(mod, "primerange", { "a", "40" }, "primerange-invalid-type")
  assert_parse_err(mod, "isprime", { "x" }, "isprime-extra-args")
  assert_parse_err(mod, "factorint", { "x" }, "factorint-extra-args")
  assert_parse_err(mod, "mat_solve", { "x" }, "mat_solve-extra-args")
  assert_parse_err(mod, "symbol", { "x", "bad=true" }, "symbol-invalid-assumption")
  assert_parse_err(mod, "dist", { "unknown", "X" }, "dist-invalid-kind")
  assert_parse_err(mod, "units", { "convert" }, "units-missing-target")

  local completion = mod._completion_for_ops_for_tests("")
  local required_ops = {
    "solveset",
    "linsolve",
    "nonlinsolve",
    "rsolve",
    "diophantine",
    "eigenvects",
    "nullspace",
    "charpoly",
    "lu",
    "qr",
    "mat_solve",
    "isprime",
    "factorint",
    "primerange",
    "groebner",
    "subsets",
    "logic_simplify",
    "units",
    "dist",
    "density",
  }
  for _, value in ipairs(required_ops) do
    assert_true(vim.tbl_contains(completion, value), "completion missing " .. value)
  end

  print("latex_sympy parser: ok")
end

local ok, err = pcall(run_parser_checks)
if not ok then
  fail(err)
end

vim.cmd("qa!")
