-- ~/.config/nvim/lua/plugins/spectre.lua
--
-- 全工程查找 + 批量替换面板（VS Code 式左侧栏）。依赖 ripgrep（已装）。
--   <leader>sr  全工程替换（左侧栏 toggle）
--   <leader>sow 当前文件替换（左侧栏 toggle，path 预填当前文件）
--
-- 打开后占用 neo-tree 的左侧位置（文件树隐藏，再按 <leader>e 重开），
-- 右侧文件内容永不被遮挡。
--
-- 交互（普通模式为中心）：
--   1. 打开停在普通模式，光标在 Search 行
--   2. 按 a 输入正则 → <Esc> 触发搜索
--   3. <Tab> 切 Search/Replace/Path · dd 勾选 · <leader>R 全部替换写盘 · ? 帮助
--
-- 出问题在 spectre 栏里 :SpectreDiag 一键自检。

-- VS Code 式左侧栏：占用 neo-tree 的左侧位置（文件树隐藏，<leader>e 重开），
-- 或无文件树时左侧新开。右侧文件内容永不被遮挡。
-- 宽度约为屏宽 1/3（最小 45），比 neo-tree 的 30 宽，能看清搜索结果。
local function open_in_sidebar()
  local width = math.max(15, math.floor(vim.o.columns * 0.20))

  -- 1) 已有 spectre 窗口 → 复用（spectre.open 内部也会判断，这里双保险）
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
    if ok and vim.bo[buf].filetype == "spectre_panel" then
      vim.api.nvim_set_current_win(win)
      return
    end
  end

  -- 2) neo-tree 窗口存在 → 关掉它（由 neo-tree 自己清理 buffer，不凭空造
  --    buffer），再左侧新开 spectre 栏，达到 VS Code「切换视图」的占位效果。
  --    绝不用 enew：那会造出一个会被会话保存、重开项目时还原出来的残留 buffer。
  local had_neotree = false
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
    if ok and vim.bo[buf].filetype == "neo-tree" then
      had_neotree = true
      break
    end
  end
  if had_neotree then pcall(vim.cmd, "Neotree close") end

  -- 3) 左侧新开一栏（无论是否关了 neo-tree）
  vim.cmd("topleft vertical " .. width .. " new")
end

-- 稳定的帮助浮窗：替代上游 show_help 在「浮窗嵌套」下被秒关的 bug。
-- 上游 show_menu_options 用 enter=false + 全局 autocmd 监听 WinScrolled 等
-- 8 个事件，任一触发即关窗。浮窗嵌套时帮助窗一创建就触发 WinScrolled → 出生即死。
-- 这里改 enter=true（焦点切过去）、buffer-local 的 q/<Esc>/BufLeave 关闭，稳定可靠。
local function show_spectre_help()
  local user_cfg = require("spectre.state").user_config
  local list = {}
  if user_cfg and user_cfg.mapping then
    for _, m in pairs(user_cfg.mapping) do
      if m.map and m.desc then table.insert(list, { key = m.map, desc = m.desc }) end
    end
  end
  -- 核心交互键（spectre 硬编码，不在 mapping 表里）
  vim.list_extend(list, {
    { key = "a / i", desc = "进入插入模式输入正则" },
    { key = "<Esc>", desc = "回普通模式并触发搜索" },
    { key = "<CR>", desc = "打开光标处结果文件" },
    { key = "?", desc = "本帮助" },
  })
  table.sort(list, function(a, b) return #a.key < #b.key end)

  local lines = { "  Spectre 快捷键", "" }
  for _, e in ipairs(list) do
    table.insert(lines, string.format("  %-12s  %s", e.key, e.desc))
  end

  local width           = math.min(60, vim.o.columns - 4)
  local height          = math.min(#lines, vim.o.lines - 4)
  local row             = math.floor((vim.o.lines - height) / 2)
  local col             = math.floor((vim.o.columns - width) / 2)
  local buf             = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  local win = vim.api.nvim_open_win(buf, true, {
    relative  = "editor",
    width     = width,
    height    = height,
    row       = row,
    col       = col,
    border    = "rounded",
    style     = "minimal",
    title     = " Spectre 帮助 ",
    title_pos = "center",
  })
  vim.wo[win].winblend = 0

  local function close()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end
  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true, silent = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true, silent = true })
  vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
    buffer = buf, once = true, callback = close,
  })
end

