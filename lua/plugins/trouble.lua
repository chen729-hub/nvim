-- ~/.config/nvim/lua/plugins/trouble.nvim
--
-- 统一面板：diagnostics / LSP references / quickfix 集中展示
-- 取代散落的 location list，体验质的飞跃
-- 快捷键 <leader>xx / xX / cs，见 config/keymaps.lua

return {
  "folke/trouble.nvim",
  cmd = { "Trouble" },
  opts = {},
}
