-- ~/.config/nvim/lua/plugins/projects.lua
--
-- projectmgr：项目切换 / 会话恢复。
-- 额外补丁：新项目（无 session/shada）打开后没有任何文件，会导致 winbar
-- 标签栏插件对空 [No Name] 缓冲报错。这里包装 open_project，在打开后兜底——
-- 若没有任何已命名的常规缓冲，就打开项目里的第一个文件，让标签栏有东西渲染。

return {
  {
    "charludo/projectmgr.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      local projectmgr = require("projectmgr")

      projectmgr.setup({
        shada = { enabled = true },
      })

      pcall(function()
        require("telescope").load_extension("projectmgr")
      end)

      -- ------------------------------------------------------------------
      -- 兜底：打开项目后若没有任何已命名常规缓冲，打开项目里的第一个文件
      -- ------------------------------------------------------------------
      local function has_named_buf()
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(b)
            and vim.bo[b].buflisted
            and vim.bo[b].buftype == ""
            and vim.api.nvim_buf_get_name(b) ~= "" then
            return true
          end
        end
        return false
      end

      -- 扫描时跳过的"垃圾"目录与隐藏项
      local junk = {
        [".git"] = true, ["node_modules"] = true, ["target"] = true,
        ["build"] = true, ["dist"] = true, [".venv"] = true, ["venv"] = true,
        [".cache"] = true, ["__pycache__"] = true, [".next"] = true,
        [".dart_tool"] = true, [".idea"] = true, [".vscode"] = true,
      }

      -- 有界递归扫描，返回第一个常规文件的绝对路径（找不到返回 nil）
      local function first_file(root, max_depth)
        local uv = vim.uv
        local function scan(dir, depth)
          local handle = uv.fs_scandir(dir)
          if not handle then return nil end
          local entries = {}
          while true do
            local nm, ty = uv.fs_scandir_next(handle)
            if not nm then break end
            entries[#entries + 1] = { nm = nm, ty = ty, full = dir .. "/" .. nm }
          end
          table.sort(entries, function(a, b) return a.nm < b.nm end)
          for _, en in ipairs(entries) do
            local hidden = en.nm:sub(1, 1) == "."
            if not hidden and not junk[en.nm] then
              if en.ty == "file" then
                return en.full
              elseif en.ty == "directory" and depth > 0 then
                local r = scan(en.full, depth - 1)
                if r then return r end
              end
            end
          end
          return nil
        end
        return scan(root, max_depth)
      end

      local function ensure_file_open()
        -- 已有文件（如 session 恢复出来的）就不动
        if has_named_buf() then return end
        local root = vim.fn.getcwd()
        -- 优先常见的入口文件，没有再做有界扫描
        local found
        for _, e in ipairs({ "README.md", "README", "readme.md", "README.org" }) do
          if vim.fn.filereadable(root .. "/" .. e) == 1 then
            found = root .. "/" .. e
            break
          end
        end
        found = found or first_file(root, 3)
        if not found then return end
        vim.cmd("edit " .. vim.fn.fnameescape(found))
        -- 顺手清掉残留的空 [No Name] 缓冲，保持 buffer 列表干净
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(b)
            and vim.api.nvim_buf_get_name(b) == ""
            and vim.api.nvim_buf_line_count(b) <= 1
            and not vim.bo[b].modified then
            pcall(vim.cmd, "silent! bwipeout " .. b)
          end
        end
      end

      -- 包装 open_project：所有入口（telescope / reopen）都走 manage.open_project
      local manage = require("projectmgr.manage")
      local orig_open = manage.open_project
      manage.open_project = function(name)
        orig_open(name)
        pcall(ensure_file_open)
      end
      projectmgr.open_project = manage.open_project
    end,
  },
}
