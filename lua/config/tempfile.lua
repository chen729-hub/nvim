-- ~/.config/nvim/lua/config/tempfile.lua

local M = {}

local languages = {
  { name = "Markdown",   ft = "markdown",   ext = "md" },
  { name = "Python",     ft = "python",     ext = "py" },
  { name = "Lua",        ft = "lua",        ext = "lua" },
  { name = "C",          ft = "c",          ext = "c" },
  { name = "C++",        ft = "cpp",        ext = "cpp" },
  { name = "Shell",      ft = "sh",         ext = "sh" },
  { name = "JavaScript", ft = "javascript", ext = "js" },
  { name = "TypeScript", ft = "typescript", ext = "ts" },
  { name = "Go",         ft = "go",         ext = "go" },
  { name = "Rust",       ft = "rust",       ext = "rs" },
  { name = "Java",       ft = "java",       ext = "java" },
  { name = "HTML",       ft = "html",       ext = "html" },
  { name = "CSS",        ft = "css",        ext = "css" },
  { name = "JSON",       ft = "json",       ext = "json" },
  { name = "YAML",       ft = "yaml",       ext = "yaml" },
}

local function delete_file(file)
  if file and vim.fn.filereadable(file) == 1 then
    vim.fn.delete(file)
  end
end

local function temp_dir()
  local dir = vim.fn.stdpath("cache") .. "/tmpfiles"

  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end

  return dir
end

local function set_temp_buffer(file, lang)
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.bo.filetype = lang.ft

  vim.b.is_temp_file = true
  vim.b.temp_file_path = file
  vim.b.temp_file_lang = lang.name
  vim.b.temp_file_base = vim.fn.fnamemodify(file, ":r")
end

function M.open()
  local lang = {
    name = "Markdown",
    ft = "markdown",
    ext = "md",
  }

  local file = temp_dir() .. "/temp-" .. os.date("%Y%m%d-%H%M%S") .. "." .. lang.ext

  vim.cmd("edit " .. vim.fn.fnameescape(file))
  set_temp_buffer(file, lang)

  local bufnr = vim.api.nvim_get_current_buf()

  vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
    buffer = bufnr,
    once = true,
    callback = function()
      local ok, path = pcall(function()
        return vim.b[bufnr].temp_file_path
      end)

      if ok then
        delete_file(path)
      end
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    once = true,
    callback = function()
      local ok, path = pcall(function()
        return vim.b[bufnr].temp_file_path
      end)

      if ok then
        delete_file(path)
      end
    end,
  })
end

function M.change_type()
  if not vim.b.is_temp_file then
    vim.notify("当前缓冲区不是临时文件", vim.log.levels.WARN)
    return
  end

  vim.ui.select(languages, {
    prompt = "切换临时文件语言:",
    format_item = function(item)
      return item.name .. "  (." .. item.ext .. ")"
    end,
  }, function(choice)
    if not choice then
      return
    end

    local old_file = vim.b.temp_file_path
    local base = vim.b.temp_file_base or vim.fn.fnamemodify(old_file, ":r")
    local new_file = base .. "." .. choice.ext

    -- 改 buffer 文件名，比如 temp-xxx.md -> temp-xxx.py
    vim.cmd("file " .. vim.fn.fnameescape(new_file))

    -- 删除旧文件，避免切换后残留 temp-xxx.md
    if old_file ~= new_file then
      delete_file(old_file)
    end

    -- 重新设置 filetype，让 LSP / treesitter / 运行插件识别
    vim.bo.filetype = choice.ft

    -- 更新当前临时文件路径，退出时删除新的文件
    vim.b.temp_file_path = new_file
    vim.b.temp_file_lang = choice.name
    vim.b.temp_file_base = base

    vim.notify("已切换为 " .. choice.name .. " 临时文件")
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("TempFile", function()
    M.open()
  end, {
    desc = "打开 Markdown 临时文件",
  })

  vim.api.nvim_create_user_command("TempFileType", function()
    M.change_type()
  end, {
    desc = "切换临时文件语言",
  })
end

return M
