local logger = require("flowistry.logger")
local utils = require("flowistry.utils")

---@class flowistry
---@field setup fun(opts: flowistry.Options)
---@field focus fun()
---@return flowistry
local M = {}

---@class flowistry.Options
---@field log_level string
---@field register_default_keymaps boolean
local options = {}

--- Default options
---@class flowistry.Options
local defaults = {
  log_level = "info",
  register_default_keymaps = true,
}

--- Sets up the plugin
---@param opts flowistry.Options
M.setup = function(opts)
  options = vim.tbl_deep_extend("force", defaults, opts or {})

  logger = require("flowistry.logger").setup({ level = options.log_level })
  assert(logger ~= nil)

  logger.info("Setting up flowistry.nvim")

  if options.register_default_keymaps then
    require("flowistry.keymaps").setup()
  end

  logger.info("Set up flowistry.nvim")
end

--- Calls `flowistry focus`
--- TODO: implement correctly, we're doing other stuff to test here
M.focus = function()
  local res = utils.findOrInstallDependencies()
  logger.debug(res)
end

return M
