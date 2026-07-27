-- ~/.config/nvim/lua/plugins/crates.lua
--
-- Cargo.toml 依赖增强：实时高亮 crate 版本、提示是否有新版
-- 一键升级版本 / 打开文档 / telescope 搜 crate
-- 仅在 Cargo.toml 生效（BufRead Cargo.toml 触发），与 rustaceanvim 天然配对

return {
  "Saecki/crates.nvim",
  tag = "stable",
  event = { "BufRead Cargo.toml" },
  config = function()
    require("crates").setup({})
    -- crates 专用 buffer-local 快捷键（仅 toml buffer 生效）
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "toml",
      group = vim.api.nvim_create_augroup("UserCratesKeys", { clear = true }),
      callback = function(args)
        local crates = require("crates")
        local opts = function(desc)
          return { buffer = args.buf, silent = true, desc = "Crates: " .. desc }
        end
        vim.keymap.set("n", "<leader>cu", crates.upgrade_crate, opts("升级当前 crate"))
        vim.keymap.set("n", "<leader>cU", crates.upgrade_all_crates, opts("升级全部 crate"))
        vim.keymap.set("n", "<leader>ch", crates.show_popup, opts("crate 详情弹窗"))
        vim.keymap.set("v", "<leader>cu", crates.upgrade_crates, opts("升级选中 crate"))
      end,
    })
  end,
}
