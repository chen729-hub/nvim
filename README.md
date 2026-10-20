# Neovim 配置

一套面向 Arch Linux + 多语言开发个人 Neovim 配置，基于 **lazy.nvim** 全懒加载架构，用 **bubblewrap 沙盒**安全地一键运行任意语言的代码。

> Leader 键 = `空格`。所有 `<leader>` 快捷键按下后等 `which-key` 弹出菜单（400ms）即可看到全部子项，无需死记。

---

## 特色

- **沙盒化代码运行**：`<leader>r` 一键运行当前文件。解释型/编译型语言全部走 `bubblewrap` 沙盒默认断网，编译产物落 `/tmp` 不污染项目目录；`SANDBOX=0` 关沙盒、`SANDBOX_NET=1` 放开网络。
- **7 语言 LSP**：Lua / Python / Rust / JS·TS / Go / C·C++ / Bash，统一 `vim.lsp.config` 新 API 配置，root_dir 自动识别工程标记。
- **多语言 DAP 调试**：Python (debugpy)、JS/TS (vscode-js-debug)、PHP (vscode-php-debug)、C·C++·Rust (codelldb)、Go (delve)，断点 / 单步 / 变量监视齐全。
- **智能 code runner**：自动检测项目 `.venv`、区分 Cargo 项目与单文件 Rust、为 Go/Rust 显式注入绝对路径缓存目录避免沙盒里全量重编译。
- **per-window winbar**：每个窗口顶部一条独立标签栏（取代全局 bufferline），按窗口显示 buffer 顺序。
- **自定义 dms 主题**：`colors/dms.lua` + 配套 lualine 主题，另内置 catppuccin / base16 备选。
- **treesitter 折叠**：折叠后显示首行内容 + 行数；`zM`/`zR`/`<leader>zz` 全套折叠键。
- **AI / Git TUI 集成**：`<leader>ao` 右侧分栏常驻 omp 会话（自动同步当前文件/光标/选区），`<leader>g` 浮动 lazygit。
- **Git / 格式化 / 诊断 全家桶**：gitsigns 行内 hunk 操作（`<leader>h*`）、conform 保存即格式化（最小 diff 不破坏折叠）、trouble 诊断面板（`<leader>xx`）、spectre 全工程替换（`<leader>sr`）。
- **flash 秒级光标跳转**：`s` + 两字符贴标签跳屏上任意处，LazyVim 默认方案。
- **aerial 代码大纲 + 会话恢复**：`<leader>o` 实时符号树，persistence 按分支记忆窗口布局（`<leader>q*`）。
- **语言深耕**：Rust 走 rustaceanvim（展开宏 / fly check，`<leader>R*`）+ crates.nvim 版本提示；Go 走 go.nvim（GoTest / GoImpl，`<leader>G*`）。
- **零硬编码路径**：所有 mason / stdpath 走动态解析，换机器即用。

---

## 目录结构

```
~/.config/nvim/
├── init.lua                 # 入口：设 leader → 加载 options/keymaps → 启动 lazy.nvim
├── lazy-lock.json           # 插件版本锁（= 你的插件列表，必提交）
├── colors/dms.lua           # 自定义配色
├── scripts/sandbox-run      # bubblewrap 沙盒包装脚本
└── lua/
    ├── config/
    │   ├── options.lua      # 纯选项（缩进/折叠/状态栏/剪贴板…）
    │   ├── keymaps.lua      # 全局快捷键集中管理
    │   ├── keypanel.lua     # which-key 备忘板
    │   ├── winbar.lua       # per-window 标签栏
    │   ├── autoreload.lua   # 配置热重载
    │   ├── tempfile.lua     # 临时文件 / F2 另存为
    │   └── markdown.lua
    ├── lualine/themes/dms.lua
    └── plugins/             # 每个文件一类插件
        ├── lsp.lua          # LSP + nvim-cmp 自动补全
        ├── dap.lua          # 调试适配器（Python/JS-TS/PHP/C·Cpp·Rust/Go）
        ├── coderun.lua      # code_runner 沙盒配置
        ├── editor.lua       # treesitter / surround / autopairs / comment
        ├── ui.lua           # lualine / alpha / which-key / neo-tree
        ├── tools.lua        # telescope(+fzf/ui-select 扩展) / toggleterm / yazi
        ├── projects.lua     # project.nvim
        ├── markdown.lua     # render-markdown / peek
        ├── ai.lua           # omp.nvim 桥接
        ├── dankcolors.lua
        # —— 本轮新增（开发刚需 + 语言深耕）——
        ├── gitsigns.lua     # Git 行内 hunk 操作
        ├── conform.lua      # 格式化编排（保存即格式化）
        ├── indent.lua       # 缩进引导线 (ibl)
        ├── motion.lua       # flash 光标跳转
        ├── trouble.lua      # 诊断面板
        ├── todo.lua         # TODO/FIXME 高亮
        ├── session.lua      # persistence 会话恢复
        ├── spectre.lua      # 全工程查找替换
        ├── aerial.lua       # 代码大纲
        ├── snacks.lua       # vim.ui.input 美化
        ├── rust.lua         # rustaceanvim（Rust 增强）
        ├── crates.lua       # Cargo.toml 版本提示
        └── go.lua           # go.nvim（Go 增强）
```

