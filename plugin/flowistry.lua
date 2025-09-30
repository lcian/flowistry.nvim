local flowistry = require("flowistry")
local logger = require("plenary.log").new({ plugin = "flowistry.nvim", level = "error" })

vim.api.nvim_create_user_command("Flowistry", function(opts)
	local subcommand = opts.fargs[1]
	-- local subcommand_args = vim.list_slice(opts.fargs, 2)

	if not subcommand then
		logger.error("No subcommand provided")
		return
	end

	if subcommand == "focus" then
		flowistry.focus()
	else
		logger.error("Unknown subcommand: " .. subcommand)
	end
end, {
	nargs = "*",
	complete = function(_, _)
		return { "focus" }
	end,
})
