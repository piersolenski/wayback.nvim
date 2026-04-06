local config = require("wayback.config")
local git = require("wayback.git")

local M = {}

M.actions = require("wayback.actions")

vim.api.nvim_set_hl(0, "WaybackDate", { default = true, link = "Number" })
vim.api.nvim_set_hl(0, "WaybackTimelapse", { default = true, link = "Comment" })

local function get_visual_range()
  local mode = vim.api.nvim_get_mode().mode
  local is_visual = mode:match("^[vV]") or mode == "\22"
  if not is_visual then
    return nil, nil
  end
  local start_line = vim.fn.getpos("v")[2]
  local end_line = vim.fn.getcurpos()[2]
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", true)
  return start_line, end_line
end

function M.setup(opts)
  config.setup(opts)
end

local function validate(opts)
  if vim.fn.executable("git") == 0 then
    vim.notify("Git is not installed", vim.log.levels.ERROR)
    return nil
  end
  if not git.is_git_directory() then
    vim.notify("Not a git repository", vim.log.levels.ERROR)
    return nil
  end
  local file_path = nil
  if type(opts) == "string" then
    file_path = opts
  elseif opts and opts.fargs and opts.fargs[1] then
    file_path = opts.fargs[1]
  end
  if not file_path or file_path == "" then
    file_path = vim.fn.expand("%:p")
  end
  if not file_path or file_path == "" then
    vim.notify("No file in current buffer", vim.log.levels.WARN)
    return nil
  end
  return file_path
end

local picker_modules = {
  telescope = "wayback.pickers.telescope",
  fzf_lua = "wayback.pickers.fzf_lua",
  snacks = "wayback.pickers.snacks",
}

local picker_checks = {
  telescope = function()
    return pcall(require, "telescope")
  end,
  snacks = function()
    local ok, snacks = pcall(require, "snacks")
    return ok and snacks.picker ~= nil
  end,
  fzf_lua = function()
    return pcall(require, "fzf-lua")
  end,
}

local function detect_picker()
  for _, name in ipairs({ "snacks", "telescope", "fzf_lua" }) do
    if picker_checks[name]() then
      return name
    end
  end
  return nil
end

local function resolve_picker()
  local picker_name = config.values.picker
  if picker_name == "auto" then
    local detected = detect_picker()
    if not detected then
      error("wayback: no supported picker found. Install telescope.nvim, fzf-lua, or snacks.nvim")
    end
    picker_name = detected
  end

  local mod_path = picker_modules[picker_name]
  if not mod_path then
    error(
      "wayback: unknown picker '" .. picker_name .. "'. Use 'telescope', 'fzf_lua', or 'snacks'"
    )
  end

  return require(mod_path)
end

function M.open(opts)
  local visual_start, visual_end = get_visual_range()

  local file_path = validate(opts)
  if not file_path then
    return
  end
  if type(opts) ~= "table" then
    opts = {}
  end

  -- Detect range: from visual mode, command range, or explicit opts
  local line1, line2 = visual_start, visual_end
  if not line1 and opts.range and opts.range > 0 then
    line1 = opts.line1
    line2 = opts.line2
  end

  if line1 and line2 then
    local relative = git.repo_relative_path(file_path)
    local commits = git.log_range(relative, line1, line2)
    if #commits == 0 then
      vim.notify("No commits found for selected range", vim.log.levels.INFO)
      return
    end
    opts.commits = commits
  end

  resolve_picker().open(opts, file_path)
end

function M.heatmap()
  local file_path = validate()
  if not file_path then
    return
  end
  require("wayback.heatmap").toggle(file_path)
end

function M.timelapse(opts)
  local file_path = validate(opts)
  if not file_path then
    return
  end
  require("wayback.timelapse").start(file_path)
end

return M