return {
  "nvim-pack/nvim-spectre",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = { "Spectre" },
  opts = {
    -- VS Code 式左侧栏：占用 neo-tree 位置或左侧新开，不遮挡文件内容
    open_cmd = open_in_sidebar,
    -- 关键：以普通模式打开。
    -- 之前设 true 会让用户一进来就卡在插入模式，导致 ? / <Tab> / <leader>R
    -- （全是普通模式映射）失效，且不按 <Esc> 就不会触发搜索。
    is_insert_mode = false,
  },
  config = function(_, opts)
    require("spectre").setup(opts)
    -- 修正 diff 高亮：上游 SpectreSearch→DiffChange、SpectreReplace→DiffDelete
    -- 完全反直觉（要删的原文显"保留"色，新文本显红色"删除"色），导致 both 模式
    -- 预览看起来像「往后面加红字」。改成直观 diff：红=要删的原文，绿=要加的新文本。
    -- setup() 内部会调 set_hl()，必须在它之后覆盖；并随 colorscheme 切换保持。
    local function fix_hl()
      vim.api.nvim_set_hl(0, "SpectreSearch", { link = "DiffDelete" })
      vim.api.nvim_set_hl(0, "SpectreReplace", { link = "DiffAdd" })
    end
    fix_hl()
    vim.api.nvim_create_autocmd("ColorScheme", { callback = fix_hl })
    -- override spectre 的 ? 帮助：上游 show_help 在「浮窗嵌套」下被自己的
    -- autocmd 秒关（WinScrolled 触发即 nvim_win_close）。重绑到上面的稳定版本。
    -- spectre 的 ? 是 mapping_buffer() 里硬编码（init.lua:234），mapping_buffer
    -- 在 open() 末尾、FileType（init.lua:171 设 filetype）之后才跑，所以
    -- 用 FileType 同步设会被覆盖。defer_fn(0) 等当前事件循环跑完（mapping_buffer
    -- 已执行）再设，并校验 buffer 仍有效（bufhidden=wipe 可能已销毁它）。
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "spectre_panel",
      callback = function(args)
        vim.defer_fn(function()
          if not vim.api.nvim_buf_is_valid(args.buf) then return end
          vim.keymap.set("n", "?", show_spectre_help,
            { buffer = args.buf, nowait = true, silent = true, desc = "Spectre 帮助" })
        end, 0)
      end,
    })
    -- 防残留 + 关行号：spectre buffer 设 bufhidden=wipe（关窗即销毁，不残留、
    -- 不被会话卷入）；spectre 窗口关闭绝对/相对行号（只作用于该 buffer 所在
    -- 窗口，主编辑器窗口的行号不受影响）。
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "spectre_panel",
      callback = function(args)
        vim.bo[args.buf].bufhidden = "wipe"
        for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
          vim.wo[win].number         = false
          vim.wo[win].relativenumber = false
        end
      end,
    })
    vim.api.nvim_create_autocmd("User", {
      pattern = "PersistenceSavePre",
      callback = function() pcall(require("spectre").close) end,
    })
    -- 一键自检：在 spectre 窗口里 :SpectreDiag，打印当前模式/光标 buffer/
    -- cwd/搜索词/keymap 是否就位，用于定位「按了没反应 / 搜不到」类问题
    vim.api.nvim_create_user_command("SpectreDiag", function()
      local s              = require("spectre.state")
      local b              = vim.api.nvim_get_current_buf()
      local has_q, has_tab = false, false
      for _, m in ipairs(vim.api.nvim_buf_get_keymap(b, "n")) do
        local lhs = vim.fn.keytrans(m.lhs)
        if lhs == "?" then has_q = true end
        if lhs == "<Tab>" or lhs == "<lt>Tab>" then has_tab = true end
      end
      local lines = {
        "当前模式      = " .. vim.fn.mode() .. "  (n=普通 i=插入，搜索靠 <Esc> 回普通触发)",
        "光标所在 buf  = " .. b .. "  filetype=" .. vim.bo[b].ft,
        "spectre bufnr = " .. tostring(s.bufnr) .. "  光标在 spectre? " .. tostring(b == s.bufnr),
        "spectre cwd   = " .. tostring(s.cwd),
        "vim :pwd      = " .. vim.fn.getcwd(),
        "搜索词        = [" .. tostring(s.query.search_query) .. "]  (<2 字符不搜)",
        "路径过滤 path = [" .. tostring(s.query.path) .. "]",
        "? 帮助映射    = " .. tostring(has_q) .. "    <Tab> 切换映射 = " .. tostring(has_tab),
      }
      vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Spectre 自检" })
    end, { desc = "诊断当前 spectre 面板状态" })
  end,
}
