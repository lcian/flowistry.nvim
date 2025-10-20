local logger = require("flowistry.logger")

---@private
---@class flowistry.cache.entry
---@field filename string analysis filename
---@field range flowistry.charRange flowistry.focusResponse.ok.containers[1]
---@field response flowistry.focusResponse.ok

---@private
---@type flowistry.cache.entry[]
local cache = {}

---@alias flowistry.cache table<flowistry.focusResponse.ok>
local cache_proxy = {}

local cache_size = 0
local cache_capacity = 20

local cache_meta = {
  __index = function(_, index)
    ---@type string
    local filename = index[1]
    ---@type flowistry.charPos
    local position = index[2]
    local j = nil
    for i, entry in ipairs(cache) do
      local a = filename == entry.filename
      local b = position.line >= entry.range.start.line
      local c = position.line <= entry.range["end"].line
      local d = (position.line > entry.range.start.line) or (entry.range.start.column <= position.column)
      local e = (position.line < entry.range["end"].line) or (position.column <= entry.range["end"].column)
      if a and b and c and d and e then
        j = i
        break
      end
    end
    if j == nil then
      logger.debug("cache miss")
      return nil
    end
    logger.debug("cache hit")
    local entry = table.remove(cache, j)
    table.insert(cache, entry)
    return entry.response
  end,
  ---@param value flowistry.focusResponse.ok
  __newindex = function(_, index, value)
    ---@type string
    local filename = index[1]
    ---@type flowistry.charRange
    local range = index[2]
    local j = nil
    for i, entry in ipairs(cache) do
      if filename == entry.filename and vim.deep_equal(range, entry.range) then
        j = i
        break
      end
    end
    if j ~= nil then
      local entry = table.remove(cache, j)
      table.insert(cache, entry)
    else
      table.insert(cache, { filename = filename, range = range, response = value })
      cache_size = cache_size + 1
    end
    if cache_size > cache_capacity then
      table.remove(cache, 1)
      cache_size = cache_size - 1
    end
  end,
}

setmetatable(cache_proxy, cache_meta)

---@class flowistry.state
---@field options flowistry.options current options
---@field cache flowistry.cache
---@field has_deps boolean are dependencies installed
---@field enabled boolean? buffer local - is focus mode enabled
---@field mark flowistry.charPos? buffer local - mark position
---@field autocmd integer? buffer local - render autocmd
---@field last_pos flowistry.charPos? buffer local - last position we focused on
---@return flowistry.state
local M = {
  has_deps = false,
  cache = cache_proxy,
  options = {},
}

local buflocals = { "enabled", "mark", "autocmd", "last_pos" }

local state_meta = {
  __index = function(table, index)
    if index == "cache" then
      return cache_proxy[index]
    end
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
    if index == "cache" then
      cache_proxy[index] = value
      return
    end
    for _, name in ipairs(buflocals) do
      if name == index then
        vim.api.nvim_buf_set_var(0, "flowistry.state." .. name, value)
        return
      end
    end
    rawset(table, index, value)
  end,
}

setmetatable(M, state_meta)

---@param options flowistry.options
M.setup = function(options)
  M.options = options
end

return M
