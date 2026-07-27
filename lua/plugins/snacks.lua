-- ~/.config/nvim/lua/plugins/snacks.lua
--
-- snacks.nvim（folke QoL 合集）—— 这里只开 input 模块
-- 美化所有 vim.ui.input 浮窗（LSP 重命名 / conform 选 formatter / 任意输入框）
-- 替代已归档的 dressing.nvim（stevearc 2025-02 归档，官方推荐改用 snacks）
--
-- ⚠️ 只开 input，不开 dashboard / bigfile / statuscolumn / notifier
--    避免与已装 alpha-nvim / lualine / 自写 winbar 冲突
--    需要通知美化时取消注释 notifier 即可

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    input = { enabled = true },
    -- notifier = { enabled = true },
  },
}
