---@class flowistry.constants
---@return flowistry.constants
local M = {}

M.rustToolchainChannel = "nightly-2025-08-20"
M.rustToolchainComponenents = { "rust-src", "rustc-dev", "llvm-tools-preview" }
M.cargoCommand = string.format("cargo +%s", M.rustToolchainChannel)
M.timeoutSecs = 1000

return M
