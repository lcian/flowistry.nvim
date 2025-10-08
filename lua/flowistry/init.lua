local Job = require("plenary.job")
local base64 = require("vendor.base64")
local constants = require("flowistry.constants")
local logger = require("flowistry.logger")
local utils = require("flowistry.utils")

---@class flowistry
---@field setup fun(opts: flowistry.Options)
---@field focus fun()
---@return flowistry
local M = {}

---@class flowistry.Options
---@field log_level string
---@field register_default_keymaps boolean
local options = {}

--- Default options
---@class flowistry.Options
local defaults = {
  log_level = "info",
  register_default_keymaps = true,
}

--- Sets up the plugin
---@param opts flowistry.Options
M.setup = function(opts)
  options = vim.tbl_deep_extend("force", defaults, opts or {})

  logger = require("flowistry.logger").setup({ level = options.log_level })
  assert(logger ~= nil)

  logger.info("Setting up flowistry.nvim")

  if options.register_default_keymaps then
    require("flowistry.keymaps").setup()
  end

  logger.info("Set up flowistry.nvim")
end

--- Calls `flowistry focus`
--- TODO: implement correctly, we're doing other stuff to test here
M.focus = function()
  local ok = utils.findOrInstallDependencies()
  if not ok then
    return
  end

  logger.debug("calling flowistry focus")

  local filename = vim.api.nvim_buf_get_name(0)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]
  local column = cursor[2]

  local stderr_tbl = {}
  Job:new({
    command = "cargo",
    args = { "+" .. constants.rust_toolchain_channel, "flowistry", "focus", filename, tostring(row), tostring(column) },
    on_exit = function(_, code, _)
      logger.debug("flowistry exited with code " .. tostring(code))
      local stderr = table.concat(stderr_tbl)
      if stderr ~= "" then
        logger.error("error calling flowistry focus:\n" .. stderr)
        return
      end
    end,
    on_stderr = function(_, line, _)
      table.insert(stderr_tbl, line)
    end,
    on_stdout = function(_, line, _)
      local decoded = base64.decode(line)
      local json = utils.decompress_gzip(decoded)
      if json == nil then
        logger.error("failed to decode flowistry focus output")
        return
      end
      ---@type flowistry.focusResponse
      local result = vim.json.decode(json)
      if result.Err ~= nil then
        logger.warn("got err from flowistry focus: " .. result.Err)
        return
      end
      logger.debug("got Ok")
    end,
  }):start()
end

return M
