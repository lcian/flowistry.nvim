---@class flowistry.constants
---@return flowistry.constants
local M = {
  timeout = 60 * 1000,
  highlight = {
    priority = 1000,
    ---@type table<flowistry.highlight.group, string>
    groups = {
      mark = "FlowistryMark",
      direct = "FlowistryDirect",
      indirect = "FlowistryIndirect",
      backdrop = "FlowistryBackdrop",
    },
  },
  flowistry = {
    version = "0.5.44",
  },
  rust = {
    toolchain = {
      channel = "nightly-2025-08-20",
      components = { "rust-src", "rustc-dev", "llvm-tools-preview" },
    },
  },
}

function M.setup()
  M.augroup = vim.api.nvim_create_augroup("flowistry", { clear = true })
  M.namespace = vim.api.nvim_create_namespace("flowistry")
end

M.setup()

return M
