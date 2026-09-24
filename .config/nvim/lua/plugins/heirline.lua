local function project_relative_dir()
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == "" then return "" end
  local dir = vim.fn.fnamemodify(vim.fn.fnamemodify(filepath, ":."), ":h")
  return dir == "." and "" or dir .. "/"
end

local statusline_path = {
  condition = function() return require("astroui.status.condition").is_file(0) and project_relative_dir() ~= "" end,
  provider = function()
    return require("astroui.status.utils").stylize(project_relative_dir(), { padding = { left = 1, right = 1 } })
  end,
  hl = { fg = "fg", bg = "bg" },
  update = { "BufEnter", "BufFilePost", "DirChanged" },
}

---@type LazySpec
return {
  "rebelot/heirline.nvim",
  opts = function(_, opts)
    -- insert the path component between mode() and git_branch()
    table.insert(opts.statusline, 2, statusline_path)
    -- drop the mirrored mode() indicator AstroNvim tacks on at the far
    -- right of the statusline; the one on the left is enough
    table.remove(opts.statusline)
    return opts
  end,
}
