local Job = require("plenary.job")
local base64 = require("vendor.base64")
local constants = require("flowistry.constants")
local logger = require("flowistry.logger")
local utils = require("flowistry.utils")

---@class flowistry
---@field setup fun(opts: flowistry.options)
---@field focus fun()
---@return flowistry
local M = {}

---@class flowistry.options
---@field log_level string
---@field register_default_keymaps boolean
local options = {}

--- Default options
---@class flowistry.options
local defaults = {
  log_level = "info",
  register_default_keymaps = true,
}

---Sets up the plugin
---@param opts flowistry.options
M.setup = function(opts)
  options = vim.tbl_deep_extend("force", defaults, opts or {})

  logger = assert(require("flowistry.logger").setup({ level = options.log_level }))
  logger.debug("flowistry.focus()")

  require("flowistry.state").setup(options)

  require("flowistry.highlight").setup() -- TODO: pass opts to allow override

  if options.register_default_keymaps then
    require("flowistry.keymaps").setup()
  end
end

---Call `flowistry focus` with the current cursor position
M.focus = function()
  logger.debug("flowistry.focus()")
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local column = cursor[2]
  M.focus_position(row, column)
end

M.focus_position = function(row, column)
  local ok = utils.find_or_install_dependencies()
  if not ok then
    return
  end

  logger.debug("calling flowistry.focus with row " .. row .. " and col " .. column)

  local filename = vim.api.nvim_buf_get_name(0)
  local stderr_tbl = {}
  Job:new({
    command = "cargo",
    args = { "+" .. constants.rust.toolchain.channel, "flowistry", "focus", filename, tostring(row), tostring(column) },
    on_exit = function(_, code, _)
      logger.debug("flowistry exited with code " .. tostring(code))
      local stderr = table.concat(stderr_tbl)
      if stderr ~= "" then
        logger.error("error calling flowistry focus:\n" .. stderr)
        return
      end
    end,
    on_stderr = function(_, line, _)
      logger.info("got some stderr")
      table.insert(stderr_tbl, line)
    end,
    on_stdout = function(_, line, _)
      logger.info("got some stdout: " .. line)
      local decoded = base64.decode(line) -- TODO: consider using shell for this too
      logger.info("decoded")

      local json = utils.decompress_gzip(decoded)
      if json == nil then
        logger.error("failed to decode flowistry focus output")
        return
      end
      logger.info("decoded gzip")

      ---@type flowistry.focusResponse
      local focus_result = vim.json.decode(json)
      if focus_result.Err ~= nil then
        -- TODO: change to error, possibly based on Err kind
        logger.warn("got Err from flowistry focus: " .. focus_result.Err)
        return
      end
      logger.info("ok")
      local result = assert(focus_result.Ok)
      logger.debug(vim.inspect(result.containers))

      local match = utils.focus_response_query(result, { line = row, column = column })
      if match == nil then
        logger.info("no matches, should return")
        return
      end

      utils.schedule_immediate(function()
        logger.debug("setting highlights")
        for _, pos in ipairs(result.containers) do
          vim.api.nvim_buf_set_extmark(0, constants.namespace, pos.start.line, pos.start.column, {
            end_row = pos["end"].line,
            end_col = pos["end"].column,
            hl_group = constants.highlight.groups.backdrop,
            priority = constants.highlight.priority,
            strict = false,
          })
        end
        for _, pos in ipairs(match.slice) do
          vim.api.nvim_buf_set_extmark(0, constants.namespace, pos.start.line, pos.start.column, {
            end_row = pos["end"].line,
            end_col = pos["end"].column,
            hl_group = constants.highlight.groups.indirect,
            priority = constants.highlight.priority + 1,
            strict = false,
          })
        end
        for _, pos in ipairs(match.direct_influence) do
          vim.api.nvim_buf_set_extmark(0, constants.namespace, pos.start.line, pos.start.column, {
            end_row = pos["end"].line,
            end_col = pos["end"].column,
            hl_group = constants.highlight.groups.direct,
            priority = constants.highlight.priority + 2,
            strict = false,
          })
        end
        vim.api.nvim_buf_set_extmark(0, constants.namespace, match.range.start.line, match.range.start.column, {
          end_row = match.range["end"].line,
          end_col = match.range["end"].column,
          hl_group = constants.highlight.groups.mark,
          priority = constants.highlight.priority + 3,
          strict = false,
        })
        logger.debug("set highlights")
      end)
    end,
  }):start()
end

---Clear state and highlihgts
M.clear = function()
  logger.debug("flowistry.clear()")
  vim.api.nvim_buf_clear_namespace(0, constants.namespace, 0, -1)
end

return M
