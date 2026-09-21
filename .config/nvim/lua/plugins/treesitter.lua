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
