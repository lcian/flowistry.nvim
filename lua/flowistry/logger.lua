---@class flowistry.logger
---@return flowistry.logger
local M = {}

local level = "info"

function M.trace(message)
  M._log("trace", message)
end

function M.debug(message)
  M._log("debug", message)
end

function M.info(message)
  M._log("info", message)
end

function M.warn(message)
  M._log("warn", message)
end

function M.error(message)
  M._log("error", message)
end

---@param command string
---@param code integer
---@param stderr string?
function M.command_error(command, code, stderr)
  M._log("error", command .. " failed with exit code " .. code .. ": " .. (stderr or "[nothing on stderr]"))
end

function M.fatal(message)
  local _ = message
end

local highlight = {
  trace = "Comment",
  debug = "Comment",
  info = "None",
  warn = "WarningMsg",
  error = "ErrorMsg",
  fatal = "ErrorMsg",
}

---@private
---@param log_level string
---@param message string
function M._log(log_level, message)
  if log_level < level then
    return
  end

  local debug_info = debug.getinfo(3, "Sl")
  local code_path = debug_info.source:sub(2)
  local code_line = debug_info.currentline

  local function emit()
    vim.cmd(string.format("echohl %s", highlight[log_level]))
    local formatted = string.format("[%-6s%s] %s: %s : %s", log_level:upper(), os.date("%H:%M:%S"), code_path, code_line, message)
    for _, line in ipairs(vim.split(formatted, "\n")) do
      local formatted_line = string.format("[flowistry.nvim] %s", vim.fn.escape(line, [["\]]))
      ---@diagnostic disable-next-line
      local ok = pcall(vim.cmd, string.format([[echom "%s"]], formatted_line))
      if not ok then
        ---@diagnostic disable-next-line
        vim.api.nvim_out_write(formatted_line .. "\n")
      end
    end
    vim.cmd("echohl NONE")
  end

  if vim.in_fast_event() then
    vim.schedule(emit)
  else
    emit()
  end
end

---@class flowistry.logger.options
---@field level string

---@param opts flowistry.logger.options?
function M.setup(opts)
  level = (opts or {}).level or level
end

return M
