-- Test heatmap frequency computation

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    print("PASS: " .. name)
  else
    print("FAIL: " .. name .. " - " .. tostring(err))
    vim.cmd("cquit 1")
  end
end

-- Create a temporary git repo for testing
local tmp_dir = vim.fn.tempname()
vim.fn.mkdir(tmp_dir, "p")

local function run(cmd)
  return vim.fn.system("cd " .. tmp_dir .. " && " .. cmd)
end

-- Set up test repo
run("git init")
run("git config user.email 'test@test.com'")
run("git config user.name 'Test'")

-- Create a file with many lines to get distinct hunks
local initial = {}
for i = 1, 20 do
  initial[i] = "line" .. i
end
vim.fn.writefile(initial, tmp_dir .. "/test.lua")
run("git add test.lua")
run('git commit -m "initial commit"')

-- Modify lines near the top (line 2) - this creates a hunk only around lines 1-5
local v2 = vim.fn.copy(initial)
v2[2] = "changed2"
vim.fn.writefile(v2, tmp_dir .. "/test.lua")
run("git add test.lua")
run('git commit -m "modify line 2"')

-- Modify line 2 again
local v3 = vim.fn.copy(v2)
v3[2] = "changed2again"
vim.fn.writefile(v3, tmp_dir .. "/test.lua")
run("git add test.lua")
run('git commit -m "modify line 2 again"')

-- Save original dir and cd to temp
local original_dir = vim.fn.getcwd()
vim.cmd("cd " .. tmp_dir)

-- Load heatmap module
local heatmap = require("wayback.heatmap")

test("compute_frequency returns table with integer keys", function()
  local freq = heatmap.compute_frequency("test.lua", 20)
  assert(type(freq) == "table", "should return a table")
  assert(freq[1] ~= nil, "should have key 1")
  assert(freq[20] ~= nil, "should have key 20")
end)

test("frequently changed lines have higher frequency", function()
  local freq = heatmap.compute_frequency("test.lua", 20)
  -- Line 2 is near the top and was changed in 2 additional commits
  -- Line 18 is far from any changes and should only be in the initial commit hunk
  assert(
    freq[2] > freq[18],
    "line 2 (freq=" .. freq[2] .. ") should be higher than line 18 (freq=" .. freq[18] .. ")"
  )
end)

test("all lines have at least initial commit frequency", function()
  local freq = heatmap.compute_frequency("test.lua", 20)
  -- The initial commit creates all 20 lines so all should have freq >= 1
  for i = 1, 20 do
    assert(freq[i] >= 1, "line " .. i .. " should have freq >= 1, got " .. freq[i])
  end
end)

-- Cleanup
vim.cmd("cd " .. original_dir)
vim.fn.delete(tmp_dir, "rf")

print("\nAll heatmap tests passed!")
vim.cmd("qall!")
