include_files = { "lua/", "plugin/" }
exclude_files = { "lua/vendor/" }
self = false
cache = true
std = "lua54+nvim"
read_globals = { "vim" }
stds.nvim = {
  read_globals = { "jit" },
}
max_line_length = 200
