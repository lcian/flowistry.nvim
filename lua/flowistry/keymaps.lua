local logger = require("flowistry.logger")

---@class flowistry.keymaps
---@return flowistry.keymaps
local M = {}

local keymaps = {
  {
    map = "<leader>nf",
    cmd = "<cmd>Flowistry focus toggle<cr>",
    desc = "Toggle focus",
    mode = "n",
  },
  {
    map = "<leader>nm",
    cmd = "<cmd>Flowistry mark set<cr>",
    desc = "Set mark",
    mode = "n",
  },
  {
    map = "<leader>nr",
    cmd = "<cmd>Flowistry mark remove<cr>",
    desc = "Remove mark",
    mode = "n",
  },
}

function M.setup()
  logger.debug("flowistry.keymaps.setup()")

  local ok, wk = pcall(require, "which-key")
  if ok then
    logger.debug("using which-key")
    local wk_keymaps = {
      { "<leader>n", group = "Flowistry" },
    }
    for _, keymap in ipairs(keymaps) do
      table.insert(wk_keymaps, { keymap.map, keymap.cmd, desc = keymap.desc, mode = keymap.mode })
    end
    wk.add(wk_keymaps)
  else
    logger.debug("using vim api")
    for _, keymap in ipairs(keymaps) do
      vim.keymap.set(keymap.mode, keymap.map, keymap.cmd, { desc = keymap.desc })
    end
  end
end

return M
