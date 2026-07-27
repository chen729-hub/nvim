-- ~/.config/nvim/lua/plugins/conform.lua
--
-- 格式化编排：按 filetype 跑 formatter，保存时自动格式化
-- 用最小 diff 应用格式化，不破坏 treesitter 折叠 / 光标 / 视口
-- formatter 二进制缺失时自动 fallback 到 LSP 格式化（lsp_format="fallback"）
-- 缺的 formatter 用 :Mason 装，或 pacman（见 README）

return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  opts = {
    format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "isort", "black" },
      go = { "goimports", "gofumpt" },
      rust = { "rustfmt" },
      c = { "clang-format" },
      cpp = { "clang-format" },
      sh = { "shfmt" },
      javascript = { "prettierd", "prettier", stop_after_first = true },
      typescript = { "prettierd", "prettier", stop_after_first = true },
      json = { "prettierd", "prettier", stop_after_first = true },
      yaml = { "prettierd", "prettier", stop_after_first = true },
      markdown = { "prettierd", "prettier", stop_after_first = true },
    },
  },
}
