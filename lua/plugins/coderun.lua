-- ~/.config/nvim/lua/plugins/coderun.lua
-- -------------------------------------------------------------------
-- 代码运行器：所有解释型语言走 bubblewrap 沙盒（默认断网），
-- 编译型语言在沙盒里编译+运行，
-- shell 类不沙盒（用户脚本常需要系统交互）。
--
-- 逃生通道（在文件里设置 vim 命令时也用得上）：
--   SANDBOX=0        完全关闭沙盒
--   SANDBOX_NET=1    保留网络（pip install / go mod tidy 等）

-- 沙盒脚本路径
local SANDBOX = vim.fn.stdpath("config") .. "/scripts/sandbox-run"

-- 包一层沙盒调用，net=true 时放开网络
local function sb(net)
  if net then
    return "SANDBOX_NET=1 " .. SANDBOX .. " "
  else
    return SANDBOX .. " "
  end
end

return {
  "CRAG666/code_runner.nvim",
  config = function()
    require("code_runner").setup({
      mode = "float",
      focus = true,
      startinsert = false,
      float = {
        border = "rounded",
        width_ratio = 0.8,
        height_ratio = 0.6,
      },

      filetype = {
        -- ============================================================
        -- Python：检测项目本地 venv，没有就退回系统 python
        -- pip install 这种走 SANDBOX_NET=1 才能联网
        -- ============================================================
        python = function()
          local cwd = vim.fn.getcwd()
          local file = vim.fn.expand("%")
          local venv_python = nil

          local venv_paths = {
            cwd .. "/.venv/bin/python",
            cwd .. "/venv/bin/python",
            cwd .. "/env/bin/python",
            vim.env.HOME .. "/.venv/bin/python",
          }
          for _, p in ipairs(venv_paths) do
            if vim.fn.executable(p) == 1 then
              venv_python = p
              break
            end
          end

          local py = venv_python or "python3"
          -- venv 路径在 cwd 里就能写，否则沙盒里可能访问不到 /home 的 venv
          -- 沙盒已 bind $HOME/.venv 只读，足够运行
          return sb(false) .. py .. " -u " .. file
        end,

        -- ============================================================
        -- JavaScript / TypeScript / Deno / Lua / Ruby / PHP / Perl
        -- ============================================================
        javascript = sb(false) .. "node " .. vim.fn.expand("%:p"),
        typescript = sb(true)  .. "deno run " .. vim.fn.expand("%:p"),
        lua        = sb(false) .. "lua " .. vim.fn.expand("%:p"),
        ruby       = sb(false) .. "ruby " .. vim.fn.expand("%:p"),
        php        = sb(false) .. "php " .. vim.fn.expand("%:p"),
        perl       = sb(false) .. "perl " .. vim.fn.expand("%:p"),

        -- ============================================================
        -- Go：go run 需要网络拉模块，开 SANDBOX_NET。
        -- 用 function（不能 string）：code_runner 对 string 条目的 expand("%:p")
        --   在 setup 时就固化成字面路径，运行时跑的就不是当前文件了。
        -- 显式 GOPATH/GOCACHE/GOMODCACHE 绝对路径：沙盒把 HOME 改成 CWD，
        --   不写死 Go 会去 $CWD 建缓存 → 每次全量重编译 + 污染项目目录。
        -- env 前缀让变量进 go 的环境（jobstart 走 shell 解析）；
        -- $file 占位符在运行时被替换为当前文件（已 shellescape）。
        go = function()
          return sb(true)
              .. "env GOPATH=" .. vim.env.HOME .. "/go "
              .. "GOCACHE=" .. vim.env.HOME .. "/.cache/go-build "
              .. "GOMODCACHE=" .. vim.env.HOME .. "/go/pkg/mod "
              .. "go run $file"
        end,

        -- ============================================================
        -- C / C++：gcc / g++ 编译并运行，全程沙盒（无网）
        -- 编译产物落沙盒 /tmp（tmpfs），不污染源码目录；
        --   旧写法 "$0_without_ext" 是 bug —— sh 把它解析成
        --   $0 + 字面量 "_without_ext"，产物名变成 hello.c_without_ext。
        -- 用 function（string 的 expand("%:p") 在 setup 时固化）。
        -- $file 运行时替换为当前文件（已 shellescape），作为 sh -c 的 $0。
        -- ============================================================
        c = function()
          return sb(false) .. "sh -c 'gcc \"$0\" -o /tmp/cr_c_out && /tmp/cr_c_out' $file"
        end,

        cpp = function()
          return sb(false) .. "sh -c 'g++ \"$0\" -o /tmp/cr_cpp_out && /tmp/cr_cpp_out' $file"
        end,

        -- ============================================================
        -- Rust：智能区分 cargo 项目 / 单文件
        --   CWD 有 Cargo.toml → cargo run（开网，可能下载依赖）
        --   否则              → rustc 单文件，产物落沙盒 /tmp 不污染项目目录
        -- 关键：沙盒把 HOME 改成 CWD，rustup/cargo 会找不到 ~/.rustup、
        --   ~/.cargo，必须显式 RUSTUP_HOME / CARGO_HOME 绝对路径，否则报
        --   "rustup could not choose a version"。
        -- 用 function（string 的 expand("%:p") 在 setup 时固化）。
        -- $file / $end 是 code_runner 占位符：$file 运行时替换为当前文件；
        --   $end 替换为空、阻止 code_runner 在命令尾追加文件名。
        -- ============================================================
        rust = function()
          local home = vim.env.HOME
          local envp = "env RUSTUP_HOME=" .. home .. "/.rustup"
              .. " CARGO_HOME=" .. home .. "/.cargo"
          if vim.fn.filereadable(vim.fn.getcwd() .. "/Cargo.toml") == 1 then
            return sb(true) .. "sh -c '" .. envp .. " cargo run' $end"
          end
          return sb(false) .. "sh -c '"
              .. envp .. " rustc \"$0\" -o /tmp/cr_rust_out && /tmp/cr_rust_out' $file"
        end,

        -- ============================================================
        -- Java：javac 编译 + java 运行
        -- ============================================================
        java = sb(false) .. "sh -c '"
               .. "javac \"$0\" && "
               .. "java \"$0_without_ext\"' " .. vim.fn.expand("%:p") .. " "
               .. vim.fn.expand("%:p:r"),

        -- ============================================================
        -- Shell：不沙盒！shell 脚本通常需要系统交互
        -- ============================================================
        sh  = "bash " .. vim.fn.expand("%:p"),
        bash = "bash " .. vim.fn.expand("%:p"),
        zsh = "zsh " .. vim.fn.expand("%:p"),
      },

      project = {
        java = {
          "cd $project &&",
          "mvn compile &&",
          "mvn exec:java",
        },
      },
    })
  end,
}
