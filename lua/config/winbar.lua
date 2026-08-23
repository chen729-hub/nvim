-- ~/.config/nvim/lua/config/winbar.lua
--
-- 每个窗口自己的顶部标签栏（per-window winbar）。
-- 取代 bufferline 的全局 tabline：tabline 是 tabpage 级，只能整条横跨顶行；
-- winbar 是 window 级，每个窗口各画一条，分屏后左右各自一条。
-- 样式：胶囊（pill）形标签 + 按语种自动着色的 Nerd Font 图标。
-- 点击左键切到该 buffer，中键用 mini.bufremove 删除。
--
-- 标签列表是 per-window 的：每个窗口只记录自己在 BufEnter 里经过的 buffer，
-- 新分屏的标签栏从"只有当前 buffer"开始累积，不再共享全局 buffer 列表。
-- 标签过多超出窗口宽度时，以激活标签为中心向两侧扩展取可见区间，
-- 两端用 «N / N» 指示被藏起的标签数。

local M = {}

-- 胶囊两端的圆角字符（Powerline "rounded"），用 \u{} 转义防止字形在文件里丢失
--   左端用 E0B6（右半圆填充左半格） =  ``(注意:左端是 e0b6)
--   右端用 E0B4（左半圆填充右半格） =  ``(注意:右端是 e0b4)
local CAP_L = "\u{e0b6}"   --  ✦ 左端
local CAP_R = "\u{e0b4}"   --  ✦ 右端

-- 配色板（catppuccin mocha 色系，能与主题协调）
local C = {
  track  = "#11111b",   -- 标签栏底色（胶囊之间的间隙）
  pill   = "#181825",   -- 普通胶囊 bg
  pill_a = "#313244",   -- 激活胶囊 bg
  fg     = "#cdd6f4",   -- 激活前景
  dim    = "#6c7086",   -- 普通前景
  mod    = "#f38ba8",   -- 修改标记 ●
  close  = "#f38ba8",   -- 关闭键 颜色
}

-- 关闭键字形：Nerd Font fa-xmark（U+F00D），用 \u{} 转义保字形不丢
local CLOSE = "\u{f00d}"

-- 转义 statusline 的特殊字符
local function esc(s)
  return (s:gsub("%%", "%%%%"):gsub("\n", " "))
end

local icon_hl_cache = {}

-- 取图标 + 颜色，并按当前胶囊 bg 建一个专用高亮组（按语种着色）
local function icon_for(name, ext, pill_bg)
  local key = (ext == "" and "_noext" or ext) .. pill_bg
  if icon_hl_cache[key] then return icon_hl_cache[key] end
  local icon, color = " ", C.dim
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if ok then
    local ic, ic_color = devicons.get_icon_color(name, ext, { default = true })
    if ic then icon = ic end
    if ic_color then color = ic_color end
  end
  -- 高亮组名只保留字母数字，避免 ext 里出现怪字符
  local safe = ext:gsub("[^%w]", "")
  local hlname = "WbIcon" .. (safe == "" and "X" or safe)
  vim.api.nvim_set_hl(0, hlname, { fg = color, bg = pill_bg, default = true })
  icon_hl_cache[key] = { icon = icon, hl = hlname }
  return icon_hl_cache[key]
end

-- 点击回调
function _G.WinbarBufClick(minwid, _clicks, button, _mods)
  if not minwid or not vim.api.nvim_buf_is_valid(minwid) then return end
  if button == "m" then
    local ok = pcall(require("mini.bufremove").delete, minwid, false)
    if not ok then pcall(vim.cmd, "bdelete " .. minwid) end
  else
    pcall(vim.api.nvim_set_current_buf, minwid)
  end
end

-- 关闭键点击回调：删掉对应 buffer
function _G.WinbarCloseClick(minwid, _clicks, _button, _mods)
  if not minwid or not vim.api.nvim_buf_is_valid(minwid) then return end
  local ok = pcall(require("mini.bufremove").delete, minwid, false)
  if not ok then pcall(vim.cmd, "bdelete " .. minwid) end
end

-- 这些 filetype / buftype 的窗口不画标签栏
local skip_ft = { ["neo-tree"]=true, ["spectre_panel"]=true, ["toggleterm"]=true,
                  ["alpha"]=true, ["TelescopePrompt"]=true, ["yazi"]=true }

-- ---------------------------------------------------------------------------
-- per-window 标签列表
-- ---------------------------------------------------------------------------

-- winid -> 有序 bufnr 数组（按该窗口访问先后追加）
local tabs = {}

local function listed_normal(b)
  return vim.api.nvim_buf_is_valid(b)
    and vim.bo[b].buflisted
    and vim.bo[b].buftype == ""
    and vim.api.nvim_buf_get_name(b) ~= ""
end

