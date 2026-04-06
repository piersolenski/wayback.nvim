-- Test that open() handles missing buffer gracefully
local wayback = require("wayback")

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    print("PASS: " .. name)
  else
    print("FAIL: " .. name .. " - " .. tostring(err))
    vim.cmd("cquit 1")
  end
end

-- Set up a temporary git repo so we pass the git checks
local tmp_dir = vim.fn.tempname()
vim.fn.mkdir(tmp_dir, "p")
vim.fn.system("cd " .. tmp_dir .. " && git init && git config user.email 'test@test.com' && git config user.name 'Test'")

local original_dir = vim.fn.getcwd()
vim.cmd("cd " .. tmp_dir)

-- Capture vim.notify calls
local notifications = {}
local original_notify = vim.notify
vim.notify = function(msg, level)
  table.insert(notifications, { msg = msg, level = level })
end

test("open with no buffer notifies user", function()
  -- Ensure current buffer has no file
  vim.cmd("enew")
  notifications = {}

  wayback.open()

  assert(#notifications == 1, "expected 1 notification, got " .. #notifications)
  assert(
    notifications[1].msg == "No file in current buffer",
    "unexpected message: " .. notifications[1].msg
  )
  assert(notifications[1].level == vim.log.levels.WARN, "expected WARN level")
end)

test("open with explicit empty path notifies user", function()
  notifications = {}

  wayback.open("")

  assert(#notifications == 1, "expected 1 notification, got " .. #notifications)
  assert(
    notifications[1].msg == "No file in current buffer",
    "unexpected message: " .. notifications[1].msg
  )
end)

-- Test fugitive integration
local actions = require("wayback.actions")

test("open_buffer uses fugitive when available", function()
  -- Mock vim.fn.exists to report FugitiveFind is available
  local original_exists = vim.fn.exists
  vim.fn.exists = function(name)
    if name == "*FugitiveFind" then
      return 1
    end
    return original_exists(name)
  end

  local fugitive_find_arg = nil
  vim.fn.FugitiveFind = function(arg)
    fugitive_find_arg = arg
    return "fugitive:///tmp/.git//abc123:test.lua"
  end

  -- Track what vim.cmd receives
  local cmd_called = nil
  local original_cmd = vim.cmd
  vim.cmd = function(c)
    cmd_called = c
  end

  actions.open_buffer("abc123", "test.lua", "edit")

  assert(fugitive_find_arg == "abc123:test.lua", "expected FugitiveFind('abc123:test.lua'), got: " .. tostring(fugitive_find_arg))
  assert(cmd_called and cmd_called:find("fugitive://"), "expected fugitive URI in cmd, got: " .. tostring(cmd_called))

  -- Restore
  vim.cmd = original_cmd
  vim.fn.exists = original_exists
  vim.fn.FugitiveFind = nil
end)

test("open_buffer falls back to scratch buffer without fugitive", function()
  -- Ensure FugitiveFind doesn't exist (default state)

  -- Create a test file and commit in the temp repo
  vim.fn.writefile({ "hello" }, tmp_dir .. "/fallback.txt")
  vim.fn.system("cd " .. tmp_dir .. " && git add fallback.txt && git commit -m 'add fallback'")
  local hash = vim.fn.system("cd " .. tmp_dir .. " && git rev-parse HEAD"):gsub("%s+", "")

  actions.open_buffer(hash, "fallback.txt", "edit")

  local buf_name = vim.api.nvim_buf_get_name(0)
  assert(buf_name:find("wayback://"), "expected wayback:// buffer name, got: " .. buf_name)
  assert(vim.bo.buftype == "nofile", "expected nofile buftype")
  assert(vim.bo.readonly == true, "expected readonly buffer")
end)

-- Restore
vim.notify = original_notify
vim.cmd("cd " .. original_dir)
vim.fn.delete(tmp_dir, "rf")

print("\nAll open tests passed!")
vim.cmd("qall!")
