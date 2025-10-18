---@class flowistry.state
---@field options flowistry.options current options
---@field cache table<string, flowistry.focusResponse.ok> cache for analysis results - unused for now
---@field enabled boolean? buffer local - is focus mode enabled
---@field mark flowistry.charPos? buffer local - mark position
---@field autocmd integer? buffer local - render autocmd
---@field last_pos flowistry.charPos? buffer local - last position we focused on
---@return flowistry.state
local M = {
  options = {},
  cache = {},
}

local buflocals = { "enabled", "mark", "autocmd", "last_pos" }

local meta = {
  __index = function(table, index)
    for _, name in ipairs(buflocals) do
      if name == index then
        local ok, value = pcall(function()
          return vim.api.nvim_buf_get_var(0, "flowistry.state." .. name)
        end)
        if ok then
          return value
        else
          return nil
        end
      end
    end
    return rawget(table, index)
  end,
  __newindex = function(table, index, value)
    for _, name in ipairs(buflocals) do
      if name == index then
        vim.api.nvim_buf_set_var(0, "flowistry.state." .. name, value)
        return
      end
    end
    rawset(table, index, value)
  end,
}

---@param options flowistry.options
M.setup = function(options)
  M.options = options
end

setmetatable(M, meta)

return M
