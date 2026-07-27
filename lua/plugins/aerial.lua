-- ~/.config/nvim/lua/plugins/aerial.lua
--
-- 代码大纲：实时符号树（函数 / 类 / 变量），点击跳转
-- 优先 treesitter、回退 LSP，覆盖 50+ 语言（含 C/Go/Rust/Lua/Python）
-- 快捷键 <leader>o 切换大纲，<leader>fs telescope 选符号

return {
  "stevearc/aerial.nvim",
  cmd = { "AerialToggle", "AerialOpen" },
  opts = {
    layout = { default_direction = "right", width = 30 },
    -- 优先 treesitter（已装解析器），无则回退 LSP
    backends = { "treesitter", "lsp" },
  },
}
