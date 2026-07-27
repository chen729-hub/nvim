-- ~/.config/nvim/lua/config/keymaps.lua
--
-- 全局快捷键集中管理
--   - LSP 快捷键见 lua/plugins/lsp.lua（在 LspAttach 内绑定，buffer-local）
--   - 调试快捷键（DAP）已从 lua/plugins/dap.lua 迁移到本文件

local map = vim.keymap.set

-- ==========================================
-- 1. 常用核心控制
-- ==========================================

-- Ctrl + s : 快速保存文件 (普通模式、插入模式、可视模式统一支持)
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<cr><esc>", { noremap = true, silent = true, desc = "保存文件" })

-- Ctrl + a : 全选当前文件
map({ "n", "i", "v" }, "<C-a>", "<esc>ggVG", { noremap = true, silent = true, desc = "全选文本" })

-- 复制与粘贴：系统剪切板（需要 xclip / wl-copy）
map("v", "<C-c>", '"+y', { noremap = true, silent = true, desc = "复制到系统剪切板" })
map({ "n", "v" }, "<C-v>", '"+p', { noremap = true, silent = true, desc = "从系统剪切板粘贴" })
map("i", "<C-v>", '<ESC>"+pa', { noremap = true, silent = true, desc = "插入模式粘贴" })

-- Ctrl+x：剪切
map("v", "<C-x>", '"+d', { noremap = true, silent = true, desc = "剪切到系统剪切板" })
map("n", "<C-x>", '"+dd', { noremap = true, silent = true, desc = "剪切当前行到系统剪切板" })

-- ==========================================
-- 2. 文本快速选择
-- ==========================================

map("n", "vv", "^v$", { noremap = true, silent = true, desc = "选中当前行" })
map("n", "vw", "viw", { noremap = true, silent = true, desc = "选中当前单词" })
map("n", "v'", "vi'", { noremap = true, silent = true, desc = "选中单引号内的文本" })
map("n", "v\"", "vi\"", { noremap = true, silent = true, desc = "选中双引号内的文本" })
map("n", "v(", "vi(", { noremap = true, silent = true, desc = "选中圆括号内的文本" })
map("n", "v{", "vi{", { noremap = true, silent = true, desc = "选中花括号内的文本" })

-- ========== F2 另存为 ==========

local function delete_file(file)
  if file and vim.fn.filereadable(file) == 1 then
    vim.fn.delete(file)
  end
end

local function save_as()
  local old_file = vim.b.temp_file_path
  local is_temp = vim.b.is_temp_file == true

  local target = vim.fn.input("另存为: ", vim.fn.getcwd() .. "/", "file")

  if target == nil or target == "" then
    print("已取消另存为")
    return
  end

  target = vim.fn.expand(target)

  vim.cmd("saveas " .. vim.fn.fnameescape(target))

  -- 如果当前 buffer 是临时文件，另存后清理原临时文件
  if is_temp then
    vim.b.is_temp_file = false
    vim.b.temp_file_path = nil
    delete_file(old_file)
  end

  print("已另存为: " .. target)
end

map("n", "<F2>", save_as, { desc = "另存为" })
map("i", "<F2>", function()
  vim.cmd("stopinsert")
  vim.schedule(save_as)
end, { desc = "另存为" })
map("v", "<F2>", function()
  vim.cmd("normal! \27")
  vim.schedule(save_as)
end, { desc = "另存为" })

-- ========== 智能撤销 ==========

-- 插入模式撤销断点：防止连续输入一大段后 Ctrl+Z 一次性全删
local undo_breakpoints = {
  "<Space>", "<CR>", ".", ",", ";", ":", "!", "?",
  "，", "。", "；", "：", "！", "？",
}

for _, key in ipairs(undo_breakpoints) do
  map("i", key, key .. "<C-g>u", { noremap = true, silent = true })
end

