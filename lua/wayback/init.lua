local config = require("wayback.config")
local git = require("wayback.git")

local M = {}

M.actions = require("wayback.actions")

function M.setup(opts)
  config.setup(opts)
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
    picker_name = detect_picker()
    if not picker_name then
      error("wayback: no supported picker found. Install telescope.nvim, fzf-lua, or snacks.nvim")
    end
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
  opts = opts or {}

  if vim.fn.executable("git") == 0 then
    vim.notify("wayback: git is not installed", vim.log.levels.ERROR)
    return
  end

  if not git.is_git_directory() then
    vim.notify("wayback: not a git repository", vim.log.levels.ERROR)
    return
  end

  local file_path = nil
  if opts.fargs and opts.fargs[1] then
    file_path = opts.fargs[1]
  end

  resolve_picker().open(opts, file_path)
end

return M
