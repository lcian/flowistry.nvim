# flowistry.nvim

flowistry.nvim is a Neovim plugin that uses [flowistry](https://github.com/willcrichton/flowistry) to provide syntax highlighting based on information flow for Rust programs.

## Usage

- Enter focus mode using `:Flowistry focus on`. The plugin will track your cursor's position and select a portion of code surrounding it. All of the code in the current function that doesn't affect or isn't affected by the selected code (according to the information flow analysis) will be faded out.
- You can leave focus mode using `:Flowistry focus off`.
- You can also set a mark at the current cursor position using `:Flowistry mark set`. That allows you to move your cursor around freely, as the focus remains on the marked region.

## Installation

### Dependencies

You need at least `rustup` and `cargo`.
The plugin should be able to install the required (nightly) toolchain and `flowistry_ide` in case it's missing.
If that doesn't work, please open an Issue.

### Installation with lazy.nvim

```lua
{ "lcian/flowistry.nvim", ft = "rust", opts = {} }
```

## Configuration

Here is the default configuration for the plugin, which you can override using the mechanism provided by your plugin manager:

```lua
{
  log_level = "info",
  highlight = { -- each of the values here is of type `vim.api.keyset.highlight`
    mark = { link = "IncSearch", default = true }, -- FlowistryMark highlight group
    backdrop = { link = "Comment", default = true }, -- FlowistryBackdrop highlight group
  },
  register_default_keymaps = true,
}
```

### Keymaps

When `register_default_keymaps` is `true`, the plugin registers the following keymaps:

- `<leader>nf` - Toggle focus mode
- `<leader>nm` - Set mark at cursor position
- `<leader>nr` - Remove current mark

### Commands

The plugin defines the following commands:

- `:Flowistry focus toggle` - Toggle focus mode; this will enable syntax highligting based on the current cursor position
- `:Flowistry focus on` - Enable focus mode
- `:Flowistry focus off` - Disable focus mode
- `:Flowistry mark set` - Set a mark at the current cursor position; you can move around freely and the focus will remain on the mark
- `:Flowistry mark remove` - Remove the mark

You can disable the default keymaps and set up your own based on these commands.

## Acknowledgements

- [willcrichton/flowistry](https://github.com/willcrichton/flowistry) this plugin is completely based on the `flowistry` crates and VSCode plugin
- [iskolbin/lbase64](https://github.com/iskolbin/lbase64) for the vendored base64 implementation
- [SafeteeWoW/LibDeflate](https://github.com/SafeteeWoW/LibDeflate) for the vendored Deflate implementation

## Contributing

All Issues and Pull Requests are welcome.
For Pull Requests, please install the [pre-commit](https://github.com/pre-commit/pre-commit) hook to ensure all checks pass locally.
