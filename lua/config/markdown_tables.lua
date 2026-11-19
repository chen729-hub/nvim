-- Extend the table renderer so separators participate in its wrapped-row
-- replacements, visibility, and cleanup. Source-line extmarks disappear when
-- render-markdown conceals a row to replace it with wrapped virtual lines.
local M = {}

function M.setup()
  local renderer = require("render-markdown.render.markdown.table")
  if renderer._user_row_separators then return end
  renderer._user_row_separators = true
  local border = renderer.border

  -- This adapter uses render-markdown's internal table API. Keep it here,
  -- outside the managed plugin directory, so Lazy updates preserve the change.
  function renderer:border(wrapped)
    border(self, wrapped)
    if not vim.tbl_contains({ "padded", "trimmed" }, self.config.cell) then return end

    local chars, parts = self.config.border, {}
    for _, col in ipairs(self.data.cols) do
      parts[#parts + 1] = chars[11]:rep(col.width)
    end
    local text = chars[4] .. table.concat(parts, chars[5]) .. chars[6]
    local line = self:line():pad(self.data.layout.col):text(text, self.config.row)
    local separator = self:indent():line(true):extend(line):get()

    for i = 1, #self.data.rows - 1 do
      local row, following = self.data.rows[i], self.data.rows[i + 1]
      -- The header already has a Markdown delimiter. Only join adjacent
      -- data rows; the parser may return a subset of a very large table.
      if row.node.type == "pipe_table_row"
        and following.node.start_row == row.node.start_row + 1 then
        if wrapped[i] then
          wrapped[i][#wrapped[i] + 1] = separator
        else
          self.marks:add(self.config, "virtual_lines", row.node.start_row, 0, {
            virt_lines = { separator },
            virt_lines_above = false,
          })
        end
      end
    end
  end

  -- Remove marks from the previous source-line callback during live reload.
  local old_ns = vim.api.nvim_create_namespace("user_markdown_table_separators")
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    vim.api.nvim_buf_clear_namespace(buf, old_ns, 0, -1)
  end
end

return M
