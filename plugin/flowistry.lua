local flowistry = require("flowistry")
local logger = require("flowistry.logger")

local commands = {
  ---TODO: remove
  ["focus"] = function()
    flowistry.focus()
  end,

  ["focus toggle"] = function()
    flowistry.focus_toggle()
  end,

  ["focus on"] = function()
    flowistry.focus_on()
  end,

  ["focus off"] = function()
    flowistry.focus_off()
  end,

  ["set_mark"] = function()
    flowistry.set_mark()
  end,

  ["remove_mark"] = function()
    flowistry.remove_mark()
  end,
}

vim.api.nvim_create_user_command("Flowistry", function(opts)
  local subcommand = opts.fargs[1]
  if opts.fargs[2] then
    subcommand = subcommand .. " " .. opts.fargs[2]
  end

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
    local names = {}
    for name in pairs(commands) do
      names[#names + 1] = name
    end
    return names
  end,
})
