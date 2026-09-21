---@type LazySpec
return {
  {
    "hafslundkraft/kubebuilder-highlight.nvim",
    ft = "go",
    opts = {
      -- Unrecognised markers into their own diagnostic namespace: quickfix,
      -- ]d, trouble.nvim. Display stays off, so nothing is drawn twice.
      diagnostics = { enabled = true },
    },
  },
}
