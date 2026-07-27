-- ~/.config/nvim/lua/plugins/gitsigns.lua
--
-- Git 行内集成：sign 列标记增删改、hunk 操作、行内 blame
-- 快捷键 <leader>h* (hunk)，见 config/keymaps.lua
-- 不与 lazygit（<leader>g 浮动 TUI）冲突：gitsigns 管缓冲区内细粒度操作

return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    current_line_blame = true,
    current_line_blame_opts = { delay = 200, virt_text_pos = "eol" },
  },
}
