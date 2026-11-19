-- ~/.config/nvim/lua/config/markdown.lua
--
-- Markdown 编辑增强：
--   1. 格式化快捷键（buffer-local，仅 markdown 生效），风格贴近 Obsidian
--   2. 表格自动对齐（移植自 cap153/nvim，加 pcall 保护）
--
-- 关于快捷键的妥协（终端硬限制）：
--   * <C-i> 在终端里等于 <Tab>，不能用作"斜体"——故斜体改用 <C-e>
--   * <C-e> 在普通文件里是 cmp 取消补全；markdown 里本键改做斜体，
--     关补全弹窗请按 <Esc>

local M = {}

-- ========================================================
-- 1. 格式化快捷键
-- ========================================================

-- 插入模式：插入空标记并把光标放中间
local function ins(key, desc, rhs)
  vim.keymap.set("i", key, rhs, { buffer = 0, silent = true, desc = "Markdown：" .. desc })
end

-- 可视模式：用 left/right 包裹选区
-- 用纯 RHS 序列（c 选区 -> <C-r>" 粘回 -> 右标记 -> Esc），与插入模式同机制
-- 代价：会占用无名寄存器 "，对格式化键可接受
local function vis(key, desc, rhs)
  vim.keymap.set("x", key, rhs, { buffer = 0, silent = true, desc = "Markdown 选区：" .. desc })
end

function M.keys(buf)
  vim.api.nvim_set_current_buf(buf)
  -- 插入模式（插入空标记，光标停在中间）
  ins("<C-b>",  "加粗",     "****<Esc>F*i")       -- **|**
  ins("<C-e>",  "斜体",     "**<Esc>F*a")         -- *|*   (<C-i> 是 Tab，见文件头)
  ins("<C-]>",  "行内代码",  "``<Esc>F`a")         -- `|`
  ins("<C-k>",  "链接",     "[]()<Esc>F[a")       -- [|]()
  -- 可视模式（包裹选区）
  vis("<C-b>",  "加粗",     'c**<C-r>"**<Esc>')
  vis("<C-e>",  "斜体",     'c*<C-r>"*<Esc>')
  vis("<C-]>",  "行内代码",  'c`<C-r>"`<Esc>')
  vis("<C-k>",  "链接",     'c[<C-r>"]()<Esc>F(a')  -- [选区](|) 光标停在 URL
end

-- ========================================================
-- 2. 表格自动对齐（移植自 cap153/nvim，加 pcall 保护）
-- ========================================================

local table_line_char = {
  { ':', ':' }, { ':', '-' }, { '-', ':' },
}

local table_line_char_insert = {
  { ':', ':' }, { ':', ' ' }, { ' ', ':' },
}

local function check_markdown_table(line_number)
  local line = vim.api.nvim_buf_get_lines(0, line_number - 1, line_number, true)[1]
  return line and string.match(line, '^|.*|$')
end

local function find_markdown_table(range)
  local cursor_line = vim.fn.line('.')
  local end_line = range == -1 and 1 or vim.fn.line('$')
  for l = cursor_line, end_line, range do
    if not check_markdown_table(l) then
      return l - range
    end
    if (range == -1 and l == 1) or (range == 1 and l == vim.fn.line('$')) then
      return l
    end
  end
  return -1
end

local function get_cells_width(contents)
  local width = {}
  for _ = 1, #contents[1] do width[#width + 1] = 0 end
  for i = 1, #contents do
    if i ~= 2 then
      for _, cell in ipairs(contents[i]) do
        width[_] = math.max(width[_], cell and vim.fn.strdisplaywidth(cell) or 0)
      end
    end
  end
  return width
end

local function update_cells(contents, width)
  local function add_space(cell, num) return ' ' .. cell .. ' ' .. string.rep(' ', num) end
  local function get_chars(cell)
    return { string.sub(cell, 1, 1), string.sub(cell, #cell) }
  end
  local function char_id(chars)
    for i, v in ipairs(table_line_char) do
      if chars[1] == v[1] and chars[2] == v[2] then return i end
    end
    for i, v in ipairs(table_line_char_insert) do
      if chars[1] == v[1] and chars[2] == v[2] then return i end
    end
    return 0
  end
  for i, cells in ipairs(contents) do
    if i == 2 then
      for j, _ in ipairs(cells) do
        local chars = get_chars(contents[i][j])
        local id = char_id(chars)
        contents[i][j] = string.rep('-', width[j])
        local c = id ~= 0 and table_line_char[id] or { '-', '-' }
        contents[i][j] = c[1] .. contents[i][j] .. c[2]
      end
    else
      for j, cell in ipairs(cells) do
        contents[i][j] = add_space(cell, width[j] - vim.fn.strdisplaywidth(cell))
      end
    end
  end
  return contents
end

local function cells_to_lines(contents)
  for i = 1, #contents do
    local line = '|'
    for j = 1, #contents[i] do line = line .. contents[i][j] .. '|' end
    contents[i] = line
  end
  return contents
end

local function format_table()
  if not check_markdown_table(vim.fn.line('.')) then return end
  local s_line, e_line = find_markdown_table(-1), find_markdown_table(1)
  local contents = {}
  for lnum = s_line, e_line do
    local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, true)[1]
    -- Only unescaped pipes delimit cells; retain escaped pipes and empty cells.
    local cells, start, i = {}, 2, 2
    while i <= #line do
      local char = line:sub(i, i)
      if char == "\\" then
        i = i + 2
      elseif char == "|" then
        cells[#cells + 1] = vim.trim(line:sub(start, i - 1))
        start, i = i + 1, i + 1
      else
        i = i + 1
      end
    end
    if #contents > 0 and #cells ~= #contents[1] then return end
    contents[#contents + 1] = cells
  end
  local width = get_cells_width(contents)
  contents = update_cells(contents, width)
  contents = cells_to_lines(contents)
  vim.api.nvim_buf_set_lines(0, s_line - 1, e_line, true, contents)
end

local function format_table_line()
  local cur = vim.api.nvim_get_current_line()
  local pos = vim.api.nvim_win_get_cursor(0)
  local char = cur:sub(pos[2], pos[2])
  if char == '|' and pos[2] ~= 1 then
    format_table()
    local len = #vim.api.nvim_get_current_line()
    vim.api.nvim_win_set_cursor(0, { pos[1], len })
  end
end

function M.table(buf)
  local group = vim.api.nvim_create_augroup('UserMdTableFormat', { clear = true })
  vim.api.nvim_create_autocmd('InsertLeave', {
    group = group, buffer = buf,
    callback = function() pcall(format_table) end,
  })
  vim.api.nvim_create_autocmd('TextChangedI', {
    group = group, buffer = buf,
    callback = function() pcall(format_table_line) end,
  })
end

function M.setup(buf)
  buf = buf or 0
  M.keys(buf)
  M.table(buf)
end

return M
