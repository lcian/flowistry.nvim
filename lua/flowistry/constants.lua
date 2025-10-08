---@class flowistry.constants
---@return flowistry.constants
local M = {}

M.rust_toolchain_channel = "nightly-2025-08-20"
M.rust_toolchain_components = { "rust-src", "rustc-dev", "llvm-tools-preview" }
M.command_timeout_ms = 60 * 1000
M.flowistry_version = "0.5.44"

return M
