-- 放大预览复用现有 Snacks/Kitty 渲染器，不改正文图片配置或图片同步方式。
local M = {}
local api = vim.api
local links = require("config.image_links")
local state, installed, previous_mouse
local fallback = "<Plug>(ImageZoomMouseFallback)"

local function notify(text)
  vim.notify(text, vim.log.levels.WARN, { title = "图片预览" })
end

local function box()
  local width = math.max(1, math.floor((vim.o.columns - 4) * 0.94))
  local height = math.max(1, math.floor((vim.o.lines - vim.o.cmdheight - 4) * 0.90))
  return {
    relative = "editor", style = "minimal", border = "rounded",
    width = width, height = height,
    row = math.max(0, math.floor((vim.o.lines - height - 2) / 2)),
    col = math.max(0, math.floor((vim.o.columns - width - 2) / 2)),
    title = " 图片放大预览 ", title_pos = "center",
    footer = " 适应窗口 · q / Esc 关闭 ", footer_pos = "center", zindex = 65,
  }
end

function M.close(restore)
  local current = state
  if not current then return end
  state = nil
  local focused = api.nvim_get_current_win() == current.win
  if current.placement then current.placement:close() end
  if api.nvim_win_is_valid(current.win) then api.nvim_win_close(current.win, true) end
  if api.nvim_buf_is_valid(current.buf) then api.nvim_buf_delete(current.buf, { force = true }) end
  if restore ~= false and focused and api.nvim_win_is_valid(current.source_win) then
    api.nvim_set_current_win(current.source_win)
  end
end

function M.open(source, source_buf)
  if state and not source then return end
  source_buf = source_buf or api.nvim_get_current_buf()
  if not api.nvim_buf_is_valid(source_buf) then return end
  if not source or source == "" then
    local cursor = api.nvim_win_get_cursor(0)
    source = links.find(api.nvim_buf_get_lines(source_buf, 0, -1, false), cursor[1], cursor[2] + 1)
  end
  if not source then notify("请将光标放在图片链接上，或点击正文中的图片"); return end
  local snacks = require("snacks")
  if not snacks.image.supports_terminal() then
    notify("当前终端不支持图片预览，请在 Kitty 中打开 Neovim")
    return
  end
  -- 网络地址按原样交给已有下载器，不能改动签名 URL 中的 + 或百分号。
  if not source:lower():match("^https?://") then
    local base = vim.fn.fnamemodify(api.nvim_buf_get_name(source_buf), ":h")
    local resolved, reason = links.resolve(source, base)
    if not resolved then notify(reason); return end
    if vim.fn.filereadable(resolved) == 0 then
      resolved = snacks.image.doc.resolve(source_buf, source)
    end
    if vim.fn.filereadable(resolved) == 0 then notify("未找到图片：" .. source); return end
    source = resolved
  end
  M.close(false)
  local current = { source = source, source_win = api.nvim_get_current_win(), source_buf = source_buf }
  current.buf = api.nvim_create_buf(false, true)
  vim.bo[current.buf].bufhidden = "wipe"
  current.win = api.nvim_open_win(current.buf, true, box())
  vim.wo[current.win].winblend = 0
  state = current
  local ok, placement = pcall(snacks.image.placement.new, current.buf, source, {
    inline = false, auto_resize = true,
  })
  if not ok then M.close(); notify("图片预览失败：" .. tostring(placement)); return end
  current.placement = placement
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, function() M.close() end,
      { buffer = current.buf, silent = true, desc = "关闭图片预览" })
  end
  -- 消耗触发本次放大的鼠标释放事件，避免跳回原窗口。
  vim.keymap.set("n", "<LeftRelease>", "<Ignore>", { buffer = current.buf, silent = true })
  api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(current.win), once = true,
    callback = function() if state == current then M.close(false) end end,
  })
  api.nvim_create_autocmd("WinLeave", {
    buffer = current.buf, once = true,
    callback = function()
      vim.schedule(function() if state == current then M.close(false) end end)
    end,
  })
