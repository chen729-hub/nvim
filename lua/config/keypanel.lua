-- ~/.config/nvim/lua/config/keymap_panel.lua

local M = {}

local state = {
  buf = nil,
  win = nil,
}

local lines = {
  "",
  "  Neovim 快捷键备忘面板",
  "",
  "  面板操作",
  "  q / Esc       关闭面板",
  "  m             新建临时文件 :TempFile",
  "  f             切换临时文件语言 :TempFileType",
  "  r             运行当前文件 :RunCode",
  "  p             运行项目 :RunProject",
  "  c             关闭运行窗口 :RunClose",
  "  e             切换文件树 :Neotree toggle",
  "  /             全局搜索 :Telescope live_grep",
  "  ?             查看帮助 :Telescope help_tags",
  "",
  "  ─────────────────────────────────────────────",
  "",
  "  1. 常用核心控制",
  "",
  "  <C-s>         保存文件",
  "  <C-a>         全选当前文件",
  "  <C-c>         可视模式复制到系统剪切板",
  "  <C-v>         从系统剪切板粘贴",
  "  <C-x>         可视模式剪切 / 普通模式剪切当前行",
  "  <F2>          另存为",
  "  <C-z>         智能撤销",
  "",
  "  2. 文本快速选择",
  "",
  "  vv            选中当前行",
  "  vw            选中当前单词",
  "  v'            选中单引号内文本",
  "  v\"            选中双引号内文本",
  "  v(            选中圆括号内文本",
  "  v{            选中花括号内文本",
  "",
  "  3. 语言服务快捷键",
  "",
  "  gd            跳转到定义",
  "  K             悬浮文档提示",
  "  <leader>rn    重命名变量",
  "  <leader>ca    代码操作 / 自动修复",
  "  gr            查看引用位置",
  "",
  "  4. 文件树 / 窗口",
  "",
  "  <C-h>         回到 Neo-tree 文件树",
  "  <C-l>         回到右侧代码编辑区",
  "  <leader>e     切换文件树",
  "",
  "  5. 文件与文本搜索",
  "",
  "  <leader>ff    查找文件",
  "  <leader>fg    实时全局搜索",
  "  <leader>fb    查看当前缓冲区",
  "  <leader>fh    查看 Neovim 帮助",
  "",
  "  6. 终端",
  "",
  "  <C-\\>         切换 ToggleTerm 浮动终端",
  "  <Esc><Esc>    终端模式切回普通模式（单 Esc 透传：omp 打断 AI 等）",
  "",
  "  7. 标签页 / 缓冲区",
  "",
  "  <A-d>         删除当前标签页",
  "  <A-h>         切换到左边标签页",
  "  <A-l>         切换到右边标签页",
  "",
  "  8. 代码执行",
  "",
  "  <leader>p    切换 PicList 自动上传",
  "  <leader>r     运行当前文件",
  "  <leader>rp    运行项目",
  "  <leader>rc    关闭运行窗口",
  "",
  "  9. 临时文件",
  "",
  "  :TempFile     新建 markdown 临时文件",
  "  <leader>t     打开当前快捷键备忘面板",
  "  <leader>l     切换临时文件语言",
  "  F2            另存为",
  "",
  "  10. 调试 (DAP)",
  "",
  "  <leader>b     切换断点",
  "  <F5>          开始 / 继续调试",
  "  <F10>         单步跨过",
  "  <F11>         单步进入",
  "  <F12>         单步跳出",
  "  <leader>du    切换调试面板",
  "",
  "  11. 折叠",
  "",
  "  za / <leader>zz  切换当前折叠",
  "  zc            关闭当前折叠",
  "  zo            打开当前折叠",
  "  zM            全部折叠（压缩成大纲）",
  "  zR            全部展开",
  "  zj / zk       跳到下一个 / 上一个折叠",
  "",
  "  12. 窗口分割",
  "",
  "  <leader>wv    垂直分割窗口（左右）",
  "  <leader>ws    水平分割窗口（上下）",
  "  <leader>wc    关闭当前窗口",
  "  <leader>wh/j/k/l  跳到左/下/上/右窗口",
  "",
  "  13. 智能助手 / Git",
  "",
  "  <leader>ao    切换 omp 终端（右侧，自动同步上下文）",
  "  <leader>ac    切换 Codex 终端（右侧，保留会话）",
  "  Ctrl-\\ Ctrl-n  AI 终端返回普通模式，再用上述快捷键收起",
  "  <leader>g     浮动 lazygit",
  "",
  "  ─────────────────────────────────────────────",
  "",
  "  14. Git 行内 (gitsigns) + 诊断 (trouble)",
  "",
  "  ]h / [h       下/上一个 Git 修改块",
  "  <leader>hs    暂存修改块",
  "  <leader>hr    回退修改块",
  "  <leader>hp    预览修改块",
  "  <leader>hb    查看行修改来源",
  "  ih            选择修改块（可视模式）",
  "  <leader>xx    诊断面板：全工程",
  "  <leader>xX    诊断面板：当前缓冲区",
  "",
  "  15. 大纲 / 格式化 / 搜索替换 / 待办",
  "",
  "  <leader>o     切换代码大纲（aerial）",
  "  <leader>fs    查找符号（telescope aerial）",
  "  <leader>cf    格式化当前文件（conform）",
  "  <leader>sr    全工程查找替换（spectre）",
  "  <leader>st    搜索待办 TODO/FIXME",
  "",
  "  16. 会话恢复 (persistence)",
  "",
  "  <leader>qs    恢复当前目录会话",
  "  <leader>qS    选择会话",
  "  <leader>ql    恢复上次会话",
  "  <leader>qd    本次不自动保存",
  "",
  "  17. 光标跳转 (flash) + 语言专用",
  "",
  "  s + 两字符    跳到屏幕任意处（flash）",
  "  S             选择语法节点",
  "  <leader>R*    Rust（m 展开宏 / r 运行 / d 调试 / c 检查）",
  "  <leader>G*    Go（f 测函数 / t 测文件 / i 接口 / a 跳测试）",
  "  <leader>cu    crates：升级当前依赖（Cargo.toml）",
  "",
  "  18. 笔记同步（leader 是空格；默认不自动启动）",
  "",
  "  <leader>ns    启动 LiveSync 同步",
  "  <leader>nx    停止同步",
  "  <leader>ni    查看同步状态与进度",
  "  <leader>nn    立即同步整个笔记库",
  "  <leader>nu    推送当前笔记",
  "  <leader>nd    拉取当前笔记",
  "  <leader>nc    查看同步冲突",
  "  <leader>nh    连接诊断",
  "",
  "  19. 图片放大（保留原有正文图片显示）",
  "",
  "  鼠标左键      点击图片放大预览",
  "  <leader>mi    放大查看光标处图片",
  "  q / Esc       关闭图片预览并返回正文",
  "  <leader>mI    关闭图片预览",
  "",
}

