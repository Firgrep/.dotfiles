-- Parsers that need to be installed explicitly rather than left to
-- `auto_install`, which only fires once a matching buffer happens to be
-- opened - and silently leaves everything treesitter-based (highlighting,
-- rainbow-delimiters, textobjects) off until it does.
--
-- * printf: Go's own highlights query injects it into Printf/Sprintf/
--   Fatalf/Errorf/... format strings so verbs like `%v` get their own
--   highlight instead of just looking like regular string text; without this
--   parser installed, that injection is a silent no-op.
-- * javascript/typescript/tsx: rainbow-delimiters ships queries for these
--   (tsx inherits typescript inherits javascript), so bracket-pair coloring
--   in .ts/.tsx only works once the parsers are actually present.
---@type LazySpec
return {
  "AstroNvim/astrocore",
  opts = function(_, opts)
    opts.treesitter = opts.treesitter or {}
    local ensure_installed = opts.treesitter.ensure_installed or {}
    for _, parser in ipairs { "printf", "javascript", "typescript", "tsx" } do
      if not vim.tbl_contains(ensure_installed, parser) then table.insert(ensure_installed, parser) end
    end
    opts.treesitter.ensure_installed = ensure_installed
    return opts
  end,
}
