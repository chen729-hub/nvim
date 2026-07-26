-- ~/.config/nvim/lua/plugins/editor.lua
--
-- 编辑增强：Treesitter + 注释 + 自动配对 + surround
-- -------------------------------------------------------------------
-- 注意：nvim-treesitter 主分支已移除 modules（highlight/indent 等），
-- 高亮 / 缩进 / fold 由 Neovim 内建 vim.treesitter.start() 提供，
-- 解析器通过 :TSInstall / :TSUpdate 命令管理。

return {
  -- ==================================================================
  -- Treesitter：语法解析（高亮 / 缩进 / fold 的基础）
  -- ------------------------------------------------------------------
  -- 第一次启动会缺少解析器。打开任意文件后用 :TSInstall <lang> 装，
  -- 或运行 :TSUpdate 同步已声明的预装列表（lazy 也会在 build 时自动跑）。
  -- ==================================================================
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      -- 启动时给所有支持的 buffer 开 treesitter；缺解析器就静默跳过。
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("UserTreesitterStart", { clear = true }),
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
  },

  -- ==================================================================
  -- 快速注释：gcc / gc{motion}
  -- ==================================================================
  {
    "numToStr/Comment.nvim",
    lazy = false,
    config = true,
  },

  -- ==================================================================
  -- 自动配对括号 / 引号
  -- ==================================================================
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
  },

  -- ==================================================================
  -- 环绕修改：ysiw" / ds" / cs"'
  -- ==================================================================
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    config = true,
  },
}
