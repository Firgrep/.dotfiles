-- Match VS Code's default bracket-pair-colorization, which cycles through
-- 3 colors (gold / orchid / blue) rather than rainbow-delimiters' default 7.
-- The actual colors for these groups are set per-colorscheme in astroui.lua.

---@type LazySpec
return {
  "HiPhish/rainbow-delimiters.nvim",
  opts = {
    highlight = {
      "RainbowDelimiterYellow",
      "RainbowDelimiterViolet",
      "RainbowDelimiterBlue",
    },
  },
}
