-- Test git module with a temporary git repo
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

-- Set up test repo
run("git init")
run("git config user.email 'test@test.com'")
run("git config user.name 'Test'")

-- Create a file and commit
vim.fn.writefile({ "line1", "line2", "line3" }, tmp_dir .. "/test.lua")
run("git add test.lua")
run('git commit -m "initial commit"')

-- Modify the file and commit
vim.fn.writefile({ "line1", "modified", "line3" }, tmp_dir .. "/test.lua")
run("git add test.lua")
run('git commit -m "modify test file"')

-- Rename the file and commit
run("git mv test.lua renamed.lua")
run('git commit -m "rename test to renamed"')

-- Save original dir and cd to temp
local original_dir = vim.fn.getcwd()
vim.cmd("cd " .. tmp_dir)

test("is_git_directory returns true in git repo", function()
  assert(git.is_git_directory() == true)
end)

test("is_git_directory returns false outside git repo", function()
  local non_git = vim.fn.tempname()
  vim.fn.mkdir(non_git, "p")
  vim.cmd("cd " .. non_git)
  assert(git.is_git_directory() == false)
  vim.cmd("cd " .. tmp_dir)
  vim.fn.delete(non_git, "rf")
end)

test("log returns commits for file", function()
  local commits = git.log("renamed.lua")
  assert(#commits == 3, "expected 3 commits, got " .. #commits)
end)

test("log commits have required fields", function()
  local commits = git.log("renamed.lua")
  local c = commits[1]
  assert(c.hash and #c.hash > 0, "hash should be present")
  assert(c.date and #c.date > 0, "date should be present")
  assert(c.message and #c.message > 0, "message should be present")
  assert(c.path and #c.path > 0, "path should be present")
end)

test("log detects rename", function()
  local commits = git.log("renamed.lua")
  -- The rename commit should have the rename info
  local rename_commit = commits[1] -- most recent first
  assert(
    rename_commit.message == "rename test to renamed",
    "got: " .. tostring(rename_commit.message)
  )
end)

test("log preserves order (newest first)", function()
  local commits = git.log("renamed.lua")
  assert(commits[1].message == "rename test to renamed")
  assert(commits[2].message == "modify test file")
  assert(commits[3].message == "initial commit")
end)

test("show returns file contents", function()
  local commits = git.log("renamed.lua")
  local content = git.show(commits[1].hash, commits[1].path)
  assert(content:find("line1"), "should contain line1")
  assert(content:find("modified"), "should contain modified")
end)

test("show returns old file contents", function()
  local commits = git.log("renamed.lua")
  local content = git.show(commits[3].hash, commits[3].path)
  assert(content:find("line1"), "should contain line1")
  assert(content:find("line2"), "should contain original line2")
end)

test("log with empty path does not error", function()
  local ok, result = pcall(git.log, "")
  assert(ok, "git.log with empty path should not error")
  assert(type(result) == "table", "should return a table")
end)

-- Cleanup
vim.cmd("cd " .. original_dir)
vim.fn.delete(tmp_dir, "rf")

print("\nAll git tests passed!")
vim.cmd("qall!")
