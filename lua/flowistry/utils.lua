local Job = require("plenary.job")
local constants = require("flowistry.constants")
local logger = require("flowistry.logger")

---@class flowistry.utils
---@field findBufferWorkspaceRoot fun()
---@field findOrInstallDependencies fun()
---@return flowistry.utils
local M = {}

M.findBufferWorkspaceRoot = function()
  logger.debug("Finding workspace root for current buffer")
  local cwd = vim.fn.getcwd(0, 0)
  local root = vim.fs.root(cwd, "Cargo.toml")
  if root == nil then
    logger.error("Workspace root not found")
  end
  logger.info("Found workspace root at " .. root)
  return root
end

---@return boolean: whether or not dependencies were successfully found/installed
M.findOrInstallDependencies = function()
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
    args = { "+" .. constants.rust_toolchain_channel, "flowistry", "-V" },
    on_stdout = function(_, data)
      flowistryVersion = (flowistryVersion or "") .. data
    end,
  }):sync(constants.command_timeout_ms)

  local should_install = false
  if flowistryVersion == nil then
    logger.warn("flowistry is not installed")
    should_install = true
  elseif flowistryVersion ~= constants.flowistry_version then
    logger.warn("Found flowistry version " .. flowistryVersion .. " installed, but version " .. constants.flowistry_version .. " is required")
    should_install = true
  end

  if not should_install then
    logger.debug("flowistry is already installed with the right version")
    return true
  end
  logger.debug("flowistry is not installed, or not the right version")

  local install_success = true
  Job:new({
    command = "cargo",
    args = {
      "+" .. constants.rust_toolchain_channel,
      "install",
      "flowistry_ide",
      "--version",
      constants.flowistry_version,
      "--locked",
      "--force",
    },
    on_exit = function(_, code, _)
      if code ~= 0 then
        install_success = false
      end
    end,
  }):sync(constants.command_timeout_ms)

  if not install_success then
    logger.error("Failed to install flowistry_ide")
    return false
  else
    logger.info("Installed flowistry_ide version " .. constants.flowistry_version)
  end

  return true
end

local LibDeflate = require("vendor.LibDeflate.LibDeflate")

---@param input string
M.decompress_gzip = function(input)
  local deflate = input:sub(11, #input - 8)
  return LibDeflate:DecompressDeflate(deflate)
end

return M
