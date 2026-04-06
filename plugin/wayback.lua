vim.api.nvim_create_user_command("Wayback", function(opts)
  require("wayback").open(opts)
end, { nargs = "?", range = true, complete = "file", desc = "Browse file history at any commit" })

vim.api.nvim_create_user_command("WaybackHeatmap", function()
  require("wayback").heatmap()
end, { desc = "Toggle change frequency heatmap" })

vim.api.nvim_create_user_command("WaybackTimelapse", function(opts)
  require("wayback").timelapse(opts)
end, { nargs = "?", complete = "file", desc = "Step through file versions" })

vim.api.nvim_create_user_command("WaybackDiff", function()
  require("wayback.actions").diff_with_current()
end, { desc = "Diff wayback buffer with current version" })

vim.api.nvim_create_user_command("WaybackDiffOff", function()
  require("wayback.actions").diff_off()
end, { desc = "Turn off wayback diff" })
