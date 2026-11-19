-- ~/.config/nvim/lua/plugins/indent.lua
--
-- 缩进引导线（ibl v3）：用 virtual text 画缩进线，高亮当前作用域
-- scope 复用 treesitter；纯 virtual text，不影响 sign 列 / 折叠

return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    indent = { char = "┊", repeat_linebreak = false },
    scope = { enabled = true },
    exclude = {
      filetypes = {
        "neo-tree", "toggleterm", "TelescopePrompt", "help",
        "alpha", "dashboard", "Trouble", "spectre_panel",
      },
    },
  },
  config = function(_, opts)
    local hooks = require("ibl.hooks")
    if vim.g.user_indent_wrap_hook then hooks.clear(vim.g.user_indent_wrap_hook) end
    -- Overlay text can cover real code when smoothscroll starts inside a
    -- wrapped line. Skip guides on lines that wrap in any visible window.
    local last_tick, last_buf, width
    vim.g.user_indent_wrap_hook = hooks.register(hooks.type.SKIP_LINE, function(tick, buf, _, line)
      if tick ~= last_tick or buf ~= last_buf then
        last_tick, last_buf, width = tick, buf, nil
        for _, win in ipairs(vim.fn.win_findbuf(buf)) do
          if vim.wo[win].wrap then
            local info = vim.fn.getwininfo(win)[1]
            local available = info.width - info.textoff
            width = math.min(width or available, available)
          end
        end
      end
      return width ~= nil and vim.fn.strdisplaywidth(line) > width
    end)
    require("ibl").setup(opts)
  end,
}
