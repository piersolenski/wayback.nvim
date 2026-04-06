local git = require("wayback.git")
local actions_mod = require("wayback.actions")

local M = {}

function M.open(_opts, file_path)
  local Snacks = require("snacks")

  local commits = git.log(file_path)
  local items = {}

  for idx, commit in ipairs(commits) do
    table.insert(items, {
      idx = idx,
      text = commit.hash .. " " .. commit.date .. " " .. (commit.message or ""),
      hash = commit.hash,
      date = commit.date,
      message = commit.message or "",
      path = commit.path,
    })
  end

  Snacks.picker({
    title = "Wayback",
    items = items,
    format = function(item, _ctx)
      local ret = {}
      table.insert(ret, { item.date .. " ", "WaybackDate" })
      table.insert(ret, { string.sub(item.hash, 1, 7) .. " ", "SnacksPickerSpecial" })
      table.insert(ret, { item.message })
      return ret
    end,
    preview = function(ctx)
      local item = ctx.item
      local content = git.show(item.hash, item.path)
      local lines = vim.split(content, "\n")
      local buf = ctx.preview:scratch()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      ctx.preview:highlight({ file = item.path })
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        actions_mod.open_buffer(item.hash, item.path, "edit")
      end
    end,
    actions = {
      open_vsplit = function(picker, item)
        picker:close()
        if item then
          actions_mod.open_buffer(item.hash, item.path, "vsplit")
        end
      end,
      open_split = function(picker, item)
        picker:close()
        if item then
          actions_mod.open_buffer(item.hash, item.path, "split")
        end
      end,
      open_tab = function(picker, item)
        picker:close()
        if item then
          actions_mod.open_buffer(item.hash, item.path, "tabedit")
        end
      end,
      open_in_browser = function(_picker, item)
        if item then
          actions_mod.open_in_browser(item.hash, item.path)
        end
      end,
      yank_hash = function(_picker, item)
        if item then
          actions_mod.yank_hash(item.hash)
        end
      end,
    },
    win = {
      input = {
        keys = {
          ["<C-v>"] = { "open_vsplit", mode = { "n", "i" } },
          ["<C-x>"] = { "open_split", mode = { "n", "i" } },
          ["<C-t>"] = { "open_tab", mode = { "n", "i" } },
          ["<C-g>"] = { "open_in_browser", mode = { "n", "i" } },
          ["<C-y>"] = { "yank_hash", mode = { "n", "i" } },
        },
      },
    },
    sort = { fields = {} }, -- preserve git log order
  })
end

return M
