-- ~/.config/nvim/init.lua
--
-- 入口：只做三件事
--   1. 设置 leader
--   2. 加载个人 options / keymaps
--   3. 启动 lazy.nvim

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- 个人 options 和快捷键
require("config.options")
require("config.keymaps")
require("config.autoreload")

-- ========================================================
-- 自动化下载 / 安装 lazy.nvim 包管理器
-- ========================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins", {
  ui = { border = "rounded" },
  change_detection = { notify = false },
  -- 关掉 luarocks：本配置无任何插件依赖 luarocks（已核实 lazy-lock + 全部 spec），
  -- 默认的 hererocks 自动安装会报 ❌，关掉后 :checkhealth lazy 干净。
  rocks = { enabled = false },
  -- 关掉旧 API 废弃弹窗，不再需要全局 g:deprecation_warnings 假补丁
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },
})
