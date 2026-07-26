-- ~/.config/nvim/lua/plugins/ai.lua
--
-- AI 辅助：omp (Oh My Pi) 集成
-- ------------------------------------------------------------------
-- omp.nvim 是「反向桥接」：让正在跑的 omp 终端会话实时追踪 nvim 的
-- 当前文件 / 光标行号 / 可视选区，作为隐式上下文注入到你的提问里。
-- 它本身不弹窗口、不发请求 —— 纯被动监听 CursorMoved / BufEnter。
--
-- 前置条件（已完成）：
--   1. omp 已安装在 $PATH
--   2. omp 扩展已装：omp plugin install omp.nvim
--      （扩展端在 session_start 时建 socket，把 active_file 注入 prompt）
--
-- omp 终端的启动键位与 lazygit 一并放在 lua/config/keymaps.lua，
-- 复用 toggleterm 的 Terminal:new，不引入新依赖。

return {
  -- ==================================================================
  -- omp.nvim：被动上下文桥接
  -- ------------------------------------------------------------------
  -- VeryLazy 加载：等界面起来后再挂 autocmd，避免拖慢首屏。
  -- ==================================================================
  {
    "rauls-kjarners/omp.nvim",
    event = "VeryLazy",
    config = function()
      require("omp").setup()
    end,
  },
}
