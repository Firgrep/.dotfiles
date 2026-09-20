-- Formatter routing for web projects.

---@type LazySpec
return {
  "jay-babu/mason-null-ls.nvim",
  optional = true,
  opts = {
    handlers = {
      -- no-op handler: install biome, but don't register it as a none-ls source
      biome = function() end,
    },
  },
}
