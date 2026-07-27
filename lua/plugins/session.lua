-- ~/.config/nvim/lua/plugins/session.lua
--
-- 会话恢复（persistence.nvim，folke 出品，LazyVim 默认）
-- 退出 nvim 自动保存窗口/缓冲布局，下次进同目录自动恢复
-- 按 git 分支区分，切分支不串台
-- 快捷键 <leader>q*，见 config/keymaps.lua

return {
  "folke/persistence.nvim",
  event = "BufReadPre",
  opts = { branch = true },
}
