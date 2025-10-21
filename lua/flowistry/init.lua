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
  highlight = {
    mark = { link = "IncSearch", default = true },
    direct = { link = "Substitute", default = true },
    indirect = { link = "Search", default = true },
    backdrop = { link = "Comment", default = true },
  },
}

---@class flowistry.options
---@field log_level "trace"|"debug"|"info"|"warn"|"error"
---@field register_default_keymaps boolean
---@field highlight flowistry.highlight.options

---Sets up the plugin
---@param options flowistry.options
function M.setup(options)
  local opts = vim.tbl_deep_extend("force", defaults, options or {})

  logger.setup({ level = opts.log_level })
  logger.debug("flowistry.setup()")

  require("flowistry.state").setup(opts)

  require("flowistry.highlight").setup(opts.highlight)

  if opts.register_default_keymaps then
    require("flowistry.keymaps").setup()
  end

  utils.immediately(utils.maybe_install_dependencies)
end

function M.focus_toggle()
  if state.enabled then
    M.focus_off()
  else
    M.focus_on()
  end
end

function M.focus_on()
  if not state.has_deps then
    utils.immediately(function()
      vim.notify("[flowistry] currently installing dependencies, or failed to install them (you should've seen an error in this case)", vim.log.levels.INFO)
    end)
    return
  end
  state.enabled = true
  state.render_autocmd = vim.api.nvim_create_autocmd({ "CursorMoved" }, {
    group = constants.augroup,
    buffer = 0,
    callback = M.render,
  })
  state.save_autocmd = vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    group = constants.augroup,
    buffer = 0,
    callback = state.clear_cache,
  })
  M.render()
end

function M.focus_off()
  state.enabled = false
  vim.api.nvim_del_autocmd(state.render_autocmd)
  vim.api.nvim_del_autocmd(state.save_autocmd)
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
  if vim.deep_equal(position, state.last_position) then
    return
  end
  state.last_position = position
  vim.api.nvim_buf_clear_namespace(0, constants.namespace, 0, -1)
  utils.call_flowistry_then({
    filename = vim.api.nvim_buf_get_name(0),
    position = position,
  }, function(ok, result)
    if not ok or not result then
      return
    end

    local match = utils.focus_response_query(result, position)
    if not match then
      return
    end

    utils.immediately(function()
      local position_now = state.mark or utils.get_cursor_pos()
      if not vim.deep_equal(position, position_now) then
        --old render call
        return
      end
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
end

return M
