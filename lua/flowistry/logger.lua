---@class flowistry.logger
---@field setup fun(options)
---@field trace fun(message)
---@field debug fun(message)
---@field info fun(message)
---@field warn fun(message)
---@field error fun(message)
---@field fatal fun(message)
---@return flowistry.logger
local M = {}

M.trace = function(_) end
M.debug = function(_) end
M.info = function(_) end
M.warn = function(_) end
M.error = function(_) end
M.fatal = function(_) end

---@class flowistry.logger.Options
---@field level string

---@param options flowistry.logger.Options
M.setup = function(options)
  local logger = require("plenary.log").new({ plugin = "flowistry.nvim", level = options.level })
  M.trace = logger.trace
  M.debug = logger.debug
  M.warn = logger.warn
  M.info = logger.info
  M.error = logger.error
  M.fatal = logger.fatal
  return M
end

return M
