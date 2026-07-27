-- ~/.config/nvim/lua/plugins/motion.lua
--
-- flash.nvim：带标签的瞬时跳转
-- 按 s + 两字符即可跳到屏幕任意匹配处（贴标签一键选）
-- 占用 s / S（vim 的 s 替换字符基本没人用，可用 cl 替代）
-- <C-s> 在 / 搜索时切换 flash 高亮增强

return {
  "folke/flash.nvim",
  event = "VeryLazy",
  opts = {},
  keys = {
    { "s",     mode = { "n", "x", "o" }, function() require("flash").jump() end,         desc = "Flash：跳转" },
    { "S",     mode = { "n", "x", "o" }, function() require("flash").treesitter() end,   desc = "Flash：选 treesitter 节点" },
    { "<c-s>", mode = { "c" },           function() require("flash").toggle() end,       desc = "Flash：切换搜索高亮" },
  },
}
