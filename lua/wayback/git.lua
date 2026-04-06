local M = {}

local toplevel_cache = nil

function M.is_git_directory()
  local result = vim.fn.system("git rev-parse --is-inside-work-tree")
  return result:sub(1, 4) == "true"
end

function M.toplevel()
  if not toplevel_cache then
    toplevel_cache = vim.fn.system("git rev-parse --show-toplevel"):gsub("%s+$", "")
  end
  return toplevel_cache
end

function M._parse_log_output(content)
  local commits = {}
  local current_commit = {}

  for line in content:gmatch("[^\n]+") do
    if line:match("^hash:") then
      if next(current_commit) then
        table.insert(commits, current_commit)
      end
      current_commit = { hash = line:match("^hash: (.+)$") }
    elseif line:match("^date:") then
      current_commit.date = line:match("^date: (.+)$")
    elseif line:match("^message:") then
      current_commit.message = line:match("^message: (.+)$")
    elseif line:match("^%S") then
      local type, remainder = line:match("^(%S+)%s+(.+)$")
      current_commit.type = type
      if remainder then
        local old_name, new_name = remainder:match("^(.-)\t(.*)$")
        if not old_name or old_name == "" then
          old_name = remainder
          new_name = ""
        end
        current_commit.old_name = old_name and old_name:gsub("%s+$", "") or ""
        current_commit.new_name = new_name and new_name:gsub("^%s+", "") or ""
        current_commit.path = #current_commit.new_name > 0 and current_commit.new_name
          or current_commit.old_name
      end
    elseif line == "" and next(current_commit) then
      table.insert(commits, current_commit)
      current_commit = {}
    end
  end

  if next(current_commit) then
    table.insert(commits, current_commit)
  end

  return commits
end

function M.log(file_path)
  file_path = file_path or vim.fn.expand("%")
  local content = vim.fn.system({
    "git",
    "--no-pager",
    "log",
    "--follow",
    "--name-status",
    "--pretty=format:hash: %H\ndate: %ad\nmessage: %s\n",
    "--date=short",
    "--",
    file_path,
  })
  return M._parse_log_output(content)
end

function M.show(hash, path)
  return vim.fn.system({ "git", "--no-pager", "show", hash .. ":" .. path })
end

function M.repo_relative_path(absolute_path)
  local tl = M.toplevel()
  local resolved_path = vim.fn.resolve(absolute_path)
  local resolved_toplevel = vim.fn.resolve(tl)
  if resolved_path:sub(1, #resolved_toplevel) == resolved_toplevel then
    return resolved_path:sub(#resolved_toplevel + 2)
  end
  return absolute_path
end

function M.log_range(file_path, start_line, end_line)
  local range_spec = string.format("%d,%d:%s", start_line, end_line, file_path)
  local content = vim.fn.system({
    "git",
    "--no-pager",
    "log",
    "--date=short",
    "-L",
    range_spec,
  })

  local commits = {}
  local current = {}
  local awaiting_message = false

  for line in content:gmatch("[^\n]*\n?") do
    line = line:gsub("\n$", "")
    local hash = line:match("^commit (%x+)")
    if hash then
      if current.hash then
        table.insert(commits, current)
      end
      current = { hash = hash, path = file_path }
      awaiting_message = false
    elseif line:match("^Date:") then
      current.date = vim.trim(line:match("^Date:%s+(.+)"))
      awaiting_message = true
    elseif awaiting_message and line:match("^%s+%S") then
      current.message = vim.trim(line)
      awaiting_message = false
    end
  end

  if current.hash then
    table.insert(commits, current)
  end

  return commits
end

return M
