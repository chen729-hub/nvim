-- ~/.config/nvim/lua/plugins/dankcolors.lua
--
-- 自定义高亮 overlay
-- -------------------------------------------------------------------
-- 之前这里直接调 require('base16-colorscheme').setup() 设置整套 base16，
-- 但 ui.lua 里 catppuccin 又用 :colorscheme 覆盖，结果两套主题抢高亮，
-- 最终显示效果依赖 lazy 加载顺序，不稳定。
--
-- 现在改成 overlay 模式：让 catppuccin 负责整套基础主题，
-- 本文件只在 ColorScheme 触发后再覆盖几个关键高亮组，
-- 这样无论基础主题是谁，自定义配色都稳定生效。

local function apply_overlay()
  -- 编辑器 chrome
  vim.api.nvim_set_hl(0, "Visual", { bg = "#8d979f", fg = "#f5faff", bold = true })
  vim.api.nvim_set_hl(0, "LineNr", { fg = "#8d979f" })
  vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#abd9ff", bold = true })
  -- 分屏分隔线：配合 laststatus=3，在编辑器与终端/neo-tree 之间画出可见分界线
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#494e52" })

  -- 语法
  vim.api.nvim_set_hl(0, "Statement", { fg = "#7cc4ff", bold = true })
  vim.api.nvim_set_hl(0, "Keyword", { link = "Statement" })
  vim.api.nvim_set_hl(0, "Repeat", { link = "Statement" })
  vim.api.nvim_set_hl(0, "Conditional", { link = "Statement" })

  vim.api.nvim_set_hl(0, "Function", { fg = "#60b8ff", bold = true })
  vim.api.nvim_set_hl(0, "Macro", { fg = "#60b8ff", italic = true })
  vim.api.nvim_set_hl(0, "@function.macro", { link = "Macro" })

  vim.api.nvim_set_hl(0, "Type", { fg = "#abd9ff", bold = true, italic = true })
  vim.api.nvim_set_hl(0, "Structure", { link = "Type" })

  vim.api.nvim_set_hl(0, "String", { fg = "#7cff8d", italic = true })

  vim.api.nvim_set_hl(0, "Operator", { fg = "#e8f4ff" })
  vim.api.nvim_set_hl(0, "Delimiter", { fg = "#e8f4ff" })
  vim.api.nvim_set_hl(0, "@punctuation.bracket", { link = "Delimiter" })
  vim.api.nvim_set_hl(0, "@punctuation.delimiter", { link = "Delimiter" })

  vim.api.nvim_set_hl(0, "Comment", { fg = "#8d979f", italic = true })
end

return {
  {
    "RRethy/base16-nvim",
    lazy = false,
    priority = 1000,
    config = function()
      -- 任何 colorscheme 切换后（包括启动时 catppuccin 加载）都重新应用 overlay
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("DankColorsOverlay", { clear = true }),
        callback = apply_overlay,
      })

      -- 兜底：当下立刻应用一次，覆盖默认主题
      apply_overlay()
    end,
  },
}
