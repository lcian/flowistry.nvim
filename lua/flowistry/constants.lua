---@class flowistry.constants
---@return flowistry.constants
local M = {}

M.rustToolchainChannel = "nightly-2025-08-20"
M.rustToolchainComponenents = { "rust-src", "rustc-dev", "llvm-tools-preview" }
M.commandTimeoutMs = 60 * 1000
M.flowistryVersion = "0.5.44"

return M
