-- Always show dotfiles/hidden files in the Neo-tree file explorer.
---@type LazySpec
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        hide_dotfiles = false,
      },
    },
    window = {
      position = "right",
      mappings = {
        ["<C-d>"] = { "scroll_preview", config = { direction = -10 } },
        ["<C-u>"] = { "scroll_preview", config = { direction = 10 } },
        ["<C-f>"] = false,
        ["<C-b>"] = false,
      },
    },
  },
}
