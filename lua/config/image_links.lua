local M = {}

local function unescape(value)
  return value:gsub("\\([\\%[%]%(%)<> ])", "%1"):gsub("&amp;", "&")
end

local function destination(text, start)
  local i = start
  while text:sub(i, i):match("%s") do i = i + 1 end
  if text:sub(i, i) == "<" then
    local finish = text:find(">", i + 1, true)
    if finish then return unescape(text:sub(i + 1, finish - 1)), finish end
    return nil
  end
  local depth, first = 0, i
  while i <= #text do
    local char = text:sub(i, i)
    if char == "\\" then
      i = i + 2
    elseif char == "(" then
      depth, i = depth + 1, i + 1
    elseif char == ")" then
      if depth == 0 then break end
      depth, i = depth - 1, i + 1
    elseif char:match("%s") and depth == 0 then
      break
    else
      i = i + 1
    end
  end
  if i > first then return unescape(text:sub(first, i - 1)), i end
end

local extensions = { png = true, jpg = true, jpeg = true, webp = true, gif = true,
  bmp = true, tif = true, tiff = true, ico = true, avif = true }

local function image_path(value)
  local path = value:lower():match("^[^?#]+") or ""
  return extensions[path:match("%.([%w]+)$")] == true
end

local function candidates(lines, row)
  local line, candidates, i = lines[row] or "", {}, 1
  while i <= #line do
    local first, last, bang, label = line:find("(!?)%[([^%]]*)%]", i)
    if not first then break end
    local nextchar, value, finish = line:sub(last + 1, last + 1), nil, last
    if nextchar == "(" then
      value, finish = destination(line, last + 2)
      if finish then
        -- destination() stops before the outer ')' or optional title.
        local tail = line:sub(finish)
        local closing = tail:match("^%s*%)") or tail:match('^%s*"[^"]*"%s*%)')
          or tail:match("^%s*'[^']*'%s*%)") or tail:match("^>%s*%)")
          or tail:match('^>%s*"[^"]*"%s*%)') or tail:match("^>%s*'[^']*'%s*%)")
        if closing then finish = finish + #closing - 1 else value = nil end
      end
    else
      local ref = nextchar == "[" and line:match("^%[([^%]]*)%]", last + 1) or label
      if nextchar == "[" then
        local ending = line:find("]", last + 2, true)
        if ending then finish = ending end
      end
      if ref == "" then ref = label end
      if ref and nextchar ~= ":" then
        ref = ref:lower():gsub("%s+", " ")
        for _, definition in ipairs(lines) do
          local name, rest = definition:match("^%s*%[([^%]]+)%]:%s*(.+)$")
          if name and name:lower():gsub("%s+", " ") == ref then
            value = destination(rest, 1)
            break
          end
        end
      end
    end
    if value and (bang == "!" or image_path(value) or image_path(label)) then
      candidates[#candidates + 1] = { first, finish or last, value, label }
    end
    i = math.max(last + 1, (finish or last) + 1)
  end
  for first, target, last in line:gmatch("()!%[%[([^%]]+)%]%]()") do
    candidates[#candidates + 1] = { first, last - 1, target:match("^[^|]+"), target:match("^[^|]+") }
  end
  return candidates
end

function M.find_image(lines, row, column, strict)
  local found = candidates(lines, row)
  for _, c in ipairs(found) do
    if column >= c[1] and column <= c[2] then return c[3] end
  end
  if not strict and #found == 1 then return found[1][3] end
end

function M.find(lines, row, column)
  local found = M.find_image(lines, row, column)
  if found then return found end
  for first, value, last in (lines[row] or ""):gmatch("()(https?://[^%s<>\"']+)()") do
    if column >= first and column <= last then return value end
  end
end

-- A standalone image gets its own space in the document. Ordinary Markdown
-- links to image files also qualify, including [image.png](...image.webp).
-- Code examples, frontmatter and prose links are left as source.
function M.blocks(lines)
  local blocks, fence, fence_size = {}, nil, 0
  local frontmatter = lines[1] == "---"
  for row, line in ipairs(lines) do
    local indent, marker = line:match("^( *)([`~]+)")
    if frontmatter then
      if row > 1 and (line == "---" or line == "...") then frontmatter = false end
    elseif fence then
      if marker and #indent < 4 and #marker >= fence_size
          and line:match("^ *" .. fence .. "+%s*$") then fence = nil end
    elseif marker and #indent < 4 and #marker >= 3
        and not marker:find("[^" .. marker:sub(1, 1) .. "]") then
      fence, fence_size = marker:sub(1, 1), #marker
    elseif not line:match("^    ") and not line:match("^\t") then
      for _, item in ipairs(candidates(lines, row)) do
        if line:sub(1, item[1] - 1):match("^%s*$") and line:sub(item[2] + 1):match("^%s*$") then
          blocks[#blocks + 1] = { row = row, source = item[3], label = item[4], text = line }
          break
        end
      end
    end
  end
  return blocks
end

function M.resolve(value, base)
  value = vim.trim(value)
  if value:match("^<.*>$") or value:match('^".*"$') then value = value:sub(2, -2) end
  if value:lower():match("^https?://") then return value end
  if value:match("^file://") then
    value = vim.uri_to_fname(value)
  elseif value:match("^[%a][%w+.-]*:") and not value:match("^%a:[/\\]") then
    return nil, "请输入 HTTP(S) 图片网址或本地图片路径"
  else
    value = value:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end)
  end
  value = vim.fn.expand(value)
  if not value:match("^%a:[/\\]") and not value:match("^[/\\]") then value = base .. "/" .. value end
  return vim.fs.normalize(value)
end

return M
