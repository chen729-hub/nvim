-- ~/.config/nvim/lua/plugins/ui.lua

return {
  -- 状态栏
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = true,
  },

  -- 顶部标签页：改用自写的 per-window winbar（见 lua/config/winbar.lua）。
  -- bufferline 是全局 tabline，分屏 / neo-tree 上方也会被占住，不合需求。
  -- { "akinsho/bufferline.nvim", ... },

  -- 方式一：仅安装 bufremove 模块（推荐）
 {
    'nvim-mini/mini.bufremove',
    version = false,  -- 使用 main 分支，获取最新更新
    config = function()
        -- 可选：设置静默模式，关闭非错误提示
        require('mini.bufremove').setup({
            silent = true,  -- 删除时不显示 "[Deleted]" 等信息
        })
    end,
  },

  -- 启动仪表盘
 {
  "goolord/alpha-nvim",
  event = "VimEnter",
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    -- 加载临时文件功能
    require("config.tempfile").setup()

    -- ========== 1. ASCII 艺术标题 ==========
    dashboard.section.header.val = {
      "                      ,----,             ,---,                                            ",
      "                    .'   .`|          ,`--.' |                                     ____   ",
      "    ,----..      .'   .'   ; ,----..  |   :  :                      ,---,        ,'  , `. ",
      "   /   /   \\   ,---, '    .'/   /   \\ |   |  '              ,---.,`--.' |     ,-+-,.' _ | ",
      "  |   :     :  |   :     ./|   :     :'   :  |             /__./||   :  :  ,-+-. ;   , || ",
      "  .   |  ;. /  ;   | .'  / .   |  ;. /;   |.'.--.--.  ,---.;  ; |:   |  ' ,--.'|'   |  ;| ",
      "  .   ; /--`   `---' /  ;  .   ; /--` '---' /  /    '/___/ \\  | ||   :  ||   |  ,', |  ': ",
      "  ;   | ;        /  ;  /   ;   | ;         |  :  /`./\\   ;  \\ ' |'   '  ;|   | /  | |  || ",
      "  |   : |       ;  /  /    |   : |         |  :  ;_   \\   \\  \\: ||   |  |'   | :  | :  |, ",
      "  .   | '___   /  /  /     .   | '___       \\  \\    `. ;   \\  ' .'   :  ;;   . |  ; |--'  ",
      "  '   ; : .'|./__;  /      '   ; : .'|       `----.   \\ \\   \\   '|   |  '|   : |  | ,     ",
      "  '   | '/  :|   : /       '   | '/  :      /  /`--'  /  \\   `  ;'   :  ||   : '  |/      ",
      "  |   :    / ;   |/        |   :    /      '--'.     /    :   \\ |;   |.' ;   | |`-'       ",
      "   \\   \\ .'  `---'          \\   \\ .'         `--'---'      '---\" '---'   |   ;/           ",
      "    `---`                    `---`                                       '---'            ",
    }
    -- 重要：将标题绑定到 AlphaHeader 高亮组
    dashboard.section.header.opts.hl = "AlphaHeader"

    -- ========== 2. 落款（单独成组，绑定 AlphaText） ==========
    dashboard.section.footer = {
      type = "group",
      val = {
        { type = "text", val = "", opts = { hl = "AlphaText" } },
        { type = "text", val = "    -- by C7C", opts = { hl = "AlphaText" } },
        { type = "text", val = "", opts = { hl = "AlphaText" } },
      },
    }

    -- ========== 3. 定义颜色高亮 ==========
    -- 标题颜色
    vim.api.nvim_set_hl(0, 'AlphaHeader', { fg = '#D79921' })  -- 金黄色
    -- 落款颜色
    vim.api.nvim_set_hl(0, 'AlphaText', { fg = '#98971A' })    -- 草绿色
    -- 按钮颜色（让按钮也变色）
    vim.api.nvim_set_hl(0, 'AlphaButtons', { fg = '#83A598' })     -- 按钮主文字色（浅青绿）
    vim.api.nvim_set_hl(0, 'AlphaShortcut', { fg = '#FB4934' })    -- 快捷键字母色（红橙色）
    vim.api.nvim_set_hl(0, 'AlphaButtonText', { fg = '#FABD2F' })  -- 按钮说明文字色（琥珀色）

    -- ========== 4. 按钮配置 ==========
    dashboard.section.buttons.val = {
        dashboard.button("f", "󰈞  查找文件", "<cmd>Telescope find_files<CR>"),
        dashboard.button("r", "  最近文件", "<cmd>Telescope oldfiles<CR>"),
        dashboard.button("p", "  项目列表", "<cmd>ProjectMgr<CR>"),  -- 新增的工程项目选项
        dashboard.button("t", "󰈔  临时文件", "<cmd>TempFile<CR>"),
        dashboard.button("c", "  配置", "<cmd>e $MYVIMRC<CR>"),
        dashboard.button("q", "󰠚  退出", "<cmd>qa<CR>"),
}
    alpha.setup(dashboard.config)
  end,
 },


-- 快捷键提示
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = true,
  },

  -- 主题（例如 catppuccin）
  -- transparent_background：让 Normal 等背景透明，
  -- 露出 kitty 的 background_opacity（0.8）与 niri 的模糊（blur.kdl）。
  -- 不开它，实色 bg 会盖死 kitty 的半透明，背景就是纯黑。
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        transparent_background = true,
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },
}
