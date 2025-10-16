local constants = require("flowistry.constants")
local logger = require("flowistry.logger")

---@class flowistry.utils
---@field find_or_install_dependencies fun()
---@return flowistry.utils
local M = {}

local has_deps = nil
---Ensure that dependencies are installed, then schedule the callback to run immediately on the neovim event loop.
---The callback receives the result of the dependency check and is wrapped with `vim.schedule_wrap`.
---@param callback function(boolean)
function M.ensure_deps_and_immediately(callback)
  local cb = M.schedule_immediate_curried(callback)

  if has_deps ~= nil then
    cb(has_deps)
    return
  end
  logger.debug("finding/installing dependencies")

  local has_cargo = vim.fn.executable("cargo")
  if has_cargo == 0 then
    logger.error("flowistry requires cargo, please install it")
    has_deps = false
    cb(has_deps)
    return
  end
  logger.debug("cargo found")

  vim.system({ "cargo", "+" .. constants.rust.toolchain.channel, "flowistry", "-V" }, {
    text = true,
    timeout = constants.timeout,
  }, function(version_res)
    local should_install = true

    if version_res.code ~= 0 then
      logger.debug("flowistry is not installed")
    end

    if version_res.stdout then
      local installed_version = version_res.stdout:gsub("%s+", "")
      logger.debug("flowistry is installed with version " .. installed_version)
      if installed_version ~= constants.flowistry.version then
        logger.warn("found flowistry version " .. installed_version .. ", but version " .. constants.flowistry.version .. " is required")
      else
        should_install = false
      end
    end

    if not should_install then
      has_deps = true
      cb(has_deps)
      return
    end

    vim.system({
      "cargo",
      "+" .. constants.rust.toolchain.channel,
      "install",
      "flowistry_ide",
      "--version",
      constants.flowistry.version,
      "--locked",
      "--force",
    }, {
      text = true,
      timeout = constants.timeout,
    }, function(res)
      if res.code ~= 0 then
        logger.error("failed to install flowistry_ide")
        has_deps = false
        cb(has_deps)
        return
      end

      logger.info("installed flowistry_ide version " .. constants.flowistry.version)
      has_deps = true
      cb(has_deps)
    end)
  end)
end

---@generic T
---@param list T[]
---@param predicate function(element T) -> boolean
---@return T[]
M.filter = function(list, predicate)
  local res = {}
  for _, value in ipairs(list) do
    if predicate(value) then
      table.insert(res, value)
    end
  end
  return res
end

---@param ... boolean
---@return boolean
M.all = function(...)
  local args = { ... }
  for _, value in ipairs(args) do
    if not value then
      return false
    end
  end
  return true
end

---@param ... boolean
---@return boolean
M.any = function(...)
  local args = { ... }
  for _, value in ipairs(args) do
    if value then
      return true
    end
  end
  return false
end

---@param data flowistry.focusResponseOk
---@param query flowistry.charPos
---@return flowistry.placeInfo | nil
M.focus_response_query = function(data, query)
  ---@param place flowistry.placeInfo
  return M.filter(data.place_info, function(place)
    local a = query.line >= place.range.start.line
    local b = query.line <= place.range["end"].line
    local c = (query.line > place.range.start.line) or (place.range.start.column <= query.column)
    local d = (query.line < place.range["end"].line) or (query.column <= place.range["end"].column)
    return M.all(a, b, c, d)
  end)[1]
end

---Schedule a callback to run immediately on the neovim event loop.
---The callback is wrapped with `vim.schedule_wrap`.
---@param callback function
---@param params any?
M.schedule_immediate = function(callback, params)
  ---@diagnostic disable-next-line
  local timer = (vim.uv or vim.loop).new_timer()
  timer:start(
    0,
    0,
    vim.schedule_wrap(function()
      timer:stop()
      callback(params)
    end)
  )
end

---Schedule a callback to run immediately on the neovim event loop.
---The callback is wrapped with `vim.schedule_wrap`.
---Returns a function to pass params to.
M.schedule_immediate_curried = function(callback)
  return function(params)
    M.schedule_immediate(callback, params)
  end
end

---@return flowistry.charPos
function M.get_cursor_pos()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local column = cursor[2]
  return { line = row, column = column }
end

---@class flowistry.utils.focusOpts
---@field filename string
---@field position flowistry.charPos
---@field use_cache boolean?

---@param opts flowistry.utils.focusOpts
---@param _cb function
function M.flowistry_focus(opts, _cb)
  opts.use_cache = opts.use_cache or true

  vim.system(
    { "cargo", "+" .. constants.rust.toolchain.channel, "flowistry", "focus", opts.filename, tostring(opts.position.line), tostring(opts.position.column) },
    { timeout = constants.timeout },
    function(res)
      if res.code ~= 0 then
        logger.command_error("cargo flowistry focus", res.code, res.stderr)
        return
      end

      local function render(json)
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

        local match = M.focus_response_query(result, opts.position)
        if match == nil then
          logger.info("no matches, should return")
          return
        end
        M.schedule_immediate(function()
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
      end

      local function after_base64(compressed)
        local has_gzip = vim.fn.executable("gzip")
        if has_gzip == 0 then
          logger.debug("doesn't have gzip, using vendored one")
          local deflate = compressed:sub(11, #compressed - 8) -- remove header
          local LibDeflate = require("vendor.LibDeflate.LibDeflate")
          local json = LibDeflate:DecompressDeflate(deflate)
          render(json)
        else
          vim.system({ "gzip", "-d" }, { timeout = constants.timeout, stdin = compressed }, function(g)
            if g.code ~= 0 then
              logger.command_error("gzip -d", g.code, g.stderr)
              return
            end
            render(g.stdout)
          end)
        end
      end

      local has_base64 = vim.fn.executable("base64")
      if has_base64 == 0 then
        logger.debug("doesn't have base64, using vendored one")
        local base64 = require("vendor.base64")
        local decoded = base64.decode(res.stdout)
        after_base64(decoded)
      else
        logger.debug(res.stdout)
        vim.system({ "base64", "-d" }, { timeout = constants.timeout, stdin = res.stdout }, function(b)
          if b.code ~= 0 then
            logger.command_error("base64 -d", b.code, b.stderr)
            return
          end
          after_base64(b.stdout)
        end)
      end
    end
  )
end

return M
