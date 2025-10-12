local constants = require("flowistry.constants")

---@class flowistry.highlight
---@field setup function
local M = {}

function M.setup()
  local links = {
    [constants.highlight.groups.mark] = "IncSearch",
    [constants.highlight.groups.direct] = "Substitute",
    [constants.highlight.groups.indirect] = "Search",
    [constants.highlight.groups.backdrop] = "Comment",
  }
  for hl_group, link in pairs(links) do
    vim.api.nvim_set_hl(0, hl_group, { link = link, default = true })
  end
end

M.setup()

return M
