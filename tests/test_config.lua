-- Test config module
local config = require("wayback.config")

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    print("PASS: " .. name)
  else
    print("FAIL: " .. name .. " - " .. tostring(err))
    vim.cmd("cquit 1")
  end
end

-- Reset config before each test
local function reset()
  config.values = {
    picker = "auto",
    mappings = { i = {}, n = {} },
    browser_command = nil,
    forge = nil,
  }
end

test("defaults are correct", function()
  reset()
  assert(config.values.picker == "auto", "picker should default to auto")
  assert(config.values.browser_command == nil, "browser_command should default to nil")
  assert(config.values.forge == nil, "forge should default to nil")
  assert(type(config.values.mappings) == "table", "mappings should be a table")
  assert(type(config.values.mappings.i) == "table", "mappings.i should be a table")
  assert(type(config.values.mappings.n) == "table", "mappings.n should be a table")
end)

test("setup overrides picker", function()
  reset()
  config.setup({ picker = "telescope" })
  assert(config.values.picker == "telescope", "picker should be telescope")
end)

test("setup overrides forge", function()
  reset()
  config.setup({ forge = "gitlab" })
  assert(config.values.forge == "gitlab", "forge should be gitlab")
end)

test("setup deep merges mappings", function()
  reset()
  config.setup({ mappings = { i = { ["<C-a>"] = "test" } } })
  assert(config.values.mappings.i["<C-a>"] == "test", "custom mapping should be set")
  assert(type(config.values.mappings.n) == "table", "n mappings should be preserved")
end)

test("setup preserves unset keys", function()
  reset()
  config.setup({ picker = "fzf_lua" })
  assert(config.values.browser_command == nil, "browser_command should remain nil")
  assert(config.values.forge == nil, "forge should remain nil")
end)

test("setup with empty opts is safe", function()
  reset()
  config.setup({})
  assert(config.values.picker == "auto", "picker should remain auto")
end)

test("setup with nil opts is safe", function()
  reset()
  config.setup(nil)
  assert(config.values.picker == "auto", "picker should remain auto")
end)

print("\nAll config tests passed!")
vim.cmd("qall!")
