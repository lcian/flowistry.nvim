local logger = require("plenary.log").new({ plugin = "flowistry.nvim" })

---@class flowistry.keymaps
---@field setup fun()
local M = {}

--- Sets up the default keymaps
M.setup = function()
	logger.info("setting up default keymaps")

	local wk_ok, wk = pcall(require, "which-key")
	if wk_ok then
		logger.info("setting up default keymaps using which-key")
		wk.add({
			{ "<leader>n", group = "Flowistry" },
			{ "<leader>nf", "<cmd>Flowistry focus<cr>", desc = "Focus", mode = "n" },
		})
	else
		logger.info("setting up default keymaps using vim api")
		logger.error("not implemented")
	end

	logger.info("set up default keymaps")
end

return M
