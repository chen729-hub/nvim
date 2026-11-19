-- ~/.config/nvim/lua/plugins/markdown.lua
--
-- Markdown 增强栈：
--   * render-markdown.nvim —— 表格渲染、标题图标、callout、代码块边框、latex 公式
--   * peek.nvim            —— 浏览器实时预览（保留原有）
--   * 自定义快捷键 + 表格自动对齐见 lua/config/markdown.lua

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
      {
        "bartp5/libtexprintf",
        -- 上游 utftex：由 Lazy 下载并编译，无需 sudo。
        -- 静态链接 libtexprintf，直接运行仓库内的 src/utftex。
        build = "./autogen.sh && ./configure --disable-shared && make",
      },
    },
    opts = function()
      local utftex = require("lazy.core.config").plugins.libtexprintf.dir .. "/src/utftex"
      vim.env.NVIM_MATH_UTF_TEX = utftex
      local utftex_compat = vim.fn.stdpath("config") .. "/scripts/utftex-compat"
      return {
        latex = {
          enabled = true,
          -- 优先用原生转换；仅失败的公式进入兼容处理。
          converter = { utftex, utftex_compat },
          -- 行内公式原位显示；多行块交给下面的整行替换配置。
          position = "center",
        },
        pipe_table = {
          border_virtual = true,
        },
        custom_handlers = { latex = require("config.markdown_math") },
        -- 渲染的窗口模式（普通/命令/终端）
        render_modes = { "n", "c", "t" },
        -- Mermaid 交给 Snacks；隐藏结束围栏会连带隐藏其上的图像虚拟行。
        code = {
          sign = true,
          style = "full",
          -- 隐藏结束围栏整行会让超过一屏的软换行代码卡住滚轮。
          border = "thin",
          disable = { "mermaid" },
        },
      }
    end,
    config = function(_, opts)
      require("config.markdown_tables").setup()
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