end

-- 可见图片占用虚拟行，getmousepos().line 不一定指向它的 Markdown 源码行。
function M.hit_test(mouse)
  local win = mouse.winid or 0
  if win == 0 or not api.nvim_win_is_valid(win) then return end
  local buf = api.nvim_win_get_buf(win)
  if vim.bo[buf].filetype ~= "markdown" then return end
  local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
  local function target(row, column, strict)
    local source = links.find_image(lines, row, math.max(1, column), strict)
    if source then
      return { source = source, buf = buf, win = win, tick = api.nvim_buf_get_changedtick(buf) }
    end
  end
  local ns = api.nvim_get_namespaces()["snacks.image"]
  if ns and mouse.screenrow and mouse.screencol then
    local info = vim.fn.getwininfo(win)[1]
    for _, mark in ipairs(api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })) do
      local details = mark[4]
      if details.virt_lines and #details.virt_lines > 0 then
        local row = mark[2] + 1
        local screen = vim.fn.screenpos(win, row, 1)
        local top = details.virt_lines_above and (screen.row - #details.virt_lines) or (screen.row + 1)
        local index = mouse.screenrow - top + 1
        local virtual = details.virt_lines[index]
        if screen.row > 0 and virtual then
          local text = {}
          for _, chunk in ipairs(virtual) do text[#text + 1] = chunk[1] end
          local left = info.wincol + info.textoff
          if mouse.screencol >= left and mouse.screencol < left + vim.fn.strdisplaywidth(table.concat(text)) then
            local hit = target(row, mark[3] + 1)
            if hit then return hit end
          end
        end
      end
    end
  end
  if (mouse.line or 0) > 0 then return target(mouse.line, mouse.column or 1, true) end
end

function M.click()
  local target = M.hit_test(vim.fn.getmousepos())
  if not target then return previous_mouse and fallback or "<LeftMouse>" end
  vim.schedule(function()
    if api.nvim_win_is_valid(target.win) and api.nvim_buf_is_valid(target.buf)
        and api.nvim_win_get_buf(target.win) == target.buf
        and api.nvim_buf_get_changedtick(target.buf) == target.tick then
      api.nvim_set_current_win(target.win)
      M.open(target.source, target.buf)
    end
  end)
  return "<Ignore>"
end

function M.status() return state end

function M.setup()
  if installed then return end
  installed = true
  for _, mapping in ipairs(api.nvim_get_keymap("n")) do
    if mapping.lhs == "<LeftMouse>" then previous_mouse = mapping; break end
  end
  if previous_mouse then
    local copy = vim.deepcopy(previous_mouse)
    copy.lhs, copy.lhsraw = fallback, api.nvim_replace_termcodes(fallback, true, true, true)
    copy.lhsrawalt = nil
    vim.fn.mapset("n", false, copy)
  end
  vim.keymap.set("n", "<LeftMouse>", M.click, { expr = true, silent = true, desc = "点击放大 Markdown 图片" })
  for _, command in ipairs({ "ImageZoom", "CloudImage" }) do
    api.nvim_create_user_command(command, function(args) M.open(args.args ~= "" and args.args or nil) end,
      { nargs = "?", complete = "file", desc = "放大预览光标处图片或指定图片" })
  end
  for _, command in ipairs({ "ImageZoomClose", "CloudImageClose" }) do
    api.nvim_create_user_command(command, function() M.close() end, { desc = "关闭图片预览" })
  end
  local group = api.nvim_create_augroup("UserImageZoom", { clear = true })
  api.nvim_create_autocmd("VimResized", { group = group, callback = function()
    if state and api.nvim_win_is_valid(state.win) then
      api.nvim_win_set_config(state.win, box())
      if state.placement then state.placement:update() end
    end
  end })
  api.nvim_create_autocmd("VimLeavePre", { group = group, callback = function() M.close(false) end })
end

return M
