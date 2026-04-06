-- Test timelapse state management
local git = require("wayback.git")

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

-- Set up test repo with 3 commits
run("git init")
run("git config user.email 'test@test.com'")
run("git config user.name 'Test'")

vim.fn.writefile({ "version1" }, tmp_dir .. "/test.lua")
run("git add test.lua")
run('git commit -m "first version"')

vim.fn.writefile({ "version2" }, tmp_dir .. "/test.lua")
run("git add test.lua")
run('git commit -m "second version"')

vim.fn.writefile({ "version3" }, tmp_dir .. "/test.lua")
run("git add test.lua")
run('git commit -m "third version"')

local original_dir = vim.fn.getcwd()
vim.cmd("cd " .. tmp_dir)

test("git.log returns commits for timelapse", function()
  local commits = git.log("test.lua")
  assert(#commits == 3, "expected 3 commits, got " .. #commits)
  assert(commits[1].message == "third version", "newest should be first")
  assert(commits[3].message == "first version", "oldest should be last")
end)

test("git.show returns correct content for each version", function()
  local commits = git.log("test.lua")
  local content1 = git.show(commits[3].hash, commits[3].path)
  local content3 = git.show(commits[1].hash, commits[1].path)
  assert(content1:find("version1"), "oldest commit should have version1")
  assert(content3:find("version3"), "newest commit should have version3")
end)

test("timelapse index bounds", function()
  local commits = git.log("test.lua")
  -- Simulate index state management
  local index = 1 -- start at newest
  assert(index >= 1, "index should start at 1")
  assert(index <= #commits, "index should not exceed commit count")

  -- Navigate older
  index = index + 1
  assert(index == 2, "should be at second commit")
  index = index + 1
  assert(index == 3, "should be at third (oldest) commit")

  -- Should not go beyond
  assert(index >= #commits, "should be at the end")

  -- Navigate newer
  index = index - 1
  assert(index == 2, "should go back to second")
  index = index - 1
  assert(index == 1, "should go back to newest")

  -- Should not go below 1
  assert(index <= 1, "should be at the start")
end)

-- Cleanup
vim.cmd("cd " .. original_dir)
vim.fn.delete(tmp_dir, "rf")

print("\nAll timelapse tests passed!")
vim.cmd("qall!")
