local flowistry = require("flowistry")
local logger = require("flowistry.logger")

local commands = {}

function commands.focus()
  flowistry.focus()
end

function commands.clear()
  flowistry.clear()
end

local command_names = {}
for name in pairs(commands) do
  command_names[#command_names + 1] = name
end

vim.api.nvim_create_user_command("Flowistry", function(opts)
  local subcommand = opts.fargs[1]
  -- local subcommand_args = vim.list_slice(opts.fargs, 2)

  if not subcommand then
    logger.error("no subcommand provided")
    return
  end

  local fun = commands[subcommand]
  if fun ~= nil then
    fun()
  else
    logger.error("unknown subcommand: " .. subcommand)
  end
end, {
  nargs = "*",
  complete = function(_, _)
    return command_names
  end,
})
