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
}

function M.setup(opts)
  opts = opts or {}
  M.values = vim.tbl_deep_extend("force", M.values, opts)
end

return M
