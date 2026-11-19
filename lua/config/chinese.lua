-- 只翻译界面标签；命令、映射动作、路径和未知的原始错误保持不变。
local M = {}

local modes = {
  NORMAL = "普通", ["O-PENDING"] = "等待操作", VISUAL = "可视", ["V-LINE"] = "可视行",
  ["V-BLOCK"] = "可视块", SELECT = "选择", ["S-LINE"] = "选择行", ["S-BLOCK"] = "选择块",
  INSERT = "插入", REPLACE = "替换", ["V-REPLACE"] = "虚拟替换", COMMAND = "命令",
  EX = "扩展命令", MORE = "更多", CONFIRM = "确认", SHELL = "外壳", TERMINAL = "终端",
}

function M.mode(value)
  return modes[value] or value
end

local labels = {
  ["Run program"] = "运行程序", ["Indent left"] = "减少缩进", ["Indent right"] = "增加缩进",
  ["Visual Line"] = "可视行", Change = "修改", Delete = "删除", Uppercase = "转为大写",
  Lowercase = "转为小写", ["Toggle case"] = "切换大小写", Format = "格式化", Replace = "替换",
  Visual = "可视选择", Yank = "复制", ["Create fold"] = "创建折叠",
  ["End of line"] = "行尾", ["Matching (){}[]"] = "匹配的括号", ["Start of line"] = "行首",
  ["Move to prev char"] = "向前查找字符", ["Last line"] = "末行", ["Move before prev char"] = "向前查找字符前一位",
  ["Start of line (non ws)"] = "行首非空白字符", ["Prev word"] = "上一个单词", ["Next end of word"] = "下一个词尾",
  ["Move to next char"] = "向后查找字符", ["Prev end of word"] = "上一个词尾", ["First line"] = "首行",
  Left = "左移", Down = "下移", Up = "上移", Right = "右移", ["Move before next char"] = "向后查找字符前一位",
  ["Next word"] = "下一个单词", ["Prev empty line"] = "上一空行", ["Next empty line"] = "下一空行",
  ["Next ftFT"] = "重复字符查找", ["Prev ftFT"] = "反向字符查找", ["Search forward"] = "向后搜索",
  ["Search backward"] = "向前搜索", ["Prev WORD"] = "上一空白分隔词", ["Next end of WORD"] = "下一空白分隔词尾",
  ["Next WORD"] = "下一空白分隔词", around = "包含边界", inside = "内部",
  ['" string'] = "双引号字符串", ["' string"] = "单引号字符串", ["` string"] = "反引号字符串",
  ["[(]) block"] = "圆括号块", ["<> block"] = "尖括号块", ["[{]} block"] = "花括号块", ["[] block"] = "方括号块",
  ["WORD with ws"] = "空白分隔词及空白", paragraph = "段落", sentence = "句子", ["tag block"] = "标签块",
  ["word with ws"] = "单词及空白", ['inner " string'] = "双引号内部", ["inner ' string"] = "单引号内部",
  ["inner ` string"] = "反引号内部", ["inner [(])"] = "圆括号内部", ["inner <>"] = "尖括号内部",
  ["inner [{]}"] = "花括号内部", ["inner []"] = "方括号内部", ["inner WORD"] = "空白分隔词内部",
  ["inner paragraph"] = "段落内部", ["inner sentence"] = "句子内部", ["inner tag block"] = "标签内部",
  ["inner word"] = "单词内部", window = "窗口",
  ["Increase height"] = "增加高度", ["Decrease height"] = "减小高度", ["Decrease width"] = "减小宽度",
  ["Equally high and wide"] = "均分窗口", ["Increase width"] = "增加宽度", ["Break out into a new tab"] = "移到新标签页",
  ["Max out the height"] = "最大化高度", ["Go to the left window"] = "切换到左侧窗口",
  ["Go to the down window"] = "切换到下方窗口", ["Go to the up window"] = "切换到上方窗口",
  ["Go to the right window"] = "切换到右侧窗口", ["Close all other windows"] = "关闭其他窗口",
  ["Quit a window"] = "关闭窗口", ["Split window"] = "上下分屏", ["Split window vertically"] = "左右分屏",
  ["Switch windows"] = "切换窗口", ["Swap current with next"] = "与下个窗口交换", ["Max out the width"] = "最大化宽度",
  ["Move window to far left"] = "窗口移到最左侧", ["Move window to far bottom"] = "窗口移到最下方",
  ["Move window to far top"] = "窗口移到最上方", ["Move window to far right"] = "窗口移到最右侧",
  ["Top this line"] = "当前行移到顶部", ["Spelling suggestions"] = "拼写建议", ["Toggle all folds under cursor"] = "切换此处所有折叠",
  ["Close all folds under cursor"] = "关闭此处所有折叠", ["Delete all folds under cursor"] = "删除此处所有折叠",
  ["Delete all folds in file"] = "删除文件中所有折叠", ["Half screen to the left"] = "向左滚动半屏",
  ["Half screen to the right"] = "向右滚动半屏", ["Close all folds"] = "关闭所有折叠", ["Open all folds under cursor"] = "展开此处所有折叠",
  ["Open all folds"] = "展开所有折叠", ["Toggle fold under cursor"] = "切换当前折叠", ["Bottom this line"] = "当前行移到底部",
  ["Close fold under cursor"] = "关闭当前折叠", ["Delete fold under cursor"] = "删除当前折叠", ["Right this line"] = "当前列移到右侧",
  ["Add word to spell list"] = "加入拼写词典", ["Toggle folding"] = "切换折叠功能", ["Fold more"] = "增加折叠层级",
  ["Open fold under cursor"] = "展开当前折叠", ["Fold less"] = "减少折叠层级", ["Left this line"] = "当前列移到左侧",
  ["Show cursor line"] = "显示当前行", ["Mark word as bad/misspelling"] = "标记为拼写错误", ["Update folds"] = "更新折叠",
  ["Center this line"] = "当前行居中", ["Home line of window (top)"] = "窗口顶部行", ["Last line of window"] = "窗口底部行",
  ["Middle line of window"] = "窗口中间行", ["Previous unmatched group"] = "上一未匹配分组", ["Previous ("] = "上一圆括号",
  ["Previous <"] = "上一尖括号", ["Previous method end"] = "上一方法结尾", ["Previous method start"] = "上一方法开头",
  ["Previous misspelled word"] = "上一拼写错误", ["Previous {"] = "上一花括号", ["Next unmatched group"] = "下一未匹配分组",
  ["Next ("] = "下一圆括号", ["Next <"] = "下一尖括号", ["Next method end"] = "下一方法结尾",
  ["Next method start"] = "下一方法开头", ["Next misspelled word"] = "下一拼写错误", ["Next {"] = "下一花括号",
  ["Cycle backwards through results"] = "反向遍历结果", ["Go to [count] newer position in change list"] = "跳到较新的修改位置",
  ["Go to [count] older position in change list"] = "跳到较早的修改位置", ["Search backwards and select"] = "向前搜索并选择",
  ["Go to previous tab page"] = "上一个标签页", ["Go to file under cursor"] = "打开光标处文件", ["Go to last insert"] = "回到上次插入位置",
  ["Search forwards and select"] = "向后搜索并选择", ["Go to next tab page"] = "下一个标签页", ["Last visual selection"] = "恢复上次选择",
  ["Open file with system app"] = "用系统应用打开", ["Code Action"] = "代码操作", ["Code Actions"] = "代码操作",
  ["Select a code action:"] = "选择代码操作：", ["Select one of:"] = "请选择：", ["keymaps"] = "快捷键",
}

