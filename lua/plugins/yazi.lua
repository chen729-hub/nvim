-- ~/.config/nvim/lua/plugins/yazi.lua
--
-- yazi.nvim：在 nvim 里用浮窗打开 yazi 文件管理器
-- -------------------------------------------------------------------
-- 主要功能：
--   * <leader>-  在当前文件位置打开 yazi（最常用）
--   * <leader>cw 在 nvim 工作目录打开 yazi
--   * <C-Up>     恢复上一次 yazi 会话
-- 选中的文件会用 nvim 当前 buffer 打开；多选文件可发送到 quickfix。
-- 删除/重命名/移动文件时，nvim 里已打开的 buffer 会自动同步。

return {
  {
    "mikavilpas/yazi.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = {
      { "nvim-lua/plenary.nvim", lazy = true },
    },
    keys = {
      -- 在当前文件所在目录打开 yazi，光标停在当前文件上
      {
        "<leader>-",
        mode = { "n", "v" },
        "<cmd>Yazi<cr>",
        desc = "Yazi: 在当前文件位置打开",
      },
      -- 在 nvim 工作目录打开 yazi
      {
        "<leader>fw",
        "<cmd>Yazi cwd<cr>",
        desc = "Yazi: 在 nvim 工作目录打开",
      },
      -- 恢复上次 yazi 会话（不重新加载）
      {
        "<leader>fo",
        "<cmd>Yazi toggle<cr>",
        desc = "Yazi: 恢复上次会话",
      },
    },
    ---@type YaziConfig | {}
    opts = {
      -- 不劫持 netrw（你已经用 neo-tree 了，保留两套）
      open_for_directories = false,
      -- 浮窗里按 <F1> 看完整快捷键
      keymaps = {
        show_help = "<f1>",
      },
      -- 浮窗样式：圆角、缩放 0.9
      floating_window_scaling_factor = 0.9,
      -- winblend 必须 0：yazi 浮窗是 terminal buffer（jobstart term=true），
      -- yazi 的选中行高亮靠转义序列实时画进去。winblend>0 会触发 nvim 对
      -- 浮窗做伪透明颜色混合，terminal buffer 的高频重绘 + 混合 = 选中行
      -- 残影/错位，表现为移动光标时文件名变乱。yazi.nvim 默认就是 0。
      -- （半透明只对普通文本 buffer 有效，terminal TUI 用不了。）
      yazi_floating_window_winblend = 0,
    },
  },
}
