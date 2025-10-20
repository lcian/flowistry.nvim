local constants = require("flowistry.constants")
local logger = require("flowistry.logger")
local state = require("flowistry.state")

---@class flowistry.utils
---@field find_or_install_dependencies fun()
---@return flowistry.utils
local M = {}

function M.maybe_install_dependencies()
  logger.debug("checking if dependencies are installed")

  local has_cargo = vim.fn.executable("cargo")
  if has_cargo == 0 then
    logger.error("flowistry requires cargo, please install it")
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
      should_install = true
    else
      local installed_version = version_res.stdout:gsub("%s+", "")
      logger.debug("flowistry is installed with version " .. installed_version)
      if installed_version ~= constants.flowistry.version then
        logger.warn("found flowistry version " .. installed_version .. ", but version " .. constants.flowistry.version .. " expected")
      else
        should_install = false
      end
    end

    if not should_install then
      logger.debug("flowistry is already installed with the expected version")
      state.has_deps = true
      return
    end

    M.immediately(function()
      vim.notify("[flowistry] installing dependencies", vim.log.levels.INFO)
    end)

    local has_rustup = vim.fn.executable("rustup")
    if has_rustup == 0 then
      logger.error("installing flowistry requires rustup, please install it")
      return
    end

    logger.debug("installing Rust toolchain " .. constants.rust.toolchain.channel)
    vim.system({
      "rustup",
      "toolchain",
      "install",
      constants.rust.toolchain.channel,
    }, {
      text = true,
      timeout = constants.timeout,
    }, function(toolchain_res)
      if toolchain_res.code ~= 0 then
        logger.error("failed to install flowistry: failed to install Rust toolchain " .. constants.rust.toolchain.channel)
        return
      end

      local cmd = { "rustup", "component", "add" }
      for _, component in ipairs(constants.rust.toolchain.components) do
        table.insert(cmd, component)
      end
      table.insert(cmd, "--toolchain")
      table.insert(cmd, constants.rust.toolchain.channel)

      logger.debug("installing required components " .. vim.inspect(constants.rust.toolchain.components) .. " for toolchain " .. constants.rust.toolchain.channel)
      vim.system(cmd, {
        text = true,
        timeout = constants.timeout,
      }, function(components_res)
        if components_res.code ~= 0 then
          logger.debug("failed to install required components " .. vim.inspect(constants.rust.toolchain.components) .. " for toolchain " .. constants.rust.toolchain.channel)
          return
        end

        logger.debug("installing flowistry_ide version " .. constants.flowistry.version)
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
            logger.error("failed to install flowistry: failed to install flowistry_ide version" .. constants.rust.toolchain.channel)
            return
          end

          M.immediately(function()
            vim.notify("[flowistry] installed dependencies", vim.log.levels.INFO)
          end)
          state.has_deps = true
        end)
      end)
    end)
  end)
end

---@generic T
---@param list T[]
---@param predicate function(element T) -> boolean
---@return T[]
function M.filter(list, predicate)
  local res = {}
  for _, value in ipairs(list) do
    if predicate(value) then
      table.insert(res, value)
    end
  end
  return res
end

---@param data flowistry.focusResponse.ok
---@param query flowistry.charPos
---@return flowistry.placeInfo | nil
function M.focus_response_query(data, query)
  ---@param place flowistry.placeInfo
  return M.filter(data.place_info, function(place)
    local a = query.line >= place.range.start.line
    local b = query.line <= place.range["end"].line
    local c = (query.line > place.range.start.line) or (place.range.start.column <= query.column)
    local d = (query.line < place.range["end"].line) or (query.column <= place.range["end"].column)
    return a and b and c and d
  end)[1]
end

---Schedule a callback to run immediately on the neovim event loop.
---The callback is wrapped with `vim.schedule_wrap`.
---@param callback function
---@param params any?
function M.immediately(callback, params)
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

---@return flowistry.charPos
function M.get_cursor_pos()
  logger.debug("get_cursor_pos()")
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local column = cursor[2]
  return { line = row, column = column }
end

---@class flowistry.utils.focusOpts
---@field filename string
---@field position flowistry.charPos

---@param opts flowistry.utils.focusOpts
---@param callback function(boolean, flowistry.focusResponse.ok?)
function M.call_flowistry_then(opts, callback)
  local cached_res = state.cache[{ opts.filename, opts.position }]
  if cached_res then
    callback(true, cached_res)
    return
  end

  vim.system(
    { "cargo", "+" .. constants.rust.toolchain.channel, "flowistry", "focus", opts.filename, tostring(opts.position.line), tostring(opts.position.column) },
    { timeout = constants.timeout },
    function(res)
      if res.code ~= 0 then
        logger.command_error("cargo flowistry focus", res.code, res.stderr)
        return
      end

      local function after_gzip(json)
        ---@type flowistry.focusResponse
        local focus_result = vim.json.decode(json)
        if focus_result.Err ~= nil then
          -- TODO: change to error, possibly based on Err kind
          logger.warn("got Err from flowistry focus: " .. focus_result.Err)
          callback(false, nil)
          return
        end
        local result = assert(focus_result.Ok)
        state.cache[{ opts.filename, result.containers[1] }] = result
        callback(true, result)
      end

      local function after_base64(compressed)
        local has_gzip = vim.fn.executable("gzip")
        if has_gzip == 0 then
          logger.debug("doesn't have gzip, using vendored one")
          local deflate = compressed:sub(11, #compressed - 8) -- remove header
          local LibDeflate = require("vendor.LibDeflate.LibDeflate")
          local json = LibDeflate:DecompressDeflate(deflate)
          after_gzip(json)
        else
          vim.system({ "gzip", "-d" }, { timeout = constants.timeout, stdin = compressed }, function(g)
            if g.code ~= 0 then
              logger.command_error("gzip -d", g.code, g.stderr)
              return
            end
            after_gzip(g.stdout)
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
