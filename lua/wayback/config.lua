local M = {}

M.values = {
  -- Which picker backend to use: "telescope", "fzf_lua", "snacks", or "auto"
  -- "auto" will detect the first available picker
  picker = "auto",

  -- Keymaps inside the picker (only used by telescope backend)
  mappings = {
    i = {},
    n = {},
  },

  -- The command to use for opening the browser (nil or string)
  -- If nil, it will check if xdg-open, open, start, wslview are available, in that order.
  browser_command = nil,

  -- Force a specific forge for browser URLs: "github", "gitlab", "bitbucket", "azure_devops"
  -- If nil, auto-detects from remote URL hostname
  forge = nil,

  -- Timelapse buffer keybindings
  timelapse = {
    next = "]v",
    prev = "[v",
    quit = "q",
  },
}

local valid_pickers = { auto = true, telescope = true, fzf_lua = true, snacks = true }
local valid_forges = { github = true, gitlab = true, bitbucket = true, azure_devops = true }

local function validate(values)
  vim.validate({
    picker = {
      values.picker,
      function(v)
        return valid_pickers[v] ~= nil
      end,
      "one of 'auto', 'telescope', 'fzf_lua', 'snacks'",
    },
    browser_command = { values.browser_command, { "string", "nil" } },
    forge = {
      values.forge,
      function(v)
        return v == nil or valid_forges[v] ~= nil
      end,
      "nil or one of 'github', 'gitlab', 'bitbucket', 'azure_devops'",
    },
    mappings = { values.mappings, "table" },
    ["mappings.i"] = { values.mappings.i, "table" },
    ["mappings.n"] = { values.mappings.n, "table" },
    timelapse = { values.timelapse, "table" },
    ["timelapse.next"] = { values.timelapse.next, "string" },
    ["timelapse.prev"] = { values.timelapse.prev, "string" },
    ["timelapse.quit"] = { values.timelapse.quit, "string" },
  })
end

function M.setup(opts)
  opts = opts or {}
  M.values = vim.tbl_deep_extend("force", M.values, opts)
  validate(M.values)
end

return M
