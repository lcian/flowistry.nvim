local Job = require("plenary.job")
local constants = require("flowistry.constants")
local logger = require("flowistry.logger")

---@class flowistry.utils
---@field find_or_install_dependencies fun()
---@return flowistry.utils
local M = {}

local has_deps = false
---@return boolean: whether or not dependencies were successfully found/installed
function M.find_or_install_dependencies()
  if has_deps then
    return true
  end
  logger.debug("Finding/installing dependencies")

  local has_cargo = vim.fn.executable("cargo")
  if has_cargo == 0 then
    logger.error("flowistry requires cargo, please install it")
    return false
  end
  logger.debug("cargo found")

  local flowistryVersion = nil
  Job:new({
    command = "cargo",
    args = { "+" .. constants.rust.toolchain.channel, "flowistry", "-V" },
    on_stdout = function(_, data)
      flowistryVersion = (flowistryVersion or "") .. data
    end,
  }):sync(constants.timeout)

  local should_install = false
  if flowistryVersion == nil then
    logger.warn("flowistry is not installed")
    should_install = true
  elseif flowistryVersion ~= constants.flowistry.version then
    logger.warn("Found flowistry version " .. flowistryVersion .. " installed, but version " .. constants.flowistry.version .. " is required")
    should_install = true
  end

  if not should_install then
    logger.debug("flowistry is already installed with the right version")
    has_deps = true
    return true
  end
  logger.debug("flowistry is not installed, or not the right version")

  local install_success = true
  Job:new({
    command = "cargo",
    args = {
      "+" .. constants.rust.toolchain.channel,
      "install",
      "flowistry_ide",
      "--version",
      constants.flowistry.version,
      "--locked",
      "--force",
    },
    on_exit = function(_, code, _)
      if code ~= 0 then
        install_success = false
      end
    end,
  }):sync(constants.timeout)

  if not install_success then
    logger.error("Failed to install flowistry_ide")
    return false
  else
    logger.info("Installed flowistry_ide version " .. constants.flowistry.version)
  end

  has_deps = true
  return true
end

local LibDeflate = require("vendor.LibDeflate.LibDeflate")

---@param input string
M.decompress_gzip = function(input)
  --TODO: offload to subprocess if `gzip` or similar are available to do this async
  local deflate = input:sub(11, #input - 8) -- remove header
  return LibDeflate:DecompressDeflate(deflate)
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

M.wait_for_rust_analyzer = function()
  logger.debug("waiting for rust-analyzer")
  -- this doesn't actually work but let's roll with it for now
  vim.wait(constants.timeout, function()
    local status = vim.lsp.status()
    logger.debug(status)
    return status == ""
  end, 100)
  logger.debug("rust-analyzer done (allegedly)")
end

---Schedule a callback to run immediately on the neovim event loop.
---The callback is wrapped with `vim.schedule_wrap`.
---@param callback function
M.schedule_immediate = function(callback)
  local timer = (vim.uv or vim.loop).new_timer()
  timer:start(
    0,
    0,
    vim.schedule_wrap(function()
      timer:stop()
      callback()
    end)
  )
end

---@return flowistry.charPos
function M.get_cursor_pos()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local column = cursor[2]
  return { line = row, column = column }
end

return M
