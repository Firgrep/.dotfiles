-- AstroNvim renders icons through mini.icons.
-- Use the Seti "go" glyph (nf-seti-go, U+E627) for .go files instead of the
-- default Material Design one, and color plain folders sandy yellow instead of
-- azure (`FolderSand` is defined in astroui.lua).
local go = { glyph = "\u{e627}", hl = "MiniIconsAzure" }

---@type LazySpec
return {
  "nvim-mini/mini.icons",
  opts = {
    default = { directory = { hl = "FolderSand" } },
    extension = { go = go },
    filetype = { go = go },
  },
}
