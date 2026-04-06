local M = {}

function M.is_git_directory()
  local result = vim.fn.system("git rev-parse --is-inside-work-tree")
  return result:sub(1, 4) == "true"
end

function M.log(file_path)
  file_path = file_path or vim.fn.expand("%")
  local prefix =
    'git --no-pager log --follow --name-status --pretty=format:"hash: %H%ndate: %ad%nmessage: %s%n" --date=short '
  local cmd = prefix .. '"' .. file_path .. '"'
  local content = vim.fn.system(cmd)

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

function M.show(hash, path)
  return vim.fn.system("git --no-pager show " .. hash .. ":" .. '"' .. path .. '"')
end

return M
