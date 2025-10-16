local logger = require("flowistry.logger")
local utils = require("flowistry.utils")

---@class flowistry
---@return flowistry
local M = {}

---Default options
---@class flowistry.options
local defaults = {
  log_level = "info",
  register_default_keymaps = true,
}

---@class flowistry.options
---@field log_level string
---@field register_default_keymaps boolean

---Sets up the plugin
---@param opts flowistry.options
M.setup = function(opts)
  local options = vim.tbl_deep_extend("force", defaults, opts or {})

  logger = assert(require("flowistry.logger").setup({ level = options.log_level }))
  logger.debug("flowistry.focus()")

  require("flowistry.state").setup(options)

  require("flowistry.highlight").setup() -- TODO: pass opts to allow override

  if options.register_default_keymaps then
    require("flowistry.keymaps").setup()
  end
end

M.focus_toggle = function() end
M.focus_on = function() end
M.focus_off = function() end
M.set_mark = function() end
M.remove_mark = function() end

---TODO: remove
M.focus = function()
  M.render(utils.get_cursor_pos())
end

---@param position flowistry.charPos
M.render = function(position)
  utils.ensure_deps_and_immediately(function(deps_ok)
    if not deps_ok then
      return
    end
    utils.flowistry_focus({
      filename = vim.api.nvim_buf_get_name(0),
      position = position,
    }, function(_ok, _response) end)
  end)
end

return M
