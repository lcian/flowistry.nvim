---@class flowistry.highlight
---@field setup function
local M = {}

function M.setup()
  local links = {
    FlowistryMatch = "Search",
    FlowistryCurrent = "IncSearch",
    FlowistryBackdrop = "Comment",
    FlowistryLabel = "Substitute",
  }
  for hl_group, link in pairs(links) do
    vim.api.nvim_set_hl(0, hl_group, { link = link, default = true })
  end
end

M.setup()

return M