---

## 环境要求

### 必需

| 依赖 | 用途 | Arch 安装 |
|---|---|---|
| **Neovim ≥ 0.11** | 用了 `vim.lsp.config` / `vim.lsp.enable` 新 API | `pacman -S neovim` |
| **git** | lazy.nvim 拉插件 | `pacman -S git` |
| **bubblewrap** | code_runner 沙盒（核心） | `pacman -S bubblewrap` |
| **ripgrep** | Telescope live_grep | `pacman -S ripgrep` |
| **lazygit** | `<leader>g` 浮动 TUI | `pacman -S lazygit` |
| **Nerd Font** | 文件树 / 状态栏图标 | 自行安装（如 `ttf-jetbrains-mono-nerd`） |
| **剪贴板工具** | `+` 寄存器 | `pacman -S xclip` 或 `wl-clipboard` |

### 语言运行时与 LSP（按需）

code_runner 一键运行 + LSP 都依赖系统 PATH 里的二进制：

| 语言 | 运行 | LSP server | 安装 |
|---|---|---|---|
| Lua | `lua` | `lua_ls`（mason 自动装） | `pacman -S lua` |
| Python | `python3`（自动找 `.venv`） | `pyright`（mason） | `pacman -S python` |
| Rust | `rustc` / `cargo` | `rust_analyzer`（mason） | `pacman -S rustup` |
| JS / TS | `node` / `deno` | `ts_ls`（mason，需系统 typescript） | `pacman -S nodejs deno npm` + `npm i -g typescript` |
| Go | `go run` | `gopls`（系统装更稳） | `pacman -S go gopls` |
| C / C++ | `gcc` / `g++` | `clangd`（系统装更稳） | `pacman -S gcc clang` |
| Bash | `bash` | `bashls` | `npm i -g bash-language-server` |
| Java | `javac` / `java` | — | `pacman -S jdk-openjdk` |
| Ruby / PHP / Perl | 对应解释器 | — | 按需 |

### 可选

- **omp** — AI 辅助（`<leader>ao`）。装好后运行 `omp plugin install omp.nvim`。
- **yazi** — 终端文件管理器（yazi.nvim 依赖）。
- **shellcheck** — bashls 静态检查推荐。

---

## 快速开始

```bash
# 1. 备份旧配置（如有）
mv ~/.config/nvim ~/.config/nvim.bak

# 2. 克隆本仓库
git clone <仓库地址> ~/.config/nvim

# 3. 打开 nvim —— lazy.nvim 会自动 bootstrap 并按 lazy-lock.json 装齐全部插件
nvim
```

首次启动会花一会儿拉插件；mason 也会自动安装 `lua_ls` / `pyright` / `rust_analyzer` / `ts_ls` 及 DAP 调试器。之后启动即用。

> 同步到新机器后想锁定插件版本？`lazy-lock.json` 已经在仓库里，直接打开 nvim 就会按锁文件恢复，无需额外操作。更新插件用 `:Lazy sync`。

---

## 快捷键速查

### 通用

| 按键 | 功能 |
|---|---|
| `<C-s>` | 保存（n/i/v 全模式） |
| `<C-a>` | 全选 |
| `<C-c>` / `<C-v>` / `<C-x>` | 复制 / 粘贴 / 剪切（系统剪贴板） |
| `<C-z>` | 智能撤销 |
| `<F2>` | 另存为 |
| `Q` / `:Q` | 强制退出所有窗口（一键回终端） |

### 选择

| 按键 | 功能 |
|---|---|
| `vv` / `vw` | 选当前行 / 当前词 |
| `v'` `v"` `v(` `v{` | 选对应配对符内的文本 |

### 文件 / 窗口

| 按键 | 功能 |
|---|---|
| `<leader>e` | 切换 Neo-tree 文件树 |
| `<C-h>` / `<C-l>` | 跳文件树 / 跳编辑区 |
| `<leader>wv` / `ws` / `wc` | 垂直 / 水平分屏 / 关闭 |
| `<leader>wh/j/k/l` | 在窗口间移动 |

### 查找（Telescope）

| 按键 | 功能 |
|---|---|
| `<leader>ff` | 查找文件 |
| `<leader>fg` | 实时全局搜索（需 ripgrep） |
| `<leader>fb` | 切换 buffer |
| `<leader>fh` | 帮助标签 |

### Buffer

