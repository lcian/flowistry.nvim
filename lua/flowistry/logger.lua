---@class flowistry.Logger
---@field trace fun(_)
---@field debug fun(_)
---@field info fun(_)
---@field warn fun(_)
---@field error fun(_)
---@field fatal fun(_)
local M = {}

M.trace = function(_) end
M.debug = function(_) end
M.info = function(_) end
M.warn = function(_) end
M.error = function(_) end
M.fatal = function(_) end

return M
