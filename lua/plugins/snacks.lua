-- ~/.config/nvim/lua/plugins/snacks.lua
--
-- snacks.nvim：输入框美化 + Kitty 图形协议图片显示
-- 美化所有 vim.ui.input 浮窗（LSP 重命名 / conform 选 formatter / 任意输入框）
-- 替代已归档的 dressing.nvim（stevearc 2025-02 归档，官方推荐改用 snacks）
--
-- 只开 input / image，不开 dashboard / bigfile / statuscolumn / notifier
--    避免与已装 alpha-nvim / lualine / 自写 winbar 冲突
--    需要通知美化时取消注释 notifier 即可

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  init = function()
    -- tmux 可能挡住终端型号探测；使用 Snacks 官方提供的环境识别开关。
    -- 仅在 Kitty 中设置，并尊重用户已经指定的值。
    if vim.env.KITTY_WINDOW_ID and vim.env.KITTY_WINDOW_ID ~= "" and vim.env.SNACKS_KITTY == nil then
      vim.env.SNACKS_KITTY = "true"
    end
    -- Mermaid CLI 独立安装，只影响 Neovim 子进程的 PATH。
    local mermaid_bin = vim.fn.stdpath("data") .. "/mermaid/node_modules/.bin"
    if vim.fn.executable(mermaid_bin .. "/mmdc") == 1
        and not vim.tbl_contains(vim.split(vim.env.PATH or "", ":", { plain = true }), mermaid_bin) then
      vim.env.PATH = mermaid_bin .. ":" .. (vim.env.PATH or "")
    end
    require("config.image_zoom").setup()
  end,
  opts = {
    input = { enabled = true },
    image = {
      enabled = true,
      doc = {
        enabled = true,
        inline = true,
        float = false,
        max_width = 80,
        max_height = 30,
        -- 默认显示图表；进入代码块时由 Snacks 自动展开源码。
        conceal = function(_, kind)
          return kind == "chart" or kind == "math"
        end,
      },
      -- 自动加载失败时显示原因，避免图片无声消失。
      convert = { notify = true },
      -- 公式继续由 render-markdown + utftex 渲染，避免重复显示。
      math = { enabled = false },
    },
    -- notifier = { enabled = true },
  },
  keys = {
    { "<leader>mi", function() require("config.image_zoom").open() end, desc = "放大查看光标处图片" },
    { "<leader>mI", function() require("config.image_zoom").close() end, desc = "关闭图片预览" },
  },
}