| 按键 | 功能 |
|---|---|
| `<A-d>` | 关闭当前 buffer |
| `<A-h>` / `<A-l>` | 左 / 右切 buffer |

### 终端

| 按键 | 功能 |
|---|---|
| `<C-\>` | 浮动终端（ToggleTerm） |
| `<Esc><Esc>` | 终端模式回普通模式 |

### 代码运行

| 按键 | 功能 |
|---|---|
| `<leader>r` | 运行当前文件（沙盒） |
| `<leader>rp` | 运行项目 |
| `<leader>rc` | 关闭运行窗口 |

### 调试（DAP）

| 按键 | 功能 |
|---|---|
| `<leader>b` | 切换断点 |
| `<F5>` | 继续 |
| `<F10>` / `<F11>` / `<F12>` | 单步跨过 / 进入 / 跳出 |
| `<leader>du` | 切换 DAP UI |

### LSP（buffer-local，LspAttach 时绑定）

| 按键 | 功能 |
|---|---|
| `gd` / `gr` / `gi` / `gD` | 定义 / 引用 / 实现 / 声明 |
| `K` | 悬浮文档 |
| `<leader>rn` | 重命名符号 |
| `<leader>ca` | Code Action |
| `[d` / `]d` | 上 / 下一条诊断 |
| `<leader>dl` | 诊断列表 |

### 折叠

| 按键 | 功能 |
|---|---|
| `<leader>zz` | 切换当前块 |
| `<leader>zM` / `zR` | 全部折叠 / 展开 |

### AI / Git

| 按键 | 功能 |
|---|---|
| `<leader>ao` | 切换 omp 终端（自动同步上下文） |
| `<leader>g` | 浮动 lazygit |

---

## 沙盒代码运行器说明

`scripts/sandbox-run` 用 `bwrap` 把运行环境隔离在「当前目录 + 只读系统」里，默认断网。

| 环境变量 | 效果 |
|---|---|
| `SANDBOX=0` | 完全关闭沙盒 |
| `SANDBOX_NET=1` | 保留网络（`pip install` / `go mod tidy` / `cargo run` 拉依赖） |

各语言默认策略：
- **shell 类**（bash/zsh/sh）不沙盒 —— 脚本常需系统交互。
- **Go / Rust(cargo)** 默认开网（拉依赖），并显式注入 `$HOME` 下的缓存绝对路径，否则沙盒改了 HOME 会触发全量重编译。
- **C / C++ / Rust(单文件)** 编译产物落 `/tmp`，不污染源码目录。
- **Python** 自动探测 `.venv` / `venv` / `env` / `~/.venv`。

---

## 代码调试（DAP）说明

基于 **nvim-dap** + **nvim-dap-ui**，断点 / 单步 / 变量监视 / 调用栈齐全。所有调试器由 mason 自动安装，无需手动配置。

### 支持语言

| 语言 | 调试器（adapter） | 安装方式 |
|---|---|---|
| Python | debugpy | mason 自动 |
| JS / TS | vscode-js-debug | mason 自动 |
| PHP | vscode-php-debug | mason 自动 |
| C / C++ / Rust | codelldb（LLDB） | mason 自动 |
| Go | delve（dlv dap） | mason 自动 |

### 关键区别：谁需要先手动编译？

| 调试器 | 自动编译 | 说明 |
|---|---|---|
| delve（Go） | ✅ 会 | 打开 `.go` 文件直接 `<F5>`，delve 自己编译 |
| codelldb（C/C++/Rust） | ❌ 不会 | codelldb 只管调试，编译要你自己来 |

### 各语言用法

**Go（最省心）** —— 打开 `.go` 文件 → `<leader>b` 打断点 → `<F5>`，菜单选一种：
- `Debug (current file)` — 调试当前文件
- `Debug test (current file)` — 调试当前文件的 `*_test.go`
- `Debug (current package)` — 调试整个包

**C / C++** —— 先手动编译出带调试信息的二进制（codelldb 不会帮你编）：
```bash
gcc -g -O0 hello.c -o hello      # -g 保留调试信息；-O0 关优化避免断点漂移、变量被优化掉
```
打开 `hello.c` → `<leader>b` 打断点 → `<F5>` → 弹出输入框（已预填 `<当前目录>/hello`）→ 回车。

**Rust** —— 先 `cargo build`（debug profile 默认带调试信息，无需额外参数）：
```bash
cargo build
```
打开 `.rs` 文件 → `<leader>b` 打断点 → `<F5>` → 输入框默认填 `target/debug/`，补上 crate 名（见 `Cargo.toml` 的 `[package].name`）→ 回车。

> C/Rust 调试前务必用 `-g`（Rust debug profile 自带）编译，否则断点对不上行号、变量被优化掉。

---

## Git / 格式化 / 诊断 / 编辑增强（新增）

