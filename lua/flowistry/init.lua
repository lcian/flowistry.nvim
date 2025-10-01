local logger = require("plenary.log").new({ plugin = "flowistry.nvim" })
local constants = require("flowistry.constants")
local Job = require("plenary.job")

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
	registerDefaultKeymaps = true,
}

--- Sets up the plugin
---@param opts flowistry.Options
M.setup = function(opts)
	logger.info("Loading flowistry.nvim")

	options = vim.tbl_deep_extend("force", defaults, opts or {})

	if options.registerDefaultKeymaps then
		require("flowistry.keymaps").setup()
	end

	logger.info("Loaded flowistry.nvim")
end

--- Calls `flowistry focus`
M.focus = function()
	Job:new({
		command = "cargo",
		args = { "+" .. constants.rustToolchainChannel, "build" },
		on_stdout = function(error, data)
			print(vim.inspect(error))
			print(vim.inspect(data))
		end,
		on_stderr = function(error, data)
			print(vim.inspect(error))
			print(vim.inspect(data))
		end,
		on_exit = function(j, return_val)
			print(vim.inspect(return_val))
			print(vim.inspect(j:result()))
		end,
	}):sync(constants.timeoutSecs)
end

return M
