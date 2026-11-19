-- Run: nvim --headless -u NONE -l ~/.config/nvim/tests/markdown-tables.lua
-- Exercise the real parser, renderer, replacement resolver, and Neovim screen.
local config = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
vim.opt.rtp:prepend(config)
vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/render-markdown.nvim')
vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/nvim-treesitter/runtime')
vim.o.lines = 40
vim.o.laststatus = 0
vim.o.number = false
vim.o.signcolumn = 'no'
vim.o.wrap = true
vim.o.ruler = false
require('config.markdown_tables').setup()
require('config.markdown_tables').setup() -- reloading must not duplicate lines
local markdown = require('render-markdown')
markdown.setup({
  anti_conceal = { enabled = false }, debounce = 0,
  pipe_table = { border_virtual = true },
  win_options = { concealcursor = { rendered = 'nvic' } },
})
require('render-markdown.core.manager').init()
local ui = require('render-markdown.core.ui')

local function render()
  ui.update(vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win(), 'test', true)
  vim.wait(150)
  vim.cmd('redraw!')
end

local function check(lines, expected)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.filetype = 'markdown'
  vim.treesitter.start()
  for _ = 1, 2 do
    render()
    local count = 0
    for row = 1, vim.o.lines - 1 do
      local text = ''
      for col = 1, vim.o.columns do text = text .. vim.fn.screenstring(row, col) end
      if text:find('├', 1, true) then
        count = count + 1
        assert(text:find('┼', 1, true), 'divider must join column borders')
        assert(text:find('┤', 1, true), 'divider must join the right border')
      end
    end
    assert(count == expected, 'expected ' .. expected .. ' visible dividers, got ' .. count)
  end
end

-- Short rows, consecutive replacement rows, inline code, CJK width, and a
-- code fence that must never be treated as a rendered table.
check({ '', '| A | B |', '| --- | --- |', '| 1 | 2 |', '| 3 | 4 |', '| 5 | 6 |', '' }, 3)
check({
  '', '| 写法 | 是什么 | 可以用来做什么 |', '| --- | --- | --- |',
  '| `Student` | 我们定义的类型 | 声明变量、编写这个类的代码 |',
  '| `student` | 一个具体的学生对象 | 保存“小明”这个学生的数据，调用实例方法 |',
  '| `Student.class` | 描述 `Student` 类型的 `Class` 对象 | 查看类名、构造器、方法、字段等信息 |',
  '| `clazz` | 指向这个 `Class` 对象的变量 | 作为反射操作的入口 |', '',
}, 4)
check({ '', '```text', '| A | B |', '| --- | --- |', '| 1 | 2 |', '| 3 | 4 |', '```', '' }, 0)
check({ '', '| A | B |', '| --- | --- |', '| 1 | 2 |', '' }, 1)
markdown.disable()
vim.wait(150)
assert(#vim.api.nvim_buf_get_extmarks(0, ui.ns, 0, -1, {}) == 0, 'disable leaves marks')
print('Table screen checks passed: regular/wrapped/CJK rows, fences, edits, repeated render, disable cleanup')
vim.cmd('qa!')
