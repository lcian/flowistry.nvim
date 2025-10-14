---@class flowistry.logger
---@field trace fun(message)
---@field debug fun(message)
---@field info fun(message)
---@field warn fun(message)
---@field error fun(message)
---@field fatal fun(message)
---@return flowistry.logger
local M = {}

M.trace = function(message)
  local _ = message
end
M.debug = function(message)
  local _ = message
end
M.info = function(message)
  local _ = message
end
M.warn = function(message)
  local _ = message
end
M.error = function(message)
  local _ = message
end
M.fatal = function(message)
  local _ = message
end

---@class flowistry.logger.options
---@field level string

---@param opts flowistry.logger.options?
M.setup = function(opts)
  local options = vim.tbl_deep_extend("force", { plugin = "flowistry.nvim", level = "info" }, opts or {})
  local logger = require("plenary.log").new(options)
  M.trace = logger.trace
  M.debug = logger.debug
  M.warn = logger.warn
  M.info = logger.info
  M.error = logger.error
  M.fatal = logger.fatal
  return M
end

M.setup()

return M
