-- ~/.config/nvim/lua/config/options.lua
--
-- Neovim 全局选项。这里只放纯选项，DAP 图标已移到 lua/plugins/dap.lua。

-- 编码 / 文件
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

-- UI
vim.opt.number = true                 -- 行号
vim.opt.relativenumber = false
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"            -- 始终显示 sign 列，避免布局抖动
vim.opt.showmode = false              -- 状态栏已显示模式，命令行不再重复
vim.opt.cmdheight = 1
vim.opt.laststatus = 3                -- 全局状态栏：分屏之间改画真正的分隔线（WinSeparator）
                                      -- laststatus=2 时水平分屏的边界就是上方窗口的状态栏，画不出分隔线
vim.opt.termguicolors = true

-- 缩进
vim.opt.expandtab = true              -- Tab → 空格
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true

-- 搜索
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- 编辑体验
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.scrolloff = 4
vim.opt.sidescrolloff = 8
vim.opt.wrap = true                   -- 软换行：一行放不下时自动折到下一屏幕行显示（不产生真实换行）
vim.opt.linebreak = true              -- 只在单词边界折行，不把单词从中间截断
vim.opt.breakindent = true            -- 折行后的续行保留原行缩进
vim.opt.breakindentopt = "shift:2"    -- 续行整体再缩进 2 格，与原行错开更好认
vim.opt.showbreak = "↳ "              -- 续行开头加标记，一眼看出是折出来的行
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"     -- 系统剪切板
vim.opt.undofile = true               -- 持久化 undo
vim.opt.updatetime = 250              -- LSP / swap 写入节奏
vim.opt.timeoutlen = 400              -- which-key 延迟

-- 折叠（treesitter 驱动）
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99                   -- 默认全部展开，不自动折叠
vim.opt.foldcolumn = "1"                -- 左侧折叠列（显示 ▸ ▾ 指示符）
vim.opt.fillchars:append({ foldopen = "▾", foldclose = "▸", foldsep = "│" })

-- 折叠预览：折叠后显示首行内容 + 行数
function _G.FoldText()
  local line = vim.fn.getline(vim.v.foldstart)
  local cnt = vim.v.foldend - vim.v.foldstart + 1
  return line .. "  [" .. cnt .. " lines]"
end
vim.opt.foldtext = "v:lua.FoldText()"

-- 会话持久化（persistence.nvim 用）
-- 只存布局/缓冲/标签/工作目录，不存 options/folds（避免插件 / 自写折叠串台）
vim.opt.sessionoptions = "buffers,curdir,tabpages,winsize"

-- 临时文件目录：让 backup/swap/undo 集中
vim.opt.backup = false
vim.opt.swapfile = false

-- per-window winbar：每个窗口顶部各一条可点击标签栏（取代 bufferline 的全局 tabline）
require("config.winbar").setup()
