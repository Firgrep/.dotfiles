-- Local checkout, not a GitHub URL, because the repo is not pushed yet.
-- Once it is, swap `dir` for "hafslundkraft/kubebuilder-highlight.nvim".

---@type LazySpec
return {
  {
    dir = "~/dev/work/kubebuilder-highlight.nvim",
    ft = "go",
    opts = {
      -- Unrecognised markers into their own diagnostic namespace: quickfix,
      -- ]d, trouble.nvim. Display stays off, so nothing is drawn twice.
      diagnostics = { enabled = true },
    },
  },
}
