local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  error("This telescope extension requires nvim-telescope/telescope.nvim")
end

local wb = require("wayback")
local wb_config = require("wayback.config")

return telescope.register_extension({
  setup = function(opts)
    wb_config.setup(opts)
  end,
  exports = {
    wayback = function(opts)
      require("wayback.pickers.telescope").open(opts)
    end,
    actions = wb.actions,
  },
})
