local git = require("wayback.git")
local actions_mod = require("wayback.actions")
local config = require("wayback.config")

local M = {}

function M.open(opts, file_path)
  local action_set = require("telescope.actions.set")
  local action_state = require("telescope.actions.state")
  local actions = require("telescope.actions")
  local conf = require("telescope.config").values
  local finders = require("telescope.finders")
  local pickers = require("telescope.pickers")
  local previewers = require("telescope.previewers")
  local entry_display = require("telescope.pickers.entry_display")

  opts = opts or {}

  pickers
    .new(opts, {
      results_title = "Commits for current file",
      finder = finders.new_table({
        results = git.log(file_path),
        entry_maker = function(entry)
          local displayer = entry_display.create({
            separator = " ",
            items = {
              { width = 10 },
              { width = 7 },
              { remaining = true },
            },
          })

          return {
            value = entry.hash,
            display = function()
              return displayer({
                { entry.date, "TelescopeResultsConstant" },
                { string.sub(entry.hash, 1, 7), "TelescopeResultsIdentifier" },
                entry.message,
              })
            end,
            ordinal = entry.hash .. entry.date .. (entry.message or ""),
            path = entry.path,
          }
        end,
      }),
      sorter = conf.file_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        local function open(cmd)
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          actions_mod.open_buffer(selection.value, selection.path, cmd)
        end

        action_set.select:replace(function()
          open("edit")
        end)
        actions.select_tab:replace(function()
          open("tabedit")
        end)
        actions.select_horizontal:replace(function()
          open("split")
        end)
        actions.select_vertical:replace(function()
          open("vsplit")
        end)

        map("i", "<C-g>", function()
          local selection = action_state.get_selected_entry()
          actions_mod.open_in_browser(selection.value, selection.path)
        end)
        map("n", "<C-g>", function()
          local selection = action_state.get_selected_entry()
          actions_mod.open_in_browser(selection.value, selection.path)
        end)

        map("i", "<C-y>", function()
          local selection = action_state.get_selected_entry()
          actions_mod.yank_hash(selection.value)
        end)
        map("n", "<C-y>", function()
          local selection = action_state.get_selected_entry()
          actions_mod.yank_hash(selection.value)
        end)

        for mode, tbl in pairs(config.values.mappings) do
          for key, action in pairs(tbl) do
            map(mode, key, action)
          end
        end

        return true
      end,
      previewer = previewers.new_buffer_previewer({
        title = "File contents at commit",
        get_buffer_by_name = function(_, entry)
          return entry.value .. ":" .. entry.path
        end,
        define_preview = function(self, entry, _)
          if self.state.bufname == entry.value .. ":" .. entry.path then
            return
          end

          local content = git.show(entry.value, entry.path)
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(content, "\n"))

          local ok, pfiletype = pcall(require, "plenary.filetype")
          if ok then
            local ft = pfiletype.detect(entry.path, {})
            require("telescope.previewers.utils").highlighter(self.state.bufnr, ft)
          else
            local ft = vim.filetype.match({ filename = entry.path }) or ""
            vim.bo[self.state.bufnr].filetype = ft
          end
        end,
      }),
    })
    :find()
end

return M
