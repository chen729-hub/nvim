-- ~/.config/nvim/lua/plugins/rust.lua
--
-- Rust 开发增强：rustaceanvim（rust-tools.nvim 官方继任者）
-- 自动配置 rust-analyzer 内置 LSP（不依赖 lspconfig），提供：
--   expand macro / view IR / open Cargo.toml / fly check / runnables / debuggables
--
-- ⚠️ 与 lspconfig 的 rust_analyzer 冲突：已在 lsp.lua 移除 rust_analyzer 的
--    vim.lsp.config / vim.lsp.enable（保留 mason ensure_installed 装二进制）
-- 调试走 nvim-dap（codelldb，已在 dap.lua 配好），<leader>Rd 选 debuggables
--
-- Rust 专用快捷键（buffer-local，rust-analyzer on_attach 内绑定）：
--   <leader>Rm  展开宏        <leader>Rr  可运行项
--   <leader>Rd  可调试项      <leader>Rc  fly check
-- 通用 LSP 键（gd/K/gr/ca 等）由 lsp.lua 的 LspAttach 统一绑定，对 rust 同样生效

return {
  "mrcjkb/rustaceanvim",
  version = "^8",   -- ^8 兼容 Nvim 0.11；最新主线需 0.12
  lazy = false,     -- init 设 vim.g.rustaceanvim 必须早加载
  init = function()
    vim.g.rustaceanvim = {
      server = {
        on_attach = function(_, bufnr)
          local opts = function(desc)
            return { buffer = bufnr, silent = true, desc = "Rust: " .. desc }
          end
          vim.keymap.set("n", "<leader>Rm", function() vim.cmd.RustLsp("expandMacro") end, opts("展开宏"))
          vim.keymap.set("n", "<leader>Rr", function() vim.cmd.RustLsp("runnables") end, opts("可运行项"))
          vim.keymap.set("n", "<leader>Rd", function() vim.cmd.RustLsp("debuggables") end, opts("可调试项"))
          vim.keymap.set("n", "<leader>Rc", function() vim.cmd.RustLsp("flyCheck") end, opts("fly check"))
        end,
      },
      dap = {},
    }
  end,
}
