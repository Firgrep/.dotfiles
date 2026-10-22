-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- An LSP rename (`grn`, `<Leader>lr`) edits every file that references the
-- symbol, but leaves the touched ones as unsaved hidden buffers. Save them all
-- right after the rename's edits are applied. This is done by wrapping
-- `vim.lsp.buf.rename`, so every mapping that calls it picks it up.
local rename = vim.lsp.buf.rename
vim.lsp.buf.rename = function(new_name, opts)
  local function run(name)
    local apply = vim.lsp.util.apply_workspace_edit
    local function restore() vim.lsp.util.apply_workspace_edit = apply end
    vim.lsp.util.apply_workspace_edit = function(...)
      restore()
      local result = apply(...)
      vim.cmd "silent! wall"
      return result
    end
    -- don't leave the wrapper behind if the server never answers or errors
    vim.defer_fn(restore, 10000)
    rename(name, opts)
  end

  if new_name then return run(new_name) end
  -- prompt here (not inside `rename`) so cancelling never arms the wrapper
  vim.ui.input({ prompt = "New Name: ", default = vim.fn.expand "<cword>" }, function(name)
    if name and name ~= "" then run(name) end
  end)
end
