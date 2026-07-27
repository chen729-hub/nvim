-- ~/.config/nvim/lua/plugins/tools.lua
--
-- 工具链：模糊查找 / 项目树 / 终端

return {
  -- ==================================================================
  -- 1. Telescope 模糊查找
  -- ==================================================================
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- fzf-native：C 版高速模糊排序器，让 telescope 搜索更快更准
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      -- ui-select：把 vim.ui.select（code action / 重命名）接管到 telescope 浮窗
      "nvim-telescope/telescope-ui-select.nvim",
    },
    cmd = "Telescope",
    config = function()
      require("telescope").setup({
        defaults = {
          layout_strategy = "horizontal",
          layout_config = { prompt_position = "top" },
          sorting_strategy = "ascending",
          preview = { timeout = 250, filesize_limit = 10 },
        },
        extensions = {
          -- code action / 重命名弹窗用下拉式 telescope 浮窗
          ["ui-select"] = require("telescope.themes").get_dropdown({}),
        },
      })
      -- 启用扩展（pcall 容错：扩展未装也不崩）
      pcall(require("telescope").load_extension, "fzf")
      pcall(require("telescope").load_extension, "ui-select")
    end,
  },

  -- ==================================================================
  -- 2. project.nvim：项目自动识别（注入到 Telescope 的 projects 扩展）
  -- ==================================================================
  {
    "ahmedkhalf/project.nvim",
    config = function()
      require("project_nvim").setup({
        detection_methods = { "pattern" },
        patterns = {
          ".git", "_darcs", ".hg", ".bzr", ".svn",
          "Makefile", "package.json", "go.mod",
        },
        update_cwd = true,
        change_cwd_on_project_open = true,
      })
      pcall(require("telescope").load_extension, "projects")
    end,
  },

  -- ==================================================================
  -- 3. neo-tree 文件树
  -- ==================================================================
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({
        window = { width = 30 },
      })
    end,
  },

  -- ==================================================================
  -- 4. toggleterm 终端
  -- ------------------------------------------------------------------
  -- 之前 on_create 里硬编码 source ~/.venv/bin/activate，
  -- 写 JS / Rust / Go 时也会被强行激活 Python venv，会刷一堆错误。
  -- 改成只在当前工作目录存在 venv 时才 source。
  -- ==================================================================
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        direction = "horizontal",
        open_mapping = [[<C-\>]],
        on_create = function(term)
          -- 当前项目本地 venv 优先，再退回全局 ~/.venv
          local candidates = {
            vim.fs.joinpath(vim.fn.getcwd(), ".venv", "bin", "activate",".fish"),
            vim.fs.joinpath(vim.fn.getcwd(), "venv", "bin", "activate",".fish"),
            vim.fs.joinpath(vim.env.HOME or "", ".venv", "bin", "activate",".fish"),
          }
          for _, path in ipairs(candidates) do
            if vim.uv.fs_stat(path) then
              term:send("source " .. vim.fn.shellescape(path))
              return
            end
          end
          -- 没 venv 就什么都不做，别污染 shell
        end,
      })
    end,
  },
}
