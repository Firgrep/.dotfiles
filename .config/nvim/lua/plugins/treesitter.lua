-- Ensure the "printf" treesitter parser is installed. Go's own highlights
-- query injects it into Printf/Sprintf/Fatalf/Errorf/... format strings so
-- verbs like `%v` get their own highlight instead of just looking like
-- regular string text; without this parser installed, that injection is a
-- silent no-op.
---@type LazySpec
return {
  "AstroNvim/astrocore",
  opts = function(_, opts)
    opts.treesitter = opts.treesitter or {}
    local ensure_installed = opts.treesitter.ensure_installed or {}
    if not vim.tbl_contains(ensure_installed, "printf") then table.insert(ensure_installed, "printf") end
    opts.treesitter.ensure_installed = ensure_installed
    return opts
  end,
}
