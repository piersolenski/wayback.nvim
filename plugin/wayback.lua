vim.api.nvim_create_user_command("Wayback", function(opts)
  require("wayback").open(opts)
end, { nargs = "?", complete = "file", desc = "Browse file history at any commit" })
