-- 使用本机已验证的客户端；旧 CLI 插件及其状态目录保留，以便回退。
-- 凭据直接从笔记库的 Obsidian 设置读取，不在本配置中保存密码。
return {
  dir = vim.fn.expand("~/tools/nvim-livesync"),
  name = "nvim-livesync",
  main = "nvim_livesync",
  lazy = false,
  build = "npm ci --omit=dev",
  keys = {
    { "<leader>ns", "<cmd>LiveSyncStart<cr>", desc = "启动同步" },
    { "<leader>nx", "<cmd>LiveSyncStop<cr>", desc = "停止同步" },
    { "<leader>nn", "<cmd>LiveSyncNow<cr>", desc = "立即同步整个笔记库" },
    { "<leader>ni", "<cmd>LiveSyncStatus<cr>", desc = "查看同步状态" },
    { "<leader>nu", "<cmd>LiveSyncPush<cr>", desc = "推送当前笔记" },
    { "<leader>nd", "<cmd>LiveSyncPull<cr>", desc = "拉取当前笔记" },
    { "<leader>nc", "<cmd>LiveSyncConflicts<cr>", desc = "查看同步冲突" },
    { "<leader>nh", "<cmd>LiveSyncDoctor<cr>", desc = "连接诊断" },
  },
  opts = {
    auto_start = false,
    vault_path = "/path/to/vault",
    state_dir = vim.fn.stdpath("state") .. "/nvim-livesync/main-vault",
    connection = {
      source = "obsidian_data",
      data_path = "/path/to/vault/.obsidian/plugins/obsidian-livesync/data.json",

    },
    sync = {
      initial = "safe",
      remote_delete = "trash",
      exclude = {
        ".git/**", ".obsidian/**", ".trash/**", ".nvim-livesync/**",
        "Session.vim", "Session.vim.*", "main.shada", "main.shada.*",
      },
    },
  },
}
