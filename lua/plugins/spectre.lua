-- ~/.config/nvim/lua/plugins/spectre.lua
--
-- 全工程查找 + 批量替换面板：输入正则，左侧列出所有匹配文件
-- 逐个 / 全部替换并写盘。补 telescope live_grep「只搜不换」的空白
-- 依赖 ripgrep（已装）。快捷键 <leader>sr

return {
  "nvim-pack/nvim-spectre",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = { "Spectre" },
  opts = {},
}
