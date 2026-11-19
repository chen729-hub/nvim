-- ~/.config/nvim/lua/plugins/lsp.lua
--
-- LSP + 自动补全配置
-- -------------------------------------------------------------------
-- 关键修复：
--   1. ts_ls 显式指定系统 typescript 路径，单 JS 文件不再报
--      "Could not find a valid TypeScript installation"
--   2. root_dir 兼容未保存缓冲区（无名 buffer 退回当前工作目录）
--   3. LSP 快捷键只在一处声明（这里），与 keymaps.lua 解耦

local ts_lib = "/usr/lib/node_modules/typescript/lib"

return {
  -- ==================================================================
  -- LSP 核心：lspconfig + mason + cmp-nvim-lsp
  -- ==================================================================
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },

    config = function()
      ----------------------------------------------------------------
      -- Mason：装 LSP server 二进制
      ----------------------------------------------------------------
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "pyright",
          "rust_analyzer",
          "ts_ls",
          -- gopls / clangd / bashls 用系统包管理器装的二进制：
          --   pacman -S gopls shellcheck
          --   npm install -g bash-language-server
          -- 走 PATH 调用即可，比 mason 装更稳定（避开 mason 的网络问题）
        },
      })

      ----------------------------------------------------------------
      -- 公共能力（接上 nvim-cmp）
      ----------------------------------------------------------------
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      ----------------------------------------------------------------
      -- 通用 root_dir：先找工程标记，找不到就用缓冲区所在目录，
      -- 再不行（未命名 buffer）就用当前工作目录。
      ----------------------------------------------------------------
      local function make_root_dir(markers)
        return function(bufnr, on_dir)
          local fname = vim.api.nvim_buf_get_name(bufnr)
          local root = vim.fs.root(fname, markers)
          if not root then
            if fname == "" then
              root = vim.fn.getcwd()
            else
              root = vim.fs.dirname(fname)
            end
          end
          on_dir(root)
        end
      end

      ----------------------------------------------------------------
      -- Lua
      ----------------------------------------------------------------
      vim.lsp.config("lua_ls", {
        capabilities = capabilities,
        root_dir = make_root_dir({ ".luarc.json", ".luarc.jsonc", ".git" }),
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
          },
        },
      })

      ----------------------------------------------------------------
      -- Python
      ----------------------------------------------------------------
      vim.lsp.config("pyright", {
        capabilities = capabilities,
        root_dir = make_root_dir({
          "pyproject.toml", "setup.py", "setup.cfg",
          "requirements.txt", "Pipfile", "pyrightconfig.json", ".git",
        }),
      })

      ----------------------------------------------------------------
      -- Rust：改由 rustaceanvim 直配 rust-analyzer（见 plugins/rust.lua）
      -- 这里不再走 lspconfig，避免双重 attach 冲突。
      -- mason ensure_installed 仍保留 rust_analyzer 以装二进制。
      ----------------------------------------------------------------

      ----------------------------------------------------------------
      -- JavaScript / TypeScript
      ----------------------------------------------------------------
      vim.lsp.config("ts_ls", {
        capabilities = capabilities,
        root_dir = make_root_dir({
          "tsconfig.json", "jsconfig.json", "package.json", ".git",
        }),
        -- 单文件场景必须显式告诉 server 去哪里找 tsserver，
        -- 否则它会用 mason 自带的残缺 typescript 包并直接初始化失败。
        init_options = {
          hostInfo = "neovim",
          tsserver = { path = ts_lib },
        },
        settings = {
          completions = { completeFunctionCalls = true },
        },
      })

      ----------------------------------------------------------------
      -- Go
      ----------------------------------------------------------------
      vim.lsp.config("gopls", {
        capabilities = capabilities,
        root_dir = make_root_dir({ "go.mod", "go.work", ".git" }),
        settings = {
          gopls = {
            gofumpt = true,
            staticcheck = true,
          },
        },
      })

      ----------------------------------------------------------------
      -- C / C++（用系统 clangd，比 mason 的更新）
      ----------------------------------------------------------------
      vim.lsp.config("clangd", {
        capabilities = capabilities,
        root_dir = make_root_dir({
          "compile_commands.json", "compile_flags.txt",
          ".clang-tidy", ".git",
        }),
        cmd = { "clangd", "--background-index", "--clang-tidy" },
      })

      ----------------------------------------------------------------
      -- Bash / shell
      ----------------------------------------------------------------
      vim.lsp.config("bashls", {
        capabilities = capabilities,
        root_dir = make_root_dir({ ".git", ".bashrc", ".zshrc" }),
        settings = {
          bashIde = {
            backgroundAnalysisMaxFiles = 500,
          },
        },
      })

      ----------------------------------------------------------------
      -- 启用
      vim.lsp.enable({
        "lua_ls",
        "pyright",
        "ts_ls",
        "gopls",
        "clangd",
        "bashls",
      })

      ----------------------------------------------------------------
      -- 快捷键（LspAttach 内绑定，buffer-local）
      ----------------------------------------------------------------
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(ev)
          local opts = function(desc)
            return { buffer = ev.buf, silent = true, desc = "语言服务：" .. desc }
          end

          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts("跳转到定义"))
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts("查看引用"))
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts("跳转到实现"))
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts("悬浮文档"))
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts("跳转到声明"))
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts("重命名符号"))
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts("代码操作"))
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts("上一条诊断"))
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts("下一条诊断"))
          vim.keymap.set("n", "<leader>dl", vim.diagnostic.setloclist, opts("诊断列表"))
        end,
      })
    end,
  },

  -- ==================================================================
  -- nvim-cmp：自动补全
  -- ==================================================================
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },

    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },

        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),

        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
          { name = "buffer" },
        }),
      })
    end,
  },
}
