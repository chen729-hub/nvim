-- ~/.config/nvim/lua/plugins/todo.lua
--
-- 高亮 TODO / FIXME / BUG / HACK / NOTE / WARNING 注释
-- <leader>st 用 telescope 搜全工程待办，与 trouble 联动形成待办视图

return {
  "folke/todo-comments.nvim",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = { signs = false },
}
