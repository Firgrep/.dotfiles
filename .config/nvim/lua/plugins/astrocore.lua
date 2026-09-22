-- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!
-- Configuration documentation can be found with `:h astrocore`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

-- Jump to the closing brace of the block the cursor is currently inside
-- (or on), then open a new line right after it, indented to match that
-- closing brace's line rather than trusting filetype auto-indent (which
-- can misjudge the level right after a lone `}`).
local function exit_brace_below()
  vim.cmd "stopinsert"
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local char_here = vim.api.nvim_get_current_line():sub(col + 1, col + 1)
  if char_here ~= "}" then
    if not pcall(vim.cmd, "normal! ]}") then
      vim.cmd "startinsert"
      return
    end
    row = vim.api.nvim_win_get_cursor(0)[1]
  end
  local indent = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]:match "^%s*"
  vim.api.nvim_buf_set_lines(0, row, row, false, { indent })
  vim.api.nvim_win_set_cursor(0, { row + 1, #indent })
  vim.cmd "startinsert!"
end

-- Same idea for insert mode, but built as a returned key-sequence instead of
-- calling `:stopinsert`/`:startinsert` from Lua: those don't reliably survive
-- being invoked mid-insert-mode-processing (ends up dropping back to Normal
-- mode instead of staying in Insert). Returning keys for Neovim to play back
-- (an `expr` mapping) goes through the same native path as a plain
-- `<Esc>...gi`-style insert-mode remap, which does work.
local function exit_brace_below_keys()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local char_here = vim.api.nvim_get_current_line():sub(col + 1, col + 1)
  local jump = ""
  if char_here ~= "}" then
    row = vim.fn.searchpair("{", "", "}", "n")
    if row <= 0 then return "" end
    jump = "]}"
  end
  local indent = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]:match "^%s*"
  -- <C-u> clears whatever indent `o` auto-inserts before typing our own.
  -- Typing a throwaway space first guarantees <C-u> always has something
  -- newly-typed to delete: on a truly empty line (closing brace at column
  -- 0, so no auto-indent at all) it otherwise falls back to 'backspace'
  -- eol-joining, deleting the new line itself instead of clearing nothing.
  return "<Esc>" .. jump .. "o <C-u>" .. indent
end

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    -- Configure core features of AstroNvim
    features = {
      large_buf = { size = 1024 * 256, lines = 10000 }, -- set global limits for large files for disabling features like treesitter
      autopairs = true, -- enable autopairs at start
      cmp = true, -- enable completion at start
      diagnostics = { virtual_text = true, virtual_lines = false }, -- diagnostic settings on startup
      highlighturl = true, -- highlight URLs at start
      notifications = true, -- enable notifications at start
    },
    -- Diagnostics configuration (for vim.diagnostics.config({...})) when diagnostics are on
    diagnostics = {
      virtual_text = true,
      underline = true,
    },
    -- passed to `vim.filetype.add`
    filetypes = {
      -- see `:h vim.filetype.add` for usage
      extension = {
        foo = "fooscript",
      },
      filename = {
        [".foorc"] = "fooscript",
      },
      pattern = {
        [".*/etc/foo/.*"] = "fooscript",
      },
    },
    -- vim options can be configured here
    options = {
      opt = { -- vim.opt.<key>
        relativenumber = true, -- sets vim.opt.relativenumber
        number = true, -- sets vim.opt.number
        spell = false, -- sets vim.opt.spell
        signcolumn = "yes", -- sets vim.opt.signcolumn to yes
        wrap = false, -- sets vim.opt.wrap
        tabstop = 4, -- overrides AstroNvim's default of 2
      },
      g = { -- vim.g.<key>
        -- configure global vim variables (vim.g)
        -- NOTE: `mapleader` and `maplocalleader` must be set in the AstroNvim opts or before `lazy.setup`
        -- This can be found in the `lua/lazy_setup.lua` file
      },
    },
    -- Mappings can be configured through AstroCore as well.
    -- NOTE: keycodes follow the casing in the vimdocs. For example, `<Leader>` must be capitalized
    mappings = {
      -- first key is the mode
      n = {
        -- second key is the lefthand side of the map

        -- navigate buffer tabs
        ["]b"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
        ["[b"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },
        ["<Tab>"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
        ["<S-Tab>"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },

        -- mappings seen under group name "Buffer"
        ["<Leader>bd"] = {
          function()
            require("astroui.status.heirline").buffer_picker(
              function(bufnr) require("astrocore.buffer").close(bufnr) end
            )
          end,
          desc = "Close buffer from tabline",
        },

        -- tables with just a `desc` key will be registered with which-key if it's installed
        -- this is useful for naming menus
        -- ["<Leader>b"] = { desc = "Buffers" },

        -- setting a mapping to false will disable it
        -- ["<C-S>"] = false,

        -- move current line up/down (VS Code's Alt-Up/Alt-Down)
        ["<A-j>"] = { ":m .+1<CR>==", desc = "Move line down" },
        ["<A-k>"] = { ":m .-2<CR>==", desc = "Move line up" },

        -- jump out of the current { } block and open a line below it.
        -- <A-o> rather than <C-l>: <C-l> is smart-splits' "move to right
        -- split", which tmux also forwards here for seamless pane navigation.
        ["<A-o>"] = { exit_brace_below, desc = "Exit block, new line below" },
      },
      v = {
        -- move selected lines up/down, keeping the selection and reindenting
        ["<A-j>"] = { ":m '>+1<CR>gv=gv", desc = "Move selection down" },
        ["<A-k>"] = { ":m '<-2<CR>gv=gv", desc = "Move selection up" },
      },
      x = {
        -- paste over selection without clobbering the unnamed register
        -- (deletes the selection into the black hole register first)
        ["p"] = { '"_dP', desc = "Paste without yanking selection" },
      },
      i = {
        -- move current line up/down without leaving insert mode
        ["<A-j>"] = { "<Esc>:m .+1<CR>==gi", desc = "Move line down" },
        ["<A-k>"] = { "<Esc>:m .-2<CR>==gi", desc = "Move line up" },

        -- jump out of the current { } block and open a line below it
        ["<A-o>"] = { exit_brace_below_keys, expr = true, desc = "Exit block, new line below" },

        -- save without leaving insert mode (AstroNvim's default <C-S> is
        -- normal/visual mode only)
        ["<C-S>"] = { "<Esc><Cmd>silent! update! | redraw<CR>gi", desc = "Force write" },
      },
    },
  },
}
