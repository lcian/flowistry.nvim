---@class flowistry.focusResponse
---@field Ok flowistry.focusResponse.ok?
---@field Err string?

---@class flowistry.focusResponse.ok
---@field place_info flowistry.placeInfo[]
---@field containers flowistry.charRange[] [function body, function return type declaration, [function args declaration]?]

---@class flowistry.placeInfo
---@field range flowistry.charRange analysis target
---@field ranges flowistry.charRange[]
---@field slice flowistry.charRange[] all spans that have data/control flow dependencies to/from the target
---@field direct_influence flowistry.charRange[] direct reads/writes from/to the target

---@class flowistry.charRange
---@field start flowistry.charPos
---@field end flowistry.charPos
---@field filename table

---@class flowistry.charPos
---@field line integer
---@field column integer