-- Ctrl + Z：智能撤销
map({ "n", "i", "v" }, "<C-z>", function()
  local mode = vim.fn.mode()

  if mode == "i" or mode == "ic" or mode == "ix" then
    return "<C-g>u<C-o>u"
  end

  if mode == "v" or mode == "V" or mode == "\22" then
    return "<Esc>u"
  end

  return "u"
end, { expr = true, desc = "撤销" })

-- ==========================================
-- 3. LSP 快捷键：见 lua/plugins/lsp.lua
--    （在 LspAttach 内绑定，buffer-local，避免污染非 LSP buffer）
-- ==========================================

-- ==========================================
-- 4. 文件树 / 窗口
-- ==========================================

-- Ctrl + h : 一键跳回 Neo-tree 侧边栏
map("n", "<C-h>", function()
  local wins = vim.api.nvim_list_wins()
  for _, win in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "neo-tree" then
      vim.api.nvim_set_current_win(win)
      return
    end
  end
  vim.cmd("Neotree focus")
end, { noremap = true, silent = true, desc = "回到目录树" })

-- Ctrl + l : 回到右侧代码编辑区
map("n", "<C-l>", "<C-w>l", { noremap = true, silent = true, desc = "去文件编辑区" })

-- <leader>e : 切换文件树
map("n", "<leader>e", "<cmd>Neotree toggle<CR>", { noremap = true, silent = true, desc = "切换文件树" })

-- ==========================================
-- 5. Telescope 模糊检索
-- ==========================================

