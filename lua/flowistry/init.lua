local constants = require("flowistry.constants")
local logger = require("flowistry.logger")
local state = require("flowistry.state")
local utils = require("flowistry.utils")

---@class flowistry
---@return flowistry
local M = {}

---Default options
---@class flowistry.options
local defaults = {
  log_level = "info",
  register_default_keymaps = true,
}

---@class flowistry.options
---@field log_level string
---@field register_default_keymaps boolean

---Sets up the plugin
---@param opts flowistry.options
function M.setup(opts)
  local options = vim.tbl_deep_extend("force", defaults, opts or {})

  logger.setup({ level = options.log_level })
  logger.debug("flowistry.setup()")

  require("flowistry.state").setup(options)

  require("flowistry.highlight").setup() -- TODO: pass opts to allow override

  if options.register_default_keymaps then
    require("flowistry.keymaps").setup()
  end
end

function M.focus_toggle()
  if state.enabled then
    M.focus_off()
  else
    M.focus_on()
  end
end

function M.focus_on()
  state.enabled = true
  state.autocmd = vim.api.nvim_create_autocmd({ "CursorMoved" }, {
    group = constants.augroup,
    buffer = 0,
    callback = M.render,
  })
  M.render()
end

function M.focus_off()
  state.enabled = false
  vim.api.nvim_del_autocmd(state.autocmd)
  vim.api.nvim_buf_clear_namespace(0, constants.namespace, 0, -1)
end

function M.mark_set()
  state.mark = utils.get_cursor_pos()
end

function M.mark_remove()
  state.mark = nil
end

function M.render()
  if not state.enabled then
    return
  end
  local position = state.mark or utils.get_cursor_pos()
  if position == state.last_position then
    return
  end
  state.last_position = position
  vim.api.nvim_buf_clear_namespace(0, constants.namespace, 0, -1)
  utils.ensure_deps_then(function(deps_ok)
    if not deps_ok then
      return
    end
    utils.call_flowistry_then({
      filename = vim.api.nvim_buf_get_name(0),
      position = position,
    }, function(ok, result)
      if not ok or not result then
        return
      end

      local match = utils.focus_response_query(result, position)
      if match == nil then
        logger.info("no matches, should return")
        return
      end

      utils.immediately(function()
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
    end)
  end)
end

return M
