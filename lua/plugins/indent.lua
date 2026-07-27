-- ~/.config/nvim/lua/plugins/indent.lua
--
-- 缩进引导线（ibl v3）：用 virtual text 画缩进线，高亮当前作用域
-- scope 复用 treesitter；纯 virtual text，不影响 sign 列 / 折叠

return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    indent = { char = "┊" },
    scope = { enabled = true },
    exclude = {
      filetypes = {
        "neo-tree", "toggleterm", "TelescopePrompt", "help",
        "alpha", "dashboard", "Trouble", "spectre_panel",
      },
    },
  },
}
