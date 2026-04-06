local git = require("wayback.git")
local actions_mod = require("wayback.actions")

local M = {}

local SEP = "\t"

local function parse_entry(entry)
  local hash, path = entry:match("^(.-)" .. SEP .. "(.-)" .. SEP)
  return { hash = hash, path = path }
end

function M.open(opts, file_path)
  local fzf_lua = require("fzf-lua")

  opts = opts or {}

  local commits = git.log(file_path)
  local entries = {}

  for _, commit in ipairs(commits) do
    local short_hash = string.sub(commit.hash, 1, 7)
    local display = string.format(
      "%s %s %s",
      fzf_lua.utils.ansi_codes.cyan(commit.date),
      fzf_lua.utils.ansi_codes.green(short_hash),
      commit.message or ""
    )
    local entry = commit.hash .. SEP .. commit.path .. SEP .. display
    table.insert(entries, entry)
  end

  fzf_lua.fzf_exec(
    entries,
    vim.tbl_deep_extend("force", {
      prompt = "Wayback> ",
      fzf_opts = {
        ["--no-sort"] = "",
        ["--delimiter"] = SEP,
        ["--with-nth"] = "3",
        ["--preview"] = 'git --no-pager show {1}:"{2}"',
        ["--header"] = "ctrl-g: browser | ctrl-v: vsplit | ctrl-x: split | ctrl-t: tab | ctrl-y: yank hash",
      },
      previewer = false,
      actions = {
        ["default"] = function(selected)
          if not selected or #selected == 0 then
            return
          end
          local entry = parse_entry(selected[1])
          actions_mod.open_buffer(entry.hash, entry.path, "edit")
        end,
        ["ctrl-v"] = function(selected)
          if not selected or #selected == 0 then
            return
          end
          local entry = parse_entry(selected[1])
          actions_mod.open_buffer(entry.hash, entry.path, "vsplit")
        end,
        ["ctrl-x"] = function(selected)
          if not selected or #selected == 0 then
            return
          end
          local entry = parse_entry(selected[1])
          actions_mod.open_buffer(entry.hash, entry.path, "split")
        end,
        ["ctrl-t"] = function(selected)
          if not selected or #selected == 0 then
            return
          end
          local entry = parse_entry(selected[1])
          actions_mod.open_buffer(entry.hash, entry.path, "tabedit")
        end,
        ["ctrl-g"] = function(selected)
          if not selected or #selected == 0 then
            return
          end
          local entry = parse_entry(selected[1])
          actions_mod.open_in_browser(entry.hash, entry.path)
        end,
        ["ctrl-y"] = function(selected)
          if not selected or #selected == 0 then
            return
          end
          local entry = parse_entry(selected[1])
          actions_mod.yank_hash(entry.hash)
        end,
      },
    }, opts)
  )
end

return M
