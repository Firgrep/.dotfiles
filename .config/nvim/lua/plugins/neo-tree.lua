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
  },
}