-- 把 buf 登记进 win 的标签列表（幂等）
local function track(win, buf)
  if not listed_normal(buf) then return end
  local t = tabs[win]
  if not t then t = {}; tabs[win] = t end
  for _, x in ipairs(t) do
    if x == buf then return end
  end
  t[#t + 1] = buf
end

-- 从所有窗口的标签列表移除 buf
local function untrack(buf)
  for _, t in pairs(tabs) do
    for i = #t, 1, -1 do
      if t[i] == buf then table.remove(t, i) end
    end
  end
end

-- 窗口的标签列表（有序、已过滤失效项）。
-- 供 <A-h>/<A-l> 等按键严格按标签栏显示顺序跳转。
function M.win_bufs(win)
  if not win or win == 0 then win = vim.api.nvim_get_current_win() end
  local out = {}
  for _, b in ipairs(tabs[win] or {}) do
    if listed_normal(b) then out[#out + 1] = b end
  end
  return out
end

-- ---------------------------------------------------------------------------
-- 渲染
-- ---------------------------------------------------------------------------

-- 构造单个胶囊，返回 statusline 串 + 显示宽度
local function pill(active, b)
  local path     = vim.api.nvim_buf_get_name(b)
  local name     = vim.fn.fnamemodify(path, ":t")
  local ext      = vim.fn.fnamemodify(name, ":e")
  local modified = vim.bo[b].modified

  local pill_hl = active and "WbPillA" or "WbPill"
  local cap_hl  = active and "WbCapA"  or "WbCap"
  local bg      = active and C.pill_a or C.pill
  local ic      = icon_for(name, ext, bg)

  local close_hl = active and "WbCloseA" or "WbCloseI"
  -- 点击区域用 %X 终止（见 :h statusline）。先一段可点击切 buffer，
  -- 再单独一段可点击关闭键。
  local body = "%#" .. cap_hl .. "#" .. CAP_L
    .. "%" .. b .. "@v:lua.WinbarBufClick@%#" .. pill_hl .. "# "
    .. "%#" .. ic.hl .. "#" .. ic.icon
    .. "%#" .. pill_hl .. "# " .. esc(name) .. " "
    .. (modified and "%#WbMod#● " or "")
    .. "%X"
    -- 关闭键
    .. "%" .. b .. "@v:lua.WinbarCloseClick@%#" .. close_hl .. "#" .. CLOSE .. "%#"
    .. pill_hl .. "# %X"
    .. "%#" .. cap_hl .. "#" .. CAP_R

  -- 宽度按可见字符算：端帽 + 空格 + 图标 + 空格 + 文件名 + 空格
  --   + (● )? + 关闭键 + 空格 + 端帽
  local w = vim.fn.strdisplaywidth(CAP_L) + 1
    + vim.fn.strdisplaywidth(ic.icon) + 1
    + vim.fn.strdisplaywidth(name) + 1
    + (modified and 2 or 0)
    + vim.fn.strdisplaywidth(CLOSE) + 1
    + vim.fn.strdisplaywidth(CAP_R)
  return body, w
end

-- «N / N» 指示符宽度：箭头 1 格 + 数字 + 一侧空格
local function ind_w(n)
  return 2 + #tostring(n)
end

-- 给某个 win 构造完整 winbar 字符串
local function render_for(win)
  if not vim.api.nvim_win_is_valid(win) then return nil end
  local cur = vim.api.nvim_win_get_buf(win)
  -- 自愈：即便 BufEnter 没赶上（如 setup 晚于首屏），也先登记当前 buffer
  track(win, cur)

  -- 过滤掉已失效 / 不再符合条件的 buffer
  local bufs = {}
  for _, b in ipairs(tabs[win] or {}) do
    if listed_normal(b) then bufs[#bufs + 1] = b end
  end
  tabs[win] = bufs
  if #bufs == 0 then return nil end

  -- 先构造全部胶囊并测宽
  local pills, total = {}, 0
  local ai = 1 -- 激活胶囊下标
  for i, b in ipairs(bufs) do
    if b == cur then ai = i end
    local s, w = pill(b == cur, b)
    pills[i] = { s = s, w = w }
    total = total + w
  end
  total = total + (#pills - 1) -- 胶囊间隙

  local n = #pills
  local avail = vim.api.nvim_win_get_width(win) - 2 -- 两端留白

  -- 标签过多：以激活标签为中心，左右交替向外扩展，直到再放不下了
  local lo, hi = 1, n
  if total > avail then
    lo, hi = ai, ai
    -- 区间 [l..h] 的实际占用 = 胶囊 + 间隙 + 两端隐藏计数指示符
    local function need(l, h)
      local w = 0
      for i = l, h do
        w = w + pills[i].w + (i > l and 1 or 0)
      end
      if l > 1 then w = w + ind_w(l - 1) end
      if h < n then w = w + ind_w(n - h) end
      return w
    end
    while true do
      local grew = false
      if lo > 1 and need(lo - 1, hi) <= avail then lo = lo - 1; grew = true end
      if hi < n and need(lo, hi + 1) <= avail then hi = hi + 1; grew = true end
      if not grew then break end
    end
  end

  local out = "%#WbTrack# "  -- 左侧留白用轨道底色铺
  if lo > 1 then
    out = out .. "%#WbMore#«" .. (lo - 1) .. "%#WbTrack# "
  end
  for i = lo, hi do
    if i > lo then out = out .. " " end
    out = out .. pills[i].s
  end
  if hi < n then
    out = out .. " %#WbMore#" .. (n - hi) .. "»"
  end
  -- 末尾保持 WbTrack 高亮，让剩余空格自动用轨道底色填充（不写 %*）
  out = out .. "%#WbTrack# "
  return out
end

-- 给某个窗口设置 / 清除 winbar
local function apply_win(win)
  if not vim.api.nvim_win_is_valid(win) then return end
  local cfg = vim.api.nvim_win_get_config(win)
  if cfg.relative ~= "" then
    if vim.wo[win].winbar ~= nil then vim.wo[win].winbar = nil end
    return
  end
  local buf = vim.api.nvim_win_get_buf(win)
  local ft = vim.bo[buf].filetype
  if skip_ft[ft] or vim.bo[buf].buftype ~= "" then
    if vim.wo[win].winbar ~= nil then vim.wo[win].winbar = nil end
    return
  end
  local new = render_for(win)
  if vim.wo[win].winbar ~= new then
    vim.wo[win].winbar = new
  end
end

local function apply_all()
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    apply_win(w)
  end
end

local function set_hl()
  -- 轨道（胶囊之间的间隙 + 整条 winbar 底色）
  -- 轨道底色设为 NONE（透明），避免在透明主题里出现一条黑栏。
  -- 端帽 bg 也设为 NONE，半圆端帽只靠 fg（胶囊色）成型，外侧透出编辑器背景。
  vim.api.nvim_set_hl(0, "WbTrack", { bg = "NONE", default = true })
  -- 胶囊本体
  vim.api.nvim_set_hl(0, "WbPill",  { bg = C.pill,   fg = C.dim,  default = true })
  vim.api.nvim_set_hl(0, "WbPillA", { bg = C.pill_a, fg = C.fg,   bold = true, default = true })
  -- 半圆端帽：fg=胶囊 bg，bg=轨道 bg
  vim.api.nvim_set_hl(0, "WbCap",   { fg = C.pill,   bg = "NONE", default = true })
  vim.api.nvim_set_hl(0, "WbCapA",  { fg = C.pill_a, bg = "NONE", default = true })
  -- 修改标记
  vim.api.nvim_set_hl(0, "WbMod",   { fg = C.mod,    bg = C.pill_a, default = true })
  -- 关闭键：背景同胶囊本体（激活时用 pill_a，普通时用 pill），前景红色
  vim.api.nvim_set_hl(0, "WbCloseA",  { fg = C.close,  bg = C.pill_a, default = true, bold = true })
  vim.api.nvim_set_hl(0, "WbCloseI",  { fg = C.close,  bg = C.pill,   default = true, bold = true })
  -- 两端隐藏计数指示符（«N / N»）
  vim.api.nvim_set_hl(0, "WbMore",    { fg = C.dim,    bg = "NONE", default = true })
end

function M.setup()
  set_hl()
  local g = vim.api.nvim_create_augroup("Winbar", { clear = true })

  -- 纯刷新类事件
  vim.api.nvim_create_autocmd(
    { "BufFilePost", "BufModifiedSet", "WinNew", "WinEnter",
      "TabEnter", "FileType", "WinResized", "VimResized" },
    { group = g, callback = function() vim.schedule(apply_all) end }
  )

  -- 窗口里切到某 buffer：登记进该窗口自己的标签列表
  vim.api.nvim_create_autocmd("BufEnter", {
    group = g,
    callback = function(ev)
      track(vim.api.nvim_get_current_win(), ev.buf)
      vim.schedule(apply_all)
    end,
  })

  -- buffer 删除/抹掉：从所有窗口的标签列表移除
  vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = g,
    callback = function(ev)
      untrack(ev.buf)
      vim.schedule(apply_all)
    end,
  })

  -- 窗口关闭：丢掉它的标签列表
  vim.api.nvim_create_autocmd("WinClosed", {
    group = g,
    callback = function(ev)
      tabs[tonumber(ev.match)] = nil
      vim.schedule(apply_all)
    end,
  })

  -- 主题切换会清掉自定义高亮，重设并刷新一次
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = g, callback = function()
      icon_hl_cache = {}
      set_hl()
      vim.schedule(apply_all)
    end,
  })
  vim.schedule(apply_all)
end

return M
