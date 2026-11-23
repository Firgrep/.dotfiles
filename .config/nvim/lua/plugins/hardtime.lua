-- Break bad Vim habits (hjkl spamming, arrow keys, etc.) by blocking or
-- hinting at repeated keys. https://github.com/m4xshen/hardtime.nvim

---@type LazySpec
return {
  "m4xshen/hardtime.nvim",
  enabled = false,
  event = "VeryLazy",
  dependencies = { "MunifTanjim/nui.nvim" },
  opts = {},
}