function M.whichkey_desc(value)
  -- 保留 which-key 自带的命令包装清理，再按完整标签匹配，避免误改路径。
  for _, pair in ipairs({
    { "<Plug>%(?(.*)%)?", "%1" }, { "^%+", "" }, { "<[cC]md>", "" }, { "<[cC][rR]>", "" },
    { "<[sS]ilent>", "" }, { "^lua%s+", "" }, { "^call%s+", "" }, { "^:%s*", "" },
  }) do
    value = value:gsub(pair[1], pair[2])
  end
  return labels[value] or value
end

function M.telescope_pickers()
  local result = {}
  for name, title in pairs({
    find_files = "查找文件", live_grep = "全文搜索", grep_string = "搜索光标处文本", buffers = "缓冲区",
    oldfiles = "最近文件", help_tags = "帮助文档", marks = "位置标记", registers = "寄存器",
    commands = "命令列表", command_history = "命令历史", search_history = "搜索历史", keymaps = "快捷键",
    diagnostics = "诊断信息", lsp_references = "引用位置", lsp_document_symbols = "当前文件符号",
    lsp_workspace_symbols = "工作区符号", lsp_definitions = "定义位置", lsp_implementations = "实现位置",
    treesitter = "语法符号", builtin = "查找工具", current_buffer_fuzzy_find = "搜索当前文件",
    tags = "标签", current_buffer_tags = "当前文件标签", git_files = "Git 文件", git_status = "Git 修改",
    git_commits = "Git 提交记录", git_bcommits = "当前文件提交记录", git_branches = "Git 分支",
    highlights = "高亮组", colorscheme = "配色主题", filetypes = "文件类型", spell_suggest = "拼写建议",
    resume = "继续上次搜索", quickfix = "快速修复列表", loclist = "位置列表", jumplist = "跳转历史",
  }) do
    result[name] = { prompt_title = title, results_title = "结果", preview_title = "预览" }
  end
  return result
