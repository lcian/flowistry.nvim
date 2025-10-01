include_files = { "lua/" }
self = false
cache = true
std = "lua54+nvim"
read_globals = { "vim" }
stds.nvim = {
  read_globals = { "jit" },
}
max_line_length = 200
