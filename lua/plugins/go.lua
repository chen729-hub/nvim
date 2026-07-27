-- ~/.config/nvim/lua/plugins/go.lua
--
-- Go 开发增强：ray-x/go.nvim（Neovim Go 生态事实标准）
-- 提供 GoTest / GoImpl / fillstruct / GoAlt(测试↔实现) 等专用命令
--
-- 协调策略（避免与现有配置冲突）：
--   lsp_cfg = false   → gopls 仍由 lsp.lua 的 lspconfig 管理，不重复配
--   gofmt/goimports=false → 格式化交给 conform.nvim，不双重格式化
--   GoRun 不绑键       → 运行走已装的 code_runner（<leader>r = go run）
--
-- Go 专用快捷键（buffer-local，FileType go 时绑定）：
--   <leader>Gf  测试当前函数    <leader>Gt  测试当前文件
--   <leader>Gi  生成接口实现    <leader>Ga  跳到测试/实现文件

return {
  "ray-x/go.nvim",
  ft = { "go", "gomod", "gowork", "gotmpl" },
  dependencies = { "ray-x/guihua.lua", build = "make" },
  config = function()
    require("go").setup({
      lsp_cfg = false,
      lsp_gofumpt = false,
      gofmt = false,
      goimports = false,
    })
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "go",
      group = vim.api.nvim_create_augroup("UserGoKeys", { clear = true }),
      callback = function(args)
        local opts = function(desc)
          return { buffer = args.buf, silent = true, desc = "Go: " .. desc }
        end
        vim.keymap.set("n", "<leader>Gf", "<cmd>GoTestFunc<CR>", opts("测试当前函数"))
        vim.keymap.set("n", "<leader>Gt", "<cmd>GoTest<CR>", opts("测试当前文件"))
        vim.keymap.set("n", "<leader>Gi", "<cmd>GoImpl<CR>", opts("生成接口实现"))
        vim.keymap.set("n", "<leader>Ga", "<cmd>GoAlt<CR>", opts("跳到测试/实现"))
      end,
    })
  end,
}
