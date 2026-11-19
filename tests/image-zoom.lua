-- Standalone offline checks: nvim --headless -u NONE -i NONE -l tests/image-zoom.lua
local ok, err = xpcall(function()
  local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
  vim.opt.rtp:prepend(root)
  vim.o.columns, vim.o.lines = 180, 60
  local placements, old_mouse_calls = {}, 0
  package.loaded.snacks = { image = {
    supports_terminal = function() return true end,
    placement = { new = function(buf, src, opts)
      local result = { buf = buf, src = src, opts = opts, closed = false, updates = 0 }
      function result:close() self.closed = true end
      function result:update() self.updates = self.updates + 1 end
      placements[#placements + 1] = result
      return result
    end },
  } }
  vim.keymap.set("n", "<LeftMouse>", function() old_mouse_calls = old_mouse_calls + 1 end)
  local zoom = require("config.image_zoom")
  local links = require("config.image_links")
  zoom.setup()
  zoom.setup()
  local url = "https://example.invalid/image.png?x=a+b&token=%2B%20"
  local buf, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  vim.bo[buf].filetype = "markdown"
  local lines = { "![test](" .. url .. ")", "ordinary text", "prefix ![test](" .. url .. ") suffix",
    "![[附件/测试.png|300]]", "![sample][ref]", "[ref]: " .. url }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  assert(links.find_image(lines, 1, 1) == url, "signed URL changed")
  assert(links.find_image(lines, 4, 1) == "附件/测试.png", "wiki image failed")
  assert(links.find_image(lines, 5, 1) == url, "reference image failed")
  assert(links.find_image(lines, 3, 1, true) == nil, "plain prose became a clickable image")
  assert(links.find_image({ "https://example.invalid/not-an-image" }, 1, 5) == nil)
  assert(links.resolve("附件/a%20b.png", "/tmp/note") == "/tmp/note/附件/a b.png")
  assert(links.resolve("https://example.invalid/a+b%20c.png", "/tmp") == "https://example.invalid/a+b%20c.png")
  assert(links.resolve("javascript:alert(1)", "/tmp") == nil)

  vim.api.nvim_win_set_cursor(win, { 1, 0 })
  zoom.open()
  local state = assert(zoom.status(), "preview not opened")
  local config = vim.api.nvim_win_get_config(state.win)
  assert(config.width > 80 and config.height > 30, "preview still limited to inline size")
  assert(state.source == url and placements[1].src == url, "renderer received a changed URL")
  assert(placements[1].opts.inline == false and placements[1].opts.auto_resize == true)
  assert(vim.fn.maparg("q", "n", false, true).desc == "关闭图片预览")
  assert(vim.fn.maparg("<Esc>", "n", false, true).desc == "关闭图片预览")
  vim.o.columns = 150
  vim.api.nvim_exec_autocmds("VimResized", {})
  assert(placements[1].updates == 1, "preview did not resize")
  zoom.close()
  assert(zoom.status() == nil and placements[1].closed)
  assert(not vim.api.nvim_win_is_valid(state.win) and not vim.api.nvim_buf_is_valid(state.buf))
  assert(vim.api.nvim_get_current_win() == win, "close did not return to note")
  assert(vim.api.nvim_buf_get_changedtick(buf) == tick, "note content changed")
  assert(zoom.hit_test({ winid = win, line = 2, column = 1 }) == nil)
  assert(zoom.hit_test({ winid = win, line = 3, column = 1 }) == nil)
  assert(zoom.hit_test({ winid = win, line = 1, column = 1 }).source == url)

  -- A click on image virtual lines must use its extmark anchor, not mouse.line.
  local ns = vim.api.nvim_create_namespace("snacks.image")
  vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
    virt_lines = { { { "xxxxxxxx", "Normal" } }, { { "xxxxxxxx", "Normal" } } },
  })
  vim.cmd("redraw")
  local pos = vim.fn.screenpos(win, 1, 1)
  local info = vim.fn.getwininfo(win)[1]
  assert(pos.row > 0)
  local hit = zoom.hit_test({ winid = win, line = 2, column = 1,
    screenrow = pos.row + 2, screencol = info.wincol + info.textoff + 1 })
  assert(hit and hit.source == url, "virtual image click missed")
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  local fallback = vim.fn.maparg("<Plug>(ImageZoomMouseFallback)", "n", false, true)
  assert(type(fallback.callback) == "function", "old mouse handler lost")
  fallback.callback()
  assert(old_mouse_calls == 1)
  local mouse = vim.fn.getmousepos
  vim.fn.getmousepos = function() return { winid = win, line = 2, column = 1 } end
  assert(zoom.click() == "<Plug>(ImageZoomMouseFallback)")
  vim.fn.getmousepos = function() return { winid = win, line = 1, column = 1 } end
  assert(zoom.click() == "<Ignore>")
  assert(vim.wait(500, function() return zoom.status() ~= nil end, 10), "click did not open preview")
  vim.fn.getmousepos = mouse
  state = zoom.status()
  vim.api.nvim_set_current_win(win)
  assert(vim.wait(500, function() return zoom.status() == nil end, 10), "leaving preview did not clean up")
  assert(not vim.api.nvim_win_is_valid(state.win))
  assert(vim.deep_equal(lines, vim.api.nvim_buf_get_lines(buf, 0, -1, false)), "source changed")
  print("Image zoom passed: large preview, signed URLs, wiki/reference links, resize, mouse fallback, virtual-line click, cleanup; no note writes")
end, debug.traceback)
if not ok then
  vim.api.nvim_err_writeln(tostring(err))
  vim.cmd("cquit 1")
end
