local constants = require("flowistry.constants")

---@class flowistry.highlight
---@return flowistry.highlight
local M = {}

---@alias flowistry.highlight.group "mark"|"direct"|"indirect"|"backdrop"
---@alias flowistry.highlight.options table<flowistry.highlight.group, vim.api.keyset.highlight>

---@param options flowistry.highlight.options
function M.setup(options)
  for group, highlight in pairs(options) do
    vim.api.nvim_set_hl(0, constants.highlight.groups[group], highlight)
  end
end

return M
