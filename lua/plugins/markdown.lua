-- ~/.config/nvim/lua/plugins/markdown.lua
--
-- Markdown 增强栈：
--   * render-markdown.nvim —— 表格渲染、标题图标、callout、代码块边框、latex 公式
--   * peek.nvim            —— 浏览器实时预览（保留原有）
--   * 自定义快捷键 + 表格自动对齐见 lua/config/markdown.lua

-- latex 转换器：自建免 sudo shim（pylatexenc + 上下标补转），绝对路径稳妥
local latex_converter = vim.fn.expand("~/.local/share/nvim-latex/bin/latex2text")

return {
  -- ==================================================================
  -- render-markdown.nvim：表格 / latex / 标题 / callout 可视化渲染
  -- ------------------------------------------------------------------
  -- 依赖 treesitter 的 markdown / markdown_inline / latex 解析器（均已安装）
  -- ==================================================================
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      latex = {
        enabled = true,
        converter = { latex_converter },
      },
      -- 渲染的窗口模式（普通/命令/终端）
      render_modes = { "n", "c", "t" },
      -- 代码块上方显示语言图标
      code = { sign = true, style = "full" },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)

      -- 挂上 markdown 专属快捷键 + 表格自动对齐
      local md = require("config.markdown")
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("UserMarkdownEnhance", { clear = true }),
        pattern = { "markdown" },
        callback = function(args)
          md.setup(args.buf)
        end,
      })
      -- 当前 buffer 若已是 markdown（lazy 在 FileType 时才加载本插件）也补一次
      if vim.bo[0].filetype == "markdown" then
        md.setup(0)
      end
    end,
  },

  -- ==================================================================
  -- peek.nvim：在浏览器里实时预览 markdown
  --   :PeekOpen / :PeekClose / :PeekToggle
  -- ==================================================================
  {
    "toppair/peek.nvim",
    build = "deno task --quiet build:fast",
    ft = { "markdown" },
    config = function()
      local peek = require("peek")
      peek.setup()
      vim.api.nvim_create_user_command("PeekOpen", peek.open, {})
      vim.api.nvim_create_user_command("PeekClose", peek.close, {})
      vim.api.nvim_create_user_command("PeekToggle", function()
        if peek.is_open() then
          peek.close()
        else
          peek.open()
        end
      end, {})
    end,
  },
}
