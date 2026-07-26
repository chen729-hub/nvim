-- ~/.config/nvim/lua/config/autoreload.lua
--
-- 外部工具（如 omp 的 edit/write）修改文件后，自动刷新 nvim buffer。
--
-- 为什么需要定时器：
--   nvim 的 autoread / FocusGained 在窗口失焦时不会主动轮询；
--   而在 tmux 下 FocusGained 事件默认不触发（需要终端 focus reporting
--   且 tmux `set -g focus-events on`），所以纯事件驱动不可靠。
--   这里用「autoread + 事件 checktime + 定时器 checktime」三重保险。
--
-- 安全性：
--   checktime 只会重载「没有未保存修改」的 buffer；
--   若 buffer 本身有改动且文件也被外部改了，会弹 W12 警告，绝不强制覆盖。

vim.o.autoread = true

local augroup = vim.api.nvim_create_augroup("AutoReload", { clear = true })

-- 事件驱动：聚焦 / 切换 buffer / 光标停留时立即检查一次
vim.api.nvim_create_autocmd(
  { "FocusGained", "BufEnter", "CursorHold", "CursorHoldI", "TermClose" },
  { group = augroup, command = "checktime" }
)

-- 定时器兜底：tmux 下 FocusGained 失效，用周期轮询保证一定能刷到
-- 间隔可调：笔记场景 1000ms 足够，追求实时可改 500ms
local RELOAD_INTERVAL_MS = 1000
vim.api.nvim_create_autocmd("VimEnter", {
  group = augroup,
  once = true,
  callback = function()
    local timer = assert(vim.uv.new_timer())
    timer:start(RELOAD_INTERVAL_MS, RELOAD_INTERVAL_MS, function()
      vim.schedule(function()
        vim.cmd("checktime")
      end)
    end)
    -- timer 持续整个 nvim 生命周期，nvim 退出时自动回收，无需手动 stop
  end,
})