function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end

  state.win = nil
  state.buf = nil
end

local function safe_cmd(cmd)
  M.close()

  vim.schedule(function()
    local ok, err = pcall(vim.cmd, cmd)

    if not ok then
      vim.notify("执行失败: " .. cmd .. "\n" .. err, vim.log.levels.ERROR)
    end
  end)
end

function M.open()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    M.close()
    return
  end

  local ui = vim.api.nvim_list_uis()[1]

  local width = math.min(88, ui.width - 4)
  local height = math.min(#lines, ui.height - 6)

  local row = math.floor((ui.height - height) / 2)
  local col = math.floor((ui.width - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " 快捷键备忘 ",
    title_pos = "center",
  })

  state.buf = buf
  state.win = win

  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].cursorline = true
  vim.wo[win].wrap = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].foldenable = false
  vim.wo[win].foldmethod = "manual"
  vim.wo[win].foldlevel = 99

  local function bmap(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, {
      buffer = buf,
      noremap = true,
      silent = true,
      nowait = true,
      desc = desc,
    })
  end

  bmap("q", M.close, "关闭快捷键面板")
  bmap("<Esc>", M.close, "关闭快捷键面板")

  -- 面板内快捷动作
  bmap("m", function()
    safe_cmd("TempFile")
  end, "新建临时文件")

  bmap("f", function()
    safe_cmd("TempFileType")
  end, "切换临时文件语言")

  bmap("r", function()
    safe_cmd("RunCode")
  end, "运行当前文件")

  bmap("p", function()
    safe_cmd("RunProject")
  end, "运行项目")

  bmap("c", function()
    safe_cmd("RunClose")
  end, "关闭运行窗口")

  bmap("e", function()
    safe_cmd("Neotree toggle")
  end, "切换文件树")

  bmap("/", function()
    safe_cmd("Telescope live_grep")
  end, "全局搜索")

  bmap("?", function()
    safe_cmd("Telescope help_tags")
  end, "查看帮助")
end

function M.setup()
  vim.api.nvim_create_user_command("KeymapPanel", function()
    M.open()
  end, {
    desc = "打开快捷键备忘面板",
  })

  vim.keymap.set("n", "<leader>t", function()
    M.open()
  end, {
    noremap = true,
    silent = true,
    nowait = true,
    desc = "快捷键备忘面板",
  })

  end

return M
