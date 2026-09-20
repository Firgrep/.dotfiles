-- Load smart-splits at startup instead of on `VeryLazy`.
--
-- The tmux side of the seamless Ctrl-hjkl navigation (see ~/.dotfiles/.tmux.conf)
-- branches on the pane-local `@pane-is-vim` option, which this plugin sets when
-- it loads and unsets when Neovim exits or suspends. Lazy-loading it leaves a
-- window during startup where tmux thinks the pane is a plain shell and steals
-- Ctrl-hjkl instead of forwarding it.

---@type LazySpec
return {
  "mrjones2014/smart-splits.nvim",
  lazy = false,
}
