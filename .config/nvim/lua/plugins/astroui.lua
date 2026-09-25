
-- AstroUI provides the basis for configuring the AstroNvim User Interface
-- Configuration documentation can be found with `:h astroui`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

---@type LazySpec
return {
  "AstroNvim/astroui",
  ---@type AstroUIOpts
  opts = {
    -- change colorscheme
    colorscheme = "vscode",
    -- AstroUI allows you to easily modify highlight groups easily for any and all colorschemes
    highlights = {
      init = { -- this table overrides highlights in all themes
        -- Normal = { bg = "#000000" },
      },
      astrodark = { -- a table of overrides/changes when applying the astrotheme theme
        -- Normal = { bg = "#000000" },
      },
      vscode = function()
        -- the bundled vscode.nvim theme colors `@type.builtin` (e.g. Go's
        -- `string`/`float64`) with vscBlue (#569CD6), but real VS Code Dark+
        -- colors built-in types the same teal as user-defined types
        -- (vscBlueGreen, #4EC9B0). Fix the mismatch here.
        local colors = require("vscode.colors").get_colors()
        return {
          ["@type.builtin"] = { fg = colors.vscBlueGreen, bg = "NONE" },
          -- match VS Code's default bracket-pair-colorization cycle
          -- (gold / orchid / blue), which repeats every 3 nesting levels
          RainbowDelimiterYellow = { fg = "#FFD700", bg = "NONE" },
          RainbowDelimiterViolet = { fg = "#DA70D6", bg = "NONE" },
          RainbowDelimiterBlue = { fg = "#179FFF", bg = "NONE" },
          -- gopls (and some other LSPs) reports every keyword - if/for/return
          -- included - as one generic "keyword" semantic token type with no
          -- sub-kind. The theme links that straight to `@keyword` (blue),
          -- which paints over the treesitter-based `@keyword.conditional`
          -- /`@keyword.repeat`/`@keyword.return` (already correctly purple
          -- here) since semantic tokens render above treesitter. Clearing it
          -- lets those already-correct treesitter colors show through.
          ["@lsp.type.keyword"] = {},
          -- VS Code colors escape sequences (`\n`, `\t`, ...) a tan/khaki
          -- (#D7BA7D), distinct from the string itself. The theme only
          -- defines the pre-dot-notation `@stringEscape` name (which nothing
          -- uses anymore) and leaves `@string.escape` unset, so it falls back
          -- to plain `@string`.
          ["@string.escape"] = { fg = "#D7BA7D", bg = "NONE" },
          -- Go rune literals ('x') share the base `@character` group and stay
          -- the same tan as escape sequences, matching VS Code.
          ["@character"] = { fg = "#D7BA7D", bg = "NONE" },
          -- printf verbs (`%v`, `%d`, ...) come from the injected `printf`
          -- parser as the more specific `@character.printf`, which Neovim
          -- prefers over plain `@character` when present - override just
          -- this one so verbs get VS Code's light blue "variable" color
          -- without recoloring actual Go rune literals too.
          ["@character.printf"] = { fg = colors.vscLightBlue, bg = "NONE" },
          -- Same flattening problem as `@lsp.type.keyword` above: gopls
          -- reports an entire string literal as a single flat "string"
          -- semantic token with no sub-ranges for escapes/verbs, so once it
          -- attaches (a beat after Treesitter's first paint) it overwrites
          -- the `@string.escape`/`@character` coloring above right back to
          -- plain string color. Clearing it lets Treesitter's finer-grained
          -- highlighting inside the string stay visible.
          ["@lsp.type.string"] = {},
          -- The theme rainbows markdown headings by level (h1=blue,
          -- h2=orange, h3=yellow, h4=green, h5=blue, h6=pink). Make every
          -- level blue instead; inline code inside a heading is a separate
          -- injected-language capture (`@markup.raw.markdown_inline`, left
          -- untouched) so it keeps its own orange.
          ["@markup.heading.1.markdown"] = { fg = colors.vscBlue, bg = "NONE", bold = true },
          ["@markup.heading.2.markdown"] = { fg = colors.vscBlue, bg = "NONE", bold = true },
          ["@markup.heading.3.markdown"] = { fg = colors.vscBlue, bg = "NONE", bold = true },
          ["@markup.heading.4.markdown"] = { fg = colors.vscBlue, bg = "NONE", bold = true },
          ["@markup.heading.5.markdown"] = { fg = colors.vscBlue, bg = "NONE", bold = true },
          ["@markup.heading.6.markdown"] = { fg = colors.vscBlue, bg = "NONE", bold = true },
          NeoTreeGitUntracked = { fg = colors.vscGitUntracked, bg = "NONE", italic = true },
        }
      end,
    },
    -- Icons can be configured throughout the interface
    icons = {
      -- configure the loading of the lsp in the status line
      LSPLoading1 = "⠋",
      LSPLoading2 = "⠙",
      LSPLoading3 = "⠹",
      LSPLoading4 = "⠸",
      LSPLoading5 = "⠼",
      LSPLoading6 = "⠴",
      LSPLoading7 = "⠦",
      LSPLoading8 = "⠧",
      LSPLoading9 = "⠇",
      LSPLoading10 = "⠏",
    },
  },
}