end

local tree_commands = {
  toggle_node = "展开或收起", open = "打开", cancel = "取消", open_split = "上下分屏打开", open_vsplit = "左右分屏打开",
  open_tabnew = "新标签页打开", open_with_window_picker = "选择窗口打开", close_node = "收起节点",
  close_all_nodes = "收起所有节点", expand_all_nodes = "展开所有节点", toggle_preview = "切换预览",
  focus_preview = "聚焦预览", add = "新建文件或目录", add_directory = "新建目录", delete = "删除", rename = "重命名",
  rename_basename = "重命名（保留扩展名）", copy_to_clipboard = "复制到剪贴板", cut_to_clipboard = "剪切到剪贴板",
  paste_from_clipboard = "粘贴", copy = "复制", move = "移动", close_window = "关闭文件树", refresh = "刷新",
  show_help = "快捷键帮助", prev_source = "上一视图", next_source = "下一视图", toggle_auto_expand_width = "切换自动宽度",
  toggle_hidden = "显示或隐藏隐藏文件", fuzzy_finder = "模糊查找", fuzzy_finder_directory = "查找目录",
  fuzzy_sorter = "模糊排序", filter_on_submit = "输入筛选条件", clear_filter = "清除筛选", navigate_up = "上一级目录",
  set_root = "设为根目录", show_file_details = "文件详细信息", buffer_delete = "关闭缓冲区",
  order_by_created = "按创建时间排序", order_by_diagnostics = "按诊断排序", order_by_git_status = "按 Git 状态排序",
  order_by_modified = "按修改时间排序", order_by_name = "按名称排序", order_by_size = "按大小排序", order_by_type = "按类型排序",
  git_add_all = "暂存全部修改", git_unstage_file = "取消文件暂存", git_undo_last_commit = "撤销上次提交",
  git_add_file = "暂存文件", git_toggle_file_stage = "切换文件暂存", git_revert_file = "还原文件", git_commit = "提交修改",
  git_push = "推送提交", git_commit_and_push = "提交并推送", toggle_auto_expand = "切换自动展开", jump_to_symbol = "跳转到符号",
}

function M.tree_mappings(mappings)
  local result = vim.deepcopy(mappings or {})
  for key, mapping in pairs(result) do
    local command = type(mapping) == "table" and (mapping.command or mapping[1]) or mapping
    if type(command) == "string" and tree_commands[command] then
      if type(mapping) == "string" then mapping = { mapping } end
      mapping.desc = tree_commands[command]
      if mapping.config and mapping.config.title == "Order by" then
        mapping.config.title = "排序方式"
        mapping.desc = "排序方式"
      end
      result[key] = mapping
    end
  end
  return result
end

return M
