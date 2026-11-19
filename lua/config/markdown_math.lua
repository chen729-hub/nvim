-- Keep formula conversion in render-markdown/utftex. Use render-markdown's
-- native line replacement for standalone $$ blocks, including their delimiters.
local M = {}

function M.parse(ctx)
  local marks = require("render-markdown.handler.latex").parse(ctx)
  if not ctx.last or #marks == 0 then
    return marks
  end

  local blocks = {}
  local context = require("render-markdown.request.context").get(ctx.buf)
  for _, node in ipairs(context.latex:get()) do
    if node.start_row < node.end_row then
      local first = vim.api.nvim_buf_get_lines(ctx.buf, node.start_row, node.start_row + 1, false)[1]
      local last = vim.api.nvim_buf_get_lines(ctx.buf, node.end_row, node.end_row + 1, false)[1]
      -- Never collapse prose sharing a delimiter line, or inline formulas.
      if first and last and first:match("^%s*%$%$%s*$") and last:match("^%s*%$%$%s*$") then
        blocks[node.start_row] = node
      end
    end
  end

  for _, mark in ipairs(marks) do
    local node = blocks[mark.start_row]
    local lines = mark.opts.virt_lines
    if node and lines and #lines > 0 and mark.opts.virt_lines_above then
      -- Keep the source visible when the upstream converter reports failure.
      local failed = #lines == 1 and #lines[1] == 1 and vim.trim(lines[1][1][1]) == "error"
      if not failed then
        mark.replace = lines
        mark.conceal = true
        mark.start_col = 0
        mark.opts = {
          end_row = node.end_row,
          end_col = node.end_col,
          conceal_lines = "",
        }
      end
    end
  end
  return marks
end

return M
