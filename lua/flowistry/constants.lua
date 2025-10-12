---@class flowistry.constants
---@return flowistry.constants
local M = {
  rust_toolchain_channel = "nightly-2025-08-20",
  rust_toolchain_components = { "rust-src", "rustc-dev", "llvm-tools-preview" },
  flowistry_version = "0.5.44",
  general_timeout_ms = 60 * 1000,
  highlight = {
    priority = 1000,
    groups = {
      mark = "FlowistryMark",
      direct = "FlowistryDirect",
      indirect = "FlowistryIndirect",
      backdrop = "FlowistryBackdrop",
    },
  },
}

function M.setup()
  M.namespace = vim.api.nvim_create_namespace("flowistry")
end

M.setup()

return M
