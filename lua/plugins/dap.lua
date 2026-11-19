return {
  {
    "mfussenegger/nvim-dap",

    dependencies = {
      "williamboman/mason.nvim",
      "nvim-neotest/nvim-nio",
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "jay-babu/mason-nvim-dap.nvim",
    },

    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      ----------------------------------------------------------------
      -- 图标（Neovim 0.10+ 已废弃 vim.fn.sign_define，改用 vim.diagnostic.config）
      -- 这里继续用 sign_define 是因为 nvim-dap 自身还没有切到新 API，
      -- 这是插件内部约定，不属于"配置层废弃"。
      ----------------------------------------------------------------
      vim.fn.sign_define("DapBreakpoint", { text = "🛑", texthl = "DiagnosticSignError", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "🟡", texthl = "DiagnosticSignWarn", linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped", { text = "▶️", texthl = "DiagnosticSignInfo", linehl = "DapStoppedLine", numhl = "" })

      ----------------------------------------------------------------
      -- Python：用 mason 装好的 debugpy
      ----------------------------------------------------------------
      local mason_pkgs = vim.fn.stdpath("data") .. "/mason/packages"
      local debugpy_python = mason_pkgs .. "/debugpy/venv/bin/python"

      dap.adapters.python = {
        type = "executable",
        command = debugpy_python,
        args = { "-m", "debugpy.adapter" },
      }

      dap.configurations.python = {
        {
          type = "python",
          request = "launch",
          name = "调试当前文件",
          program = "${file}",
          pythonPath = function()
            -- 优先用当前项目的虚拟环境
            -- 注意：vim.fs.root 返回的是包含 .venv 的目录，不是 .venv 本身
            local venv = vim.env.VIRTUAL_ENV
            if not venv then
              local root = vim.fs.root(0, { ".venv", "venv", "env" })
              if root then
                -- 找出实际匹配到的那个子目录名
                for _, name in ipairs({ ".venv", "venv", "env" }) do
                  if vim.fn.isdirectory(root .. "/" .. name) == 1 then
                    venv = root .. "/" .. name
                    break
                  end
                end
              end
            end
            if venv and vim.fn.executable(venv .. "/bin/python") == 1 then
              return venv .. "/bin/python"
            end
            -- 回落到 mason debugpy venv 的 python（绝对路径）
            return debugpy_python
          end,
        },
      }
      ----------------------------------------------------------------
      -- JavaScript / TypeScript：vscode-js-debug（mason 包名 js-debug-adapter）
      -- 注意 mason-nvim-dap 只负责装包，既不提供适配器映射，也没有内置配置，
      -- 所以适配器和 launch/attach 配置都必须在这里手动写。
      -- 适配器跑的是 dapDebugServer（基于 DAP server 模式，端口由 ${port} 注入）。
      ----------------------------------------------------------------
      -- 适配器用动态函数形式：在真正启动调试会话时才解析 server 路径，
      -- 既绕开 series-server 不接受 function executable 的限制，
      -- 又能容忍 mason 包布局差异（入口可能在 js-debug/src/ 下）。
      dap.adapters["pwa-node"] = function(on_config, _)
        local root = mason_pkgs .. "/js-debug-adapter"
        local server = vim.fs.find("dapDebugServer.js", { path = root, limit = 1, type = "file" })[1]
          or root .. "/js-debug/src/dapDebugServer.js"
        on_config({
          type = "server",
          host = "localhost",
          port = "${port}",
          executable = {
            command = "node",
            args = { server, "${port}" },
          },
        })
      end

      -- JS / TS 用同一套 launch/attach；TS 多带一个 --experimental-strip-types 运行时参数
      dap.configurations.javascript = {
        {
          type = "pwa-node",
          request = "launch",
          name = "调试当前文件",
          program = "${file}",
          cwd = "${workspaceFolder}",
        },
        {
          type = "pwa-node",
          request = "attach",
          name = "附加到进程（选择进程）",
          processId = require("dap.utils").pick_process,
          cwd = "${workspaceFolder}",
        },
      }

      -- TS：用 Node v26 自带的 --experimental-strip-types 直接跑 .ts，
      -- 类型剥离不会改行号，断点即可与源码对齐；attach 与 JS 复用同一份。
      dap.configurations.typescript = {
        {
          type = "pwa-node",
          request = "launch",
          name = "调试当前文件（剥离类型）",
          program = "${file}",
          cwd = "${workspaceFolder}",
          runtimeExecutable = "node",
          runtimeArgs = { "--experimental-strip-types" },
          sourceMaps = true,
        },
        {
          type = "pwa-node",
          request = "attach",
          name = "附加到进程（选择进程）",
          processId = require("dap.utils").pick_process,
          cwd = "${workspaceFolder}",
        },
      }


      ----------------------------------------------------------------
      -- PHP：vscode-php-debug（mason 包名 php-debug-adapter）
      -- Xdebug 通过 trigger 模式连接：CLI 需要 XDEBUG_TRIGGER=1，
      -- Web 需要 XDEBUG_SESSION=1 cookie/GET 参数。
      -- 适配器是 Node.js DAP server，监听 9003 端口等 Xdebug 连入。
      ----------------------------------------------------------------
      dap.adapters.php = {
        type = "executable",
        command = "node",
        args = { mason_pkgs .. "/php-debug-adapter/extension/out/phpDebug.js" },
      }

      dap.configurations.php = {
        {
          type = "php",
          request = "launch",
          name = "调试当前文件",
          program = "${file}",
          cwd = "${fileDirname}",
          port = 9003,
          runtimeExecutable = vim.fn.expand("~/.local/bin/php"),
          runtimeArgs = { "-dxdebug.start_with_request=yes" },
        },
        {
          type = "php",
          request = "launch",
          name = "等待 Xdebug 网页调试连接",
          port = 9003,
          pathMappings = {
            ["${workspaceFolder}"] = "${workspaceFolder}",
          },
        },
      }
      ----------------------------------------------------------------
      -- C / C++ / Rust：codelldb（mason 包名 codelldb）
      -- codelldb 走 DAP server 模式：nvim-dap 拉起 adapter 进程监听端口，
      -- 再以 client 身份连进去。${port} 是 nvim-dap 在 server 模式下注入的
      -- 占位符（args 里的 ${port} 和 port 字段会被同一个空闲端口替换）。
      -- liblldb.so 由 codelldb 自带，无需额外配置。
      ----------------------------------------------------------------
      dap.adapters.codelldb = function(on_config, config)
        if config.port == nil then config.port = "${port}" end
        on_config({
          type = "server",
          host = "127.0.0.1",
          port = config.port,
          executable = {
            command = mason_pkgs .. "/codelldb/extension/adapter/codelldb",
            args = { "--port", "${port}" },
          },
        })
      end

      -- program 用 function：每次启动会话时弹输入框，默认指向当前文件去掉
      -- 后缀的同名二进制（gcc -o hello hello.c 的产物），用户可改可回车。
      ----------------------------------------------------------------
      dap.configurations.c = {
        {
          name = "调试当前文件",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input(
              "可执行文件路径：",
              vim.fn.getcwd() .. "/" .. vim.fn.expand("%:t:r"),
              "file"
            )
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = {},
        },
      }
      -- C++ 复用 C 的配置（codelldb 不区分语言，只看二进制）
      dap.configurations.cpp = dap.configurations.c

      -- Rust：crate 名未必等于文件名，先 cargo build 再调试
      -- target/debug/ 下的产物，默认提示该目录让用户补全二进制名。
      ----------------------------------------------------------------
      dap.configurations.rust = {
        {
          name = "启动调试（codelldb）",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input(
              "可执行文件路径：",
              vim.fn.getcwd() .. "/target/debug/",
              "file"
            )
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = {},
        },
      }

      ----------------------------------------------------------------
      -- Go：delve（mason 包名 delve，可执行文件 dlv）
      -- dlv dap 走 server 模式监听端口，与 codelldb 同理。
      -- program 三种：当前文件 / 当前文件测试 / 当前包。
      ----------------------------------------------------------------
      dap.adapters.delve = {
        type = "server",
        port = "${port}",
        executable = {
          command = mason_pkgs .. "/delve/dlv",
          args = { "dap", "-l", "127.0.0.1:${port}" },
        },
      }

      dap.configurations.go = {
        {
          type = "delve",
          name = "调试当前文件",
          request = "launch",
          program = "${file}",
          showLog = true,
        },
        {
          type = "delve",
          name = "调试当前文件的测试",
          request = "launch",
          mode = "test",
          program = "${file}",
          showLog = true,
        },
        {
          type = "delve",
          name = "调试当前包",
          request = "launch",
          program = "${fileDirname}",
        },
      }
      dapui.setup()
      require("nvim-dap-virtual-text").setup({
        -- PHP 的 treesitter locals query 把变量赋值归类为 reference 而非 definition，
        -- 需要打开 all_references 才能渲染普通变量
        all_references = true,
      })

      require("mason-nvim-dap").setup({
        ensure_installed = { "debugpy", "codelldb", "delve", "js-debug-adapter", "php-debug-adapter" },
        automatic_installation = true,
      })

      ----------------------------------------------------------------
      -- 快捷键已统一迁移至 lua/config/keymaps.lua
      ----------------------------------------------------------------
    end,
  },
}
