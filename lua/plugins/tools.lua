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
          prompt_title = "搜索",
          results_title = "结果",
          preview_title = "预览",
          preview = { timeout = 250, filesize_limit = 10 },
        },
        pickers = require("config.chinese").telescope_pickers(),
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
      local translate = require("config.chinese").tree_mappings
      local defaults = require("neo-tree.defaults")
      require("neo-tree").setup({
        window = { width = 30, mappings = translate(defaults.window.mappings) },
        filesystem = { window = { mappings = translate(defaults.filesystem.window.mappings) } },
        buffers = { window = { mappings = translate(defaults.buffers.window.mappings) } },
        git_status = { window = { mappings = translate(defaults.git_status.window.mappings) } },
        -- 前缀数字自然排序：笔记里 "2 xxx" 排在 "10 xxx" 前面。
        -- 同一层级不区分文件/文件夹，统一按数字前缀排列。
        -- 注意：必须是顶层选项（不是 filesystem 下），且 neo-tree 校验时会
        -- 传入不含 name 的 { type="dir", path="foo" }，name 要用 path 兜底。
        sort_function = function(a, b)
          local name_a = a.name or a.path or ""
          local name_b = b.name or b.path or ""
          local na = tonumber(name_a:match("^%s*(%d+)"))
          local nb = tonumber(name_b:match("^%s*(%d+)"))
          if na and nb then
            if na ~= nb then
              return na < nb
            end
            -- 序号相同（如 "1 文件" 与 "01 文件"）再按名字排
            return name_a < name_b
          end
          -- 带序号的排在不带序号的前面
          if na or nb then
            return na ~= nil
          end
          return name_a < name_b
        end,
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