本轮新增 15 个插件，补齐开发刚需（Git 集成 / 格式化 / 缩进线 / 诊断面板 / 光标跳转等）和语言深耕（Rust / Go）。

| 插件 | 功能 | 快捷键 |
|---|---|---|
| **gitsigns.nvim** | 行内 git sign / hunk 暂存回退 / 行 blame | `<leader>hs` 暂存 · `<leader>hr` 回退 · `<leader>hp` 预览 · `<leader>hb` blame · `]h`/`[h` 跳 hunk |
| **conform.nvim** | 保存即格式化（最小 diff，不破坏折叠） | 自动 `<leader>cf` 手动格式化 |
| **indent-blankline.nvim** | 缩进引导线 + 当前作用域高亮 | 自动生效，无需绑键 |
| **flash.nvim** | 贴标签瞬时跳转屏上任意处 | `s` + 两字符 · `S` 选 treesitter 节点 |
| **trouble.nvim** | 诊断 / 引用 / quickfix 统一面板 | `<leader>xx` 全工程 · `<leader>xX` 当前 buffer · `<leader>cs` 引用 |
| **telescope-fzf-native** | C 版高速模糊排序器 | 自动生效 |
| **telescope-ui-select** | code action / 重命名走 telescope 浮窗 | 自动接管 `vim.ui.select` |
| **todo-comments.nvim** | 高亮 TODO/FIXME/BUG + 全工程搜索 | `<leader>st` |
| **persistence.nvim** | 按分支记忆窗口/缓冲布局 | `<leader>qs` 恢复 · `<leader>qS` 选择 · `<leader>ql` 上次 |
| **nvim-spectre** | 全工程查找 + 批量替换面板 | `<leader>sr` 全工程 · `<leader>sow` 当前文件 |
| **aerial.nvim** | 实时符号树大纲（treesitter+LSP） | `<leader>o` 切换 · `<leader>fs` telescope 选符号 |
| **snacks.nvim** | 美化 `vim.ui.input` 输入框（替代 dressing） | 自动接管 |
| **rustaceanvim** | Rust 增强：展开宏 / fly check / runnables | `<leader>Rm` 宏 · `<leader>Rr` 运行 · `<leader>Rd` 调试 · `<leader>Rc` 检查 |
| **crates.nvim** | Cargo.toml 版本提示 + 一键升级（仅 toml） | `<leader>cu` 升级 · `<leader>cU` 全升 · `<leader>ch` 详情 |
| **go.nvim** | Go 增强：GoTest / GoImpl / 跳测试 | `<leader>Gf` 测函数 · `<leader>Gt` 测文件 · `<leader>Gi` 接口 · `<leader>Ga` 跳测试 |

> Formatter 二进制按需装：`pacman -S stylua shfmt clang` / `:MasonInstall black isort prettierd goimports gofumpt`。缺失时 conform 自动 fallback 到 LSP 格式化。
> Rust/Go 增强与现有 lspconfig 已协调：rust_analyzer 移交给 rustaceanvim 直配；go.nvim 设 `lsp_cfg=false` 复用 lspconfig 的 gopls，不重复 attach。

+
---

## 插件一览（54 个，见 `lazy-lock.json`）

| 类别 | 插件 |
|---|---|
| 包管理 | lazy.nvim |
| LSP | nvim-lspconfig · mason.nvim · mason-lspconfig · cmp-nvim-lsp |
| 补全 | nvim-cmp · cmp-buffer · cmp-path · cmp_luasnip · LuaSnip |
| 语法 | nvim-treesitter |
| 文件 | neo-tree · yazi · alpha-nvim |
| 查找 | telescope · plenary · telescope-fzf-native · telescope-ui-select |
| Git | gitsigns · nvim-spectre |
| 格式化 | conform.nvim |
| 缩进 | indent-blankline |
| 诊断 | trouble · todo-comments |
| 大纲 | aerial |
| 光标跳转 | flash |
| 会话 | persistence |
| UI 美化 | snacks（vim.ui.input） · lualine · which-key · nvim-web-devicons · nui |
| 终端 | toggleterm |
| 调试 | nvim-dap · nvim-dap-ui · nvim-dap-virtual-text · mason-nvim-dap · nvim-nio |
| 运行 | code_runner |
| 项目 | project.nvim · projectmgr |
| Markdown | render-markdown · peek |
| 编辑增强 | Comment · nvim-autopairs · nvim-surround · mini.bufremove |
| 主题 | catppuccin · base16-nvim |
| AI | omp.nvim |

---

## 说明

- 本配置面向 **Arch Linux**，部分注释提及 `pacman`；TypeScript 走系统全局安装（`/usr/lib/node_modules/typescript/lib`），由 `ts_ls` 显式引用。
- 个人配置，持续调整中。欢迎参考，但不保证在其他环境开箱即用。
