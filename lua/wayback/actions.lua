local M = {}

local function is_https_url(url)
  return url:match("^https://")
end

local function get_repo_url()
  local branch = vim.fn.system("git symbolic-ref --short HEAD"):gsub("%s+", "")
  if branch == "" then
    vim.notify("Could not determine current branch", vim.log.levels.ERROR)
    return nil
  end

  local remote = vim.fn.system("git config --get branch." .. branch .. ".remote"):gsub("%s+", "")
  if remote == "" then
    vim.notify("No remote tracking branch found for '" .. branch .. "'", vim.log.levels.ERROR)
    return nil
  end

  local repo_url = vim.fn.system("git remote get-url " .. remote):gsub("%s+", "")
  if repo_url == "" then
    vim.notify("Failed to get URL for remote '" .. remote .. "'", vim.log.levels.ERROR)
    return nil
  end

  if not is_https_url(repo_url) then
    repo_url = repo_url:gsub(":", "/")
    repo_url = repo_url:gsub("git@", "https://")
  end
  repo_url = repo_url:gsub("%.git$", "")
  repo_url = repo_url:gsub("[^/]+@dev", "dev")

  return repo_url
end

local function url_encode(str)
  if str then
    str = string.gsub(str, "\n", "\r\n")
    str = string.gsub(str, "([^%w %.])", function(c)
      return string.format("%%%02X", string.byte(c))
    end)
    str = string.gsub(str, " ", "+")
  end
  return str
end

local function detect_forge(url)
  local cfg = require("wayback.config").values
  if cfg.forge then
    return cfg.forge
  end

  if url:find("gitlab") then
    return "gitlab"
  end
  if url:find("bitbucket") then
    return "bitbucket"
  end
  if url:find("dev%.azure%.com") or url:find("visualstudio%.com") then
    return "azure_devops"
  end
  return "github"
end

local url_builders = {
  github = function(repo_url, hash, path)
    return repo_url .. "/blob/" .. hash .. "/" .. path
  end,
  gitlab = function(repo_url, hash, path)
    return repo_url .. "/-/blob/" .. hash .. "/" .. path
  end,
  bitbucket = function(repo_url, hash, path)
    return repo_url .. "/src/" .. hash .. "/" .. path
  end,
  azure_devops = function(repo_url, hash, path)
    return repo_url .. "?path=" .. url_encode(path) .. "&version=GC" .. hash .. "&_a=contents"
  end,
}

local function get_file_at_commit_url(repo_url, hash, path)
  local forge = detect_forge(repo_url)
  local builder = url_builders[forge]
  return builder(repo_url, hash, path)
end

--- Open a file at a specific commit in the web browser.
--- @param hash string The commit hash
--- @param path string The file path at that commit
function M.open_in_browser(hash, path)
  local config = require("wayback.config").values
  local repo_url = get_repo_url()
  if not repo_url then
    return
  end
  local full_url = get_file_at_commit_url(repo_url, hash, path)

  local open_cmd = config.browser_command
  if not open_cmd then
    if vim.fn.executable("xdg-open") == 1 then
      open_cmd = "xdg-open"
    elseif vim.fn.executable("open") == 1 then
      open_cmd = "open"
    elseif vim.fn.executable("start") == 1 then
      open_cmd = "start"
    elseif vim.fn.executable("wslview") == 1 then
      open_cmd = "wslview"
    else
      vim.notify(
        "No command available to open URL [xdg-open, open, start or wslview]",
        vim.log.levels.ERROR
      )
      return
    end
  end

  local output = vim.fn.jobstart({ open_cmd, full_url }, { detach = true })
  if output <= 0 then
    vim.notify(
      string.format("Failed to open URL: %s with command: %s", full_url, open_cmd),
      vim.log.levels.ERROR
    )
  end
end

--- Try to open a file at a specific commit using a fugitive object URI.
--- @param hash string The commit hash
--- @param path string The file path at that commit
--- @param split_cmd string How to open: "edit", "vsplit", "split", or "tabedit"
--- @return boolean success Whether the file was opened via fugitive
local valid_split_cmds = { edit = true, vsplit = true, split = true, tabedit = true }

local function try_open_fugitive(hash, path, split_cmd)
  split_cmd = valid_split_cmds[split_cmd] and split_cmd or "edit"
  if vim.fn.exists("*FugitiveFind") ~= 1 then
    return false
  end
  local ok, uri = pcall(vim.fn.FugitiveFind, hash .. ":" .. path)
  if not ok or not uri or uri == "" then
    return false
  end
  vim.cmd({ cmd = split_cmd, args = { vim.fn.fnameescape(uri) } })
  return true
end

--- Open a file at a specific commit in a buffer.
--- If vim-fugitive is installed, opens as a fugitive object.
--- Otherwise, opens in a read-only scratch buffer.
--- @param hash string The commit hash
--- @param path string The file path at that commit
--- @param split_cmd string How to open: "edit", "vsplit", "split", or "tabedit"
function M.open_buffer(hash, path, split_cmd)
  if try_open_fugitive(hash, path, split_cmd) then
    return
  end

  local git = require("wayback.git")
  local content = git.show(hash, path)

  if split_cmd == "vsplit" then
    vim.cmd("vsplit")
  elseif split_cmd == "split" then
    vim.cmd("split")
  elseif split_cmd == "tabedit" then
    vim.cmd("tabedit")
  end

  local short_hash = hash:sub(1, 7)
  local buf_name = "wayback://" .. short_hash .. "/" .. path

  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(b) and vim.api.nvim_buf_get_name(b) == buf_name then
      vim.api.nvim_win_set_buf(0, b)
      return
    end
  end

  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n"))
  pcall(vim.api.nvim_buf_set_name, buf, buf_name)

  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"

  local ft = vim.filetype.match({ filename = path, buf = buf })
  if ft then
    vim.bo[buf].filetype = ft
  end
end

--- Copy a commit hash to the clipboard.
--- @param hash string The commit hash
function M.yank_hash(hash)
  vim.fn.setreg("+", hash)
  vim.notify("Copied " .. hash:sub(1, 7))
end

return M
