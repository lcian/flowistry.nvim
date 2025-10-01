local logger = require("plenary.log").new({ plugin = "flowistry.nvim" })

---@class flowistry.utils
---@field findBufferWorkspaceRoot fun()
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

return M
