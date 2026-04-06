local git = require("wayback.git")

local M = {}

local ns_id = vim.api.nvim_create_namespace("wayback_timelapse")

local function update_display(state)
  local commit = state.commits[state.index]
  local content = git.show(commit.hash, commit.path)
  local lines = vim.split(content, "\n")

  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false

  -- Update virtual text header
  vim.api.nvim_buf_clear_namespace(state.buf, ns_id, 0, -1)
  local total = #state.commits
  local info = string.format(
    "[%d/%d] %s %s - %s",
    total - state.index + 1,
    total,
    string.sub(commit.hash, 1, 7),
    commit.date or "",
    commit.message or ""
  )
  vim.api.nvim_buf_set_extmark(state.buf, ns_id, 0, 0, {
    virt_lines_above = true,
    virt_lines = { { { info, "WaybackTimelapse" } } },
  })
end

function M.start(file_path)
  local commits = git.log(file_path)

  if #commits == 0 then
    vim.notify("No commits found for this file", vim.log.levels.INFO)
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buf)

  local ft = vim.filetype.match({ filename = file_path })
  if ft then
    vim.bo[buf].filetype = ft
  end

  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  pcall(
    vim.api.nvim_buf_set_name,
    buf,
    "wayback://timelapse/" .. vim.fn.fnamemodify(file_path, ":t")
  )

  -- Start at newest commit (index 1)
  local state = {
    buf = buf,
    commits = commits,
    index = 1,
  }

  update_display(state)

  local keys = require("wayback.config").values.timelapse

  vim.keymap.set("n", keys.next, function()
    if state.index <= 1 then
      vim.notify("Already at newest version", vim.log.levels.INFO)
      return
    end
    state.index = state.index - 1
    update_display(state)
  end, { buffer = buf, desc = "Wayback: newer version" })

  vim.keymap.set("n", keys.prev, function()
    if state.index >= #state.commits then
      vim.notify("Already at oldest version", vim.log.levels.INFO)
      return
    end
    state.index = state.index + 1
    update_display(state)
  end, { buffer = buf, desc = "Wayback: older version" })

  vim.keymap.set("n", keys.quit, function()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end, { buffer = buf, desc = "Wayback: exit timelapse" })
end

return M
