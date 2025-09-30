local logger = require("plenary.log").new({ plugin = "flowistry.nvim" })

---@class flowistry
---@field setup fun(opts: flowistry.Options)
---@field focus fun()
---@return flowistry
local M = {}

--- Options for the plugin
---@class flowistry.Options
---@field flowistryCommand string: the command to run flowistry
---@field registerDefaultKeymaps boolean: whether or not to register deafult keymaps
local options = {}

--- Default options
---@class flowistry.Options
local defaults = {
	flowistryCommand = "cargo",
	registerDefaultKeymaps = true,
}

--- Sets up the plugin
---@param opts flowistry.Options
M.setup = function(opts)
	logger.info("loading flowistry.nvim")

	options = vim.tbl_deep_extend("force", defaults, opts or {})

	if options.registerDefaultKeymaps then
		require("flowistry.keymaps").setup()
	end

	logger.info("loaded flowistry.nvim")
end

--- Calls `flowistry focus`
M.focus = function()
	vim.system({ options.flowistryCommand, "build" }, { text = true }, function(result)
		if result.code ~= 0 then
			print("error: got status code " .. result.code)
		else
			print("ok, got the following")
			print(result.stdout)
		end
	end)
end

return M