map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { noremap = true, silent = true, desc = "查找文件" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>",  { noremap = true, silent = true, desc = "实时全局搜索" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>",    { noremap = true, silent = true, desc = "查看当前缓冲区" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>",  { noremap = true, silent = true, desc = "查看 Neovim 帮助" })

-- ==========================================
-- 6. 终端 (ToggleTerm)
-- ==========================================

map({ "n", "t" }, "<C-\\>", "<cmd>ToggleTerm<CR>", { noremap = true, silent = true, desc = "切换浮动终端" })
-- 终端模式：双击 Esc 切回普通模式。
-- 单 Esc 不再绑定 → 默认透传 pty，让 omp / lazygit / fzf / shell 里的 vim 都能收到；
-- 普通 toggleterm 里单击会有 ~timeoutlen(400ms) 延迟才透传（等歧义超时），omp buffer 另用 nowait 免延迟（见 <leader>ao）。
map("t", "<Esc><Esc>", [[<C-\><C-n>]], { noremap = true, silent = true, desc = "终端：双击 Esc 切回普通模式" })

-- ==========================================
-- 7. 标签页 / Buffer
-- ==========================================

-- <A-d> : 用 mini.bufremove 删除当前缓冲区
map("n", "<A-d>", function()
  require("mini.bufremove").delete(0)
end, { desc = "删除标签页并切换到下一个" })

-- <A-h>/<A-l> 切换 buffer
-- 严格按当前窗口标签栏的显示顺序跳（见 config/winbar.lua 的 per-window 标签表），
-- 不再用全局 bufnr 顺序。不 wrap：到两端就停下。
local function cycle_buf(dir)
  local bufs = require("config.winbar").win_bufs(0)
  if #bufs == 0 then return end
  local cur = vim.api.nvim_get_current_buf()
  -- 找当前 buffer 在列表里的位置
  local idx = nil
  for i, b in ipairs(bufs) do
    if b == cur then idx = i break end
  end
  -- 当前 buffer 不在列表里（比如停在 neo-tree）：跳到列表首个
  if idx == nil then
    vim.api.nvim_set_current_buf(bufs[1])
    return
  end
  local nexti = idx + dir
  -- 边界：不 wrap，到头就停
  if nexti < 1 or nexti > #bufs then return end
  vim.api.nvim_set_current_buf(bufs[nexti])
end

map("n", "<A-h>", function() cycle_buf(-1) end, { desc = "左边标签页" })
map("n", "<A-l>", function() cycle_buf(1) end,  { desc = "右边标签页" })

-- ==========================================
-- 8. 代码执行 (code_runner)
-- ==========================================

map("n", "<leader>r",  "<cmd>RunCode<CR>",    { noremap = true, silent = true, desc = "运行当前文件" })
map("n", "<leader>rp", "<cmd>RunProject<CR>", { noremap = true, silent = true, desc = "运行项目" })
map("n", "<leader>rc", "<cmd>RunClose<CR>",   { noremap = true, silent = true, desc = "关闭运行窗口" })

-- ==========================================
-- 9. 临时文件
-- ==========================================

map("n", "<leader>l", "<cmd>TempFileType<CR>", { desc = "切换临时文件语言" })

-- ==========================================
-- 10. 调试 (DAP) —— 从 lua/plugins/dap.lua 迁移至此
--    使用 lazy require，无需 dap 插件在定义时已加载
-- ==========================================

map("n", "<leader>b", function() require("dap").toggle_breakpoint() end, { desc = "DAP: 切换断点" })
map("n", "<F5>",       function() require("dap").continue() end,          { desc = "DAP: 继续" })
map("n", "<F10>",      function() require("dap").step_over() end,         { desc = "DAP: 单步跨过" })
map("n", "<F11>",      function() require("dap").step_into() end,         { desc = "DAP: 单步进入" })
map("n", "<F12>",      function() require("dap").step_out() end,          { desc = "DAP: 单步跳出" })
map("n", "<leader>du", function() require("dapui").toggle() end,          { desc = "DAP: 切换 UI" })

-- ==========================================
-- 11. 折叠 (treesitter fold)
--    内置 z- 系列命令（za=toggle zc=关闭 zo=打开 zM=全部折叠 zR=全部展开 zj/zk=跳转）
--    下面是几个更顺手的 <leader> 版本：
-- ==========================================
map("n", "<leader>zz", "za", { noremap = true, silent = true, desc = "折叠：切换当前块" })
map("n", "<leader>zM", "zM", { noremap = true, silent = true, desc = "折叠：全部折叠" })
map("n", "<leader>zR", "zR", { noremap = true, silent = true, desc = "折叠：全部展开" })

-- ==========================================
-- 12. 窗口分割（≈ tmux prefix 那套逻辑）
--     <leader>w 子前缀 + v/s/c/hjkl，按了 w 后等 which-key 弹出菜单
-- ==========================================
map("n", "<leader>wv", "<cmd>vsplit<CR>", { silent = true, desc = "窗口：垂直分割" })
map("n", "<leader>ws", "<cmd>split<CR>",  { silent = true, desc = "窗口：水平分割" })
map("n", "<leader>wc", "<cmd>close<CR>",  { silent = true, desc = "窗口：关闭" })
map("n", "<leader>wh", "<C-w>h",          { silent = true, desc = "窗口：移到左边" })
map("n", "<leader>wj", "<C-w>j",          { silent = true, desc = "窗口：移到下边" })
map("n", "<leader>wk", "<C-w>k",          { silent = true, desc = "窗口：移到上边" })
map("n", "<leader>wl", "<C-w>l",          { silent = true, desc = "窗口：移到右边" })

-- ==========================================
-- 14. AI / Git TUI (omp + lazygit)
-- ------------------------------------------------------------------
-- 复用 toggleterm 的 Terminal:new 起常驻 TUI，首次按键才 lazy 创建。
-- 终端实例缓存在模块 local，避免每次 toggle 重建进程。
-- ==========================================

local tui_terms = {}

local function toggle_tui(name, opts)
  if tui_terms[name] == nil then
    tui_terms[name] = require("toggleterm.terminal").Terminal:new(opts)
  end
  tui_terms[name]:toggle()
end

-- <leader>ao : 右侧分栏常驻 omp 会话
--   omp.nvim 会把这个会话设为活跃目标，自动同步当前文件 / 光标 / 选区
map("n", "<leader>ao", function()
  toggle_tui("omp", {
    cmd = "omp",
    direction = "vertical",
    hidden = true,
    close_on_exit = true,
    -- omp buffer 内单 Esc 透传打断 AI。
    -- buffer-local + nowait：无前缀歧义、不等 timeoutlen，单击立即透传。
    -- 副作用：此 buffer 里双击 <Esc><Esc> 也不再退 normal（第一个 Esc 已被本映射吃掉）；
    --   想退 normal 操纵窗口用 <C-\><C-n>，或再按 <leader>ao 收起。
    on_open = function(term)
      vim.keymap.set("t", "<Esc>", "<Esc>", {
        buffer = term.bufnr, noremap = true, silent = true, nowait = true,
        desc = "omp: 透传 Esc（打断 AI）",
      })
    end,
  })
end, { silent = true, desc = "AI: 切换 omp 终端" })

-- <leader>g : 浮动 lazygit
map("n", "<leader>g", function()
  toggle_tui("lazygit", {
    cmd = "lazygit",
    direction = "float",
    hidden = true,
    close_on_exit = true,
    float_opts = { border = "rounded" },
  })
end, { silent = true, desc = "Git: 浮动 lazygit" })

-- ==========================================
-- 15. Git 行内操作 (gitsigns) —— hunk 暂存/回退/预览/跳转
--     与 <leader>g 浮动 lazygit 互补：lazygit 管整库提交，gitsigns 管当前文件细粒度
-- ==========================================
map("n", "]h", function() require("gitsigns").nav_hunk("next") end, { desc = "Git: 下一个 hunk" })
map("n", "[h", function() require("gitsigns").nav_hunk("prev") end, { desc = "Git: 上一个 hunk" })
map("n", "<leader>hs", function() require("gitsigns").stage_hunk() end,    { desc = "Git: 暂存 hunk" })
map("n", "<leader>hr", function() require("gitsigns").reset_hunk() end,    { desc = "Git: 回退 hunk" })
map("n", "<leader>hp", function() require("gitsigns").preview_hunk() end,  { desc = "Git: 预览 hunk" })
map("n", "<leader>hb", function() require("gitsigns").blame_line() end,    { desc = "Git: 行 blame" })
map("n", "<leader>hR", function() require("gitsigns").reset_buffer() end,  { desc = "Git: 回退整文件" })
map({ "n", "v" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { silent = true, desc = "Git: 选 hunk（文本对象）" })

-- ==========================================
-- 16. 诊断面板 (trouble) —— 统一展示 diagnostics / references
--     取代散落的 location list
-- ==========================================
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", { desc = "诊断：全工程面板" })
map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", { desc = "诊断：当前 buffer" })
map("n", "<leader>cs", "<cmd>Trouble lsp toggle focus=false<CR>",  { desc = "LSP: 符号引用面板" })

-- ==========================================
-- 17. 代码大纲 (aerial) + 格式化 (conform)
-- ==========================================
map("n", "<leader>o",  "<cmd>AerialToggle!<CR>", { desc = "大纲：切换符号树" })
map("n", "<leader>fs", "<cmd>Telescope aerial<CR>", { desc = "查找：符号" })
map("n", "<leader>cf", function() require("conform").format({ async = true }) end, { desc = "格式化：当前文件" })

-- ==========================================
-- 18. 搜索替换 / 待办 (spectre + todo-comments)
-- ==========================================
map("n", "<leader>sr", function() require("spectre").open() end,         { desc = "搜索：全工程替换" })
map("n", "<leader>sow", function() require("spectre").open_file_search() end, { desc = "搜索：当前文件替换" })
map("n", "<leader>st", "<cmd>TodoTelescope<CR>", { desc = "查找：待办 (TODO/FIXME)" })

-- ==========================================
-- 19. 会话恢复 (persistence) —— <leader>q 命名空间
-- ==========================================
map("n", "<leader>qs", function() require("persistence").load() end,        { desc = "会话：恢复当前目录" })
map("n", "<leader>qS", function() require("persistence").select() end,      { desc = "会话：选择会话" })
map("n", "<leader>ql", function() require("persistence").load({ last = true }) end, { desc = "会话：恢复上次" })
map("n", "<leader>qd", function() require("persistence").stop() end,        { desc = "会话：本次不保存" })


-- ==========================================
-- 13. 备忘板
-- ==========================================

require("config.keypanel").setup()