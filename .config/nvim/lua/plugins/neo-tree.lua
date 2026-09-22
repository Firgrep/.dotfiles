-- Always show dotfiles/hidden files in the Neo-tree file explorer.
---@type LazySpec
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts_extend = { "event_handlers" },
  opts = {
    -- VS Code style "preview tab": moving onto a node previews it live into
    -- the real editor window; pressing <cr> commits it as a real open.
    event_handlers = {
      {
        event = "after_render",
        handler = function()
          local state = require("neo-tree.sources.manager").get_state("filesystem")
          if state and state.tree and not require("neo-tree.sources.common.preview").is_active() then
            state.config = { use_float = false }
            state.commands.toggle_preview(state)
          end
        end,
      },
    },
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
