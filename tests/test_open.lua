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
vim.fn.system("cd " .. tmp_dir .. " && git init")

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

-- Restore
vim.notify = original_notify
vim.cmd("cd " .. original_dir)
vim.fn.delete(tmp_dir, "rf")

print("\nAll open tests passed!")
vim.cmd("qall!")
