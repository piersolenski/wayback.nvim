local git = require("wayback.git")

local M = {}

local ns_id = vim.api.nvim_create_namespace("wayback_heatmap")
local active_buffers = {}

local heatmap_colors = {
  "#1a1b2e", -- 1: very faint blue
  "#1e2440", -- 2: dark blue
  "#232d52", -- 3: blue
  "#2a3355", -- 4: blue-purple
  "#3b2d4a", -- 5: purple
  "#4a2842", -- 6: purple-red
  "#5c2238", -- 7: dark red
  "#6e1d2e", -- 8: red
  "#801824", -- 9: bright red
  "#92131a", -- 10: hot red
}

for i, color in ipairs(heatmap_colors) do
  vim.api.nvim_set_hl(0, "WaybackHeat" .. i, { default = true, bg = color })
end

function M.compute_frequency(file_path, line_count)
  local content = vim.fn.system({
    "git",
    "--no-pager",
    "log",
    "--follow",
    "-p",
    "--max-count=200",
    "--pretty=format:WAYBACK_COMMIT",
    "--",
    file_path,
  })

  local freq = {}
  for i = 1, line_count do
    freq[i] = 0
  end

  for line in content:gmatch("[^\n]+") do
    local start, count = line:match("^@@ %-%d+,?%d* %+(%d+),?(%d*) @@")
    if start then
      start = tonumber(start)
      count = tonumber(count)
      if not count or count == 0 then
        count = 1
      end
      for i = start, math.min(start + count - 1, line_count) do
        freq[i] = freq[i] + 1
      end
    end
  end

  return freq
end

function M.toggle(file_path)
  local buf = vim.api.nvim_get_current_buf()

  if active_buffers[buf] and vim.api.nvim_buf_is_valid(buf) then
    M.clear(buf)
    return
  end
  active_buffers[buf] = nil

  local relative = git.repo_relative_path(file_path)
  local line_count = vim.api.nvim_buf_line_count(buf)
  local freq = M.compute_frequency(relative, line_count)

  local max_freq = 0
  for _, v in pairs(freq) do
    if v > max_freq then
      max_freq = v
    end
  end

  if max_freq == 0 then
    vim.notify("No change history found", vim.log.levels.INFO)
    return
  end

  for line_nr, count in pairs(freq) do
    if count > 0 then
      local level = math.ceil((count / max_freq) * 10)
      vim.api.nvim_buf_set_extmark(buf, ns_id, line_nr - 1, 0, {
        line_hl_group = "WaybackHeat" .. level,
        priority = 10,
      })
    end
  end

  active_buffers[buf] = true
  vim.notify("Heatmap enabled", vim.log.levels.INFO)
end

function M.clear(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
  active_buffers[buf] = nil
  vim.notify("Heatmap disabled", vim.log.levels.INFO)
end

return M
