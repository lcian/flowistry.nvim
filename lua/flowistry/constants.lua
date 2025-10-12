---@class flowistry.constants
---@return flowistry.constants
local M = {}

M.rust_toolchain_channel = "nightly-2025-08-20"
M.rust_toolchain_components = { "rust-src", "rustc-dev", "llvm-tools-preview" }
M.flowistry_version = "0.5.44"
M.general_timeout_ms = 60 * 1000
M.highlight_groups = {
  match = "FlowistryMatch",
  current = "FlowistryCurrent",
  backdrop = "FlowistryBackdrop",
  label = "FlowistryLabel",
}

function M.setup()
  M.namespace = vim.api.nvim_create_namespace("flowistry")
end

M.setup()

return M
