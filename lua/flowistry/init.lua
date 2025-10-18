local constants = require("flowistry.constants")
local logger = require("flowistry.logger")
local state = require("flowistry.state")
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
function M.setup(opts)
  local options = vim.tbl_deep_extend("force", defaults, opts or {})

  logger.setup({ level = options.log_level })
  logger.debug("flowistry.setup()")

  require("flowistry.state").setup(options)

  require("flowistry.highlight").setup() -- TODO: pass opts to allow override

  if options.register_default_keymaps then
    require("flowistry.keymaps").setup()
  end
end

function M.focus_toggle()
  if state.enabled then
    M.focus_off()
  else
    M.focus_on()
  end
end

function M.focus_on()
  state.enabled = true
  state.autocmd = vim.api.nvim_create_autocmd({ "CursorMoved" }, {
    group = constants.augroup,
    buffer = 0,
    callback = M.render,
  })
  M.render()
end

function M.focus_off()
  state.enabled = false
  vim.api.nvim_del_autocmd(state.autocmd)
  vim.api.nvim_buf_clear_namespace(0, constants.namespace, 0, -1)
end

function M.mark_set()
  state.mark = utils.get_cursor_pos()
end

function M.mark_remove()
  state.mark = nil
end

function M.render()
  if not state.enabled then
    return
  end
  local position = state.mark or utils.get_cursor_pos()
  if position == state.last_position then
    return
  end
  state.last_position = position
  vim.api.nvim_buf_clear_namespace(0, constants.namespace, 0, -1)
  utils.ensure_deps_then(function(deps_ok)
    if not deps_ok then
      return
    end
    --utils.call_flowistry_then(function(ok, res)
    --  if not ok then
    --    return
    --  end
    --end)
    utils.flowistry_focus({
      filename = vim.api.nvim_buf_get_name(0),
      position = position,
    }, function(_ok, _response) end)
  end)
end

return M
