----------------------------------- GENERAL ------------------------------------

---@class flowistry.placeInfo
---@field range flowistry.charRange
---@field ranges flowistry.charRange[]
---@field slice flowistry.charRange[]
---@field direct_influence flowistry.charRange[]

---@class flowistry.charRange
---@field start flowistry.charPos
---@field end flowistry.charPos
---@field filename table

---@class flowistry.charPos
---@field line integer
---@field column integer

------------------------------------ FOCUS -------------------------------------

---@class flowistry.focusResponse
---@field Ok flowistry.focusResponseOk?
---@field Err string

---@class flowistry.focusResponseOk
---@field place_info flowistry.placeInfo[]
---@field containers flowistry.charRange[]
