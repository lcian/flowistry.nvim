local constants = require("flowistry.constants")

---@class flowistry.highlight
---@field setup function
local M = {}

function M.setup()
  local links = {
    [constants.highlight_groups.match] = "Search",
    [constants.highlight_groups.current] = "IncSearch",
    [constants.highlight_groups.backdrop] = "Comment",
    [constants.highlight_groups.label] = "Substitute",
  }
  for hl_group, link in pairs(links) do
    vim.api.nvim_set_hl(0, hl_group, { link = link, default = true })
  end
end

M.setup()

return M
