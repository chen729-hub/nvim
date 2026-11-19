-- Standalone: nvim --headless -u NONE -i NONE -l tests/tree-sort.lua
-- Read the configured comparator without loading plugins or touching notes.
local ok, err = xpcall(function()
  local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
  local saved = {}
  for _, name in ipairs({ "neo-tree", "neo-tree.defaults", "config.chinese" }) do
    saved[name] = package.loaded[name]
  end
  local options
  package.loaded["neo-tree"] = { setup = function(value) options = value end }
  local window = { mappings = {} }
  package.loaded["neo-tree.defaults"] = {
    window = window, filesystem = { window = window }, buffers = { window = window }, git_status = { window = window },
  }
  package.loaded["config.chinese"] = dofile(root .. "/lua/config/chinese.lua")
  local configured, config_error = pcall(function()
    for _, spec in ipairs(dofile(root .. "/lua/plugins/tools.lua")) do
      if spec[1] == "nvim-neo-tree/neo-tree.nvim" then spec.config() end
    end
  end)
  for _, name in ipairs({ "neo-tree", "neo-tree.defaults", "config.chinese" }) do
    package.loaded[name] = saved[name]
  end
  assert(configured, config_error)
  local compare = assert(options and options.sort_function, "sort_function not configured")
  local entries = {
    { name = "10 附录", type = "directory" },
    { name = "2 实战", type = "directory" },
    { name = "普通笔记.md", type = "file" },
    { name = "01 入门.md", type = "file" },
    { name = "1 基础", type = "directory" },
    { name = "02 练习.md", type = "file" },
    { name = "00 总览", type = "directory" },
    { name = "0 索引.md", type = "file" },
    { name = "未编号目录", type = "directory" },
  }
  table.sort(entries, compare)
  local expected = { "0 索引.md", "00 总览", "01 入门.md", "1 基础", "02 练习.md", "2 实战", "10 附录", "普通笔记.md", "未编号目录" }
  for index, entry in ipairs(entries) do
    assert(entry.name == expected[index], "wrong order at " .. index .. ": " .. entry.name)
    assert(not compare(entry, entry), "comparator must be irreflexive")
    for next_index = index + 1, #entries do
      assert(compare(entry, entries[next_index]), "inconsistent ascending order")
      assert(not compare(entries[next_index], entry), "inconsistent descending order")
    end
  end
  -- Flipping every type must leave the sequence identical.
  for _, entry in ipairs(entries) do
    entry.type = entry.type == "directory" and "file" or "directory"
  end
  table.sort(entries, function(a, b) return compare(b, a) end)
  table.sort(entries, compare)
  for index, entry in ipairs(entries) do assert(entry.name == expected[index], "type affected ordering") end
  assert(compare({ path = "foo", type = "dir" }, { path = "foo", type = "file" }) == false)
  assert(compare({}, {}) == false)
  print("Tree sorting passed: mixed files/directories, 0/00, 1/01, 2/02/10, ties and unnumbered names")
end, debug.traceback)
if not ok then
  vim.api.nvim_err_writeln(tostring(err))
  vim.cmd("cquit 1")
end
