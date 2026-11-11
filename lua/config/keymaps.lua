local km = vim.keymap.set

local function sanitize_ident(s)
  if not s then
    return ""
  end
  return (s:gsub("[^%w_]", "")):gsub("^%d+", "") -- remove non-word, and leading digits if any
end

-- parse field name from the current line: matches "    name: Type" style
local function field_from_current_line()
  local line = vim.api.nvim_get_current_line()
  -- try to capture `name` from "name: Type" allowing whitespace
  local field = line:match("^%s*([%w_]+)%s*:")
  if field and field ~= "" then
    return field
  end
  -- fallback to word under cursor
  local cw = vim.fn.expand("<cword>")
  return sanitize_ident(cw)
end

local function detect_int_type()
  local line = vim.api.nvim_get_current_line()
  -- find first integer type like i8, i16, i32, i64, i128 (flexible)
  local t = line:match("[iu]%d+")
  if t and t ~= "" then
    return t
  end
  -- fallback: check word under cursor
  local cw = vim.fn.expand("<cword>")
  t = cw:match("[iu]%d+")
  if t and t ~= "" then
    return t
  end
  -- default
  return "i64"
end

local function insert_getter_replacing_line(return_type, body_expr_fmt)
  local buf = 0
  local row = vim.api.nvim_win_get_cursor(0)[1] -- 1-indexed
  local curline = vim.api.nvim_get_current_line()
  local indent = curline:match("^%s*") or ""

  local raw_field = field_from_current_line()
  local field = sanitize_ident(raw_field)
  if field == "" then
    vim.notify("No valid identifier on current line", vim.log.levels.WARN)
    return
  end

  local fn_name = "get_" .. field
  local body = string.format(body_expr_fmt, field)

  local lines = {
    indent .. string.format("pub fn %s(&self) -> %s {", fn_name, return_type),
    indent .. "    " .. body,
    indent .. "}",
  }

  -- replace the current line with the function
  vim.api.nvim_buf_set_lines(buf, row - 1, row, true, lines)

  -- target_row is where the original next line will now be
  local target_row = row + #lines

  -- ensure target_row exists; if not, append an empty line
  local nlines = vim.api.nvim_buf_line_count(buf)
  if target_row > nlines then
    vim.api.nvim_buf_set_lines(buf, -1, -1, true, { "" })
    nlines = nlines + 1
  end

  -- place cursor on that next/or appended line, column 0
  vim.api.nvim_win_set_cursor(0, { math.min(target_row, nlines), 0 })
end

local function insert_setter_replacing_line(param_type, assign_fmt)
  local buf = 0
  local row = vim.api.nvim_win_get_cursor(0)[1] -- 1-indexed
  local curline = vim.api.nvim_get_current_line()
  local indent = curline:match("^%s*") or ""

  local raw_field = field_from_current_line()
  local field = sanitize_ident(raw_field)
  if field == "" then
    vim.notify("No valid identifier on current line", vim.log.levels.WARN)
    return
  end

  local fn_name = "set_" .. field

  local lines = {
    indent .. string.format("pub fn %s(&mut self, value: %s) -> &mut Self {", fn_name, param_type),
    indent .. "    " .. string.format(assign_fmt, field),
    indent .. "    self",
    indent .. "}",
  }

  vim.api.nvim_buf_set_lines(buf, row - 1, row, true, lines)

  local target_row = row + #lines
  local nlines = vim.api.nvim_buf_line_count(buf)
  if target_row > nlines then
    vim.api.nvim_buf_set_lines(buf, -1, -1, true, { "" })
    nlines = nlines + 1
  end

  vim.api.nvim_win_set_cursor(0, { math.min(target_row, nlines), 0 })
end

local function insert_int_getter_from_line()
  local ty = detect_int_type()
  insert_getter_replacing_line(ty, "self.%s")
end

local function insert_int_setter_from_line()
  local ty = detect_int_type()
  insert_setter_replacing_line(ty, "self.%s = value;")
end

-- Mappings: leader+fs -> &str getter, leader+fi -> i64 getter
km("n", "<leader>fgs", function()
  insert_getter_replacing_line("&str", "&self.%s")
end, { noremap = false, silent = true, desc = "get &str" })
km(
  "n",
  "<leader>fgi",
  insert_int_getter_from_line,
  { noremap = false, silent = true, desc = "get integer/same format" }
)
km("n", "<leader>fss", function()
  insert_setter_replacing_line("&str", "self.%s = value.to_string();")
end, { noremap = false, silent = true, desc = "insert &str" })
km(
  "n",
  "<leader>fsi",
  insert_int_setter_from_line,
  { noremap = false, silent = true, desc = "insert integer/same format" }
)

-- Macros Example down below
-- km('n', '<leader>fvs', '<cmd>norm ^yiwo<esc>p<CR>', { noremap = true, silent = true})
km(
  "n",
  "<leader>fvs",
  '0w"ayiwipub<space>fn<space>insert_<Esc>f:i(&mut self, <Esc>"apa: &str)<Esc>f:<S-C> -> &mut Self {<Esc>oself.<Esc>"apa.push(<Esc>"apa.to_string());<Esc>oself<Esc>o}<Esc>j',
  { noremap = true, silent = true }
)

km(
  "n",
  "<leader>fvi",
  '0w"ayiwipub<space>fn<space>insert_<Esc>f:i(&mut self, <Esc>"apa<Esc>f<w"byiwF:lD"bpa) -> &mut Self {<Esc>oself.<Esc>"apa.push(<Esc>"apa);<Esc>oself<Esc>o}<Esc>j',
  { noremap = true, silent = true }
)

km("n", "<leader>fo", "0f:wvt,cOption<<Esc>pa><Esc>j", { noremap = true, silent = true })

km("n", "<leader>vv", function()
  require("telescope.builtin").lsp_document_symbols({
    symbols = { "Variable", "Constant", "Field" },
  })
end, { desc = "Document Variables" })

vim.keymap.set("v", "<leader>ya", function()
  -- 1. Capture coordinates immediately
  local s_line = vim.fn.line("v")
  local e_line = vim.fn.line(".")
  local start_col = vim.fn.col("v")

  -- 2. Exit visual mode to prevent crashes/UI collisions
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)

  vim.schedule(function()
    -- Interactive inputs
    local n_str = vim.fn.input("Yank every n-th line: ", "2")
    local n = tonumber(n_str) or 1
    if n < 1 then
      n = 1
    end

    local delim = vim.fn.input("Delimiter (Empty for whole line): ")

    -- IMPROVEMENT: Default to '+' (System Clipboard) for cross-terminal support
    local reg = vim.fn.input("Register (default '+'): ", "+")
    if reg == "" then
      reg = "+"
    end
    reg = reg:sub(1, 1)

    -- Normalize line order
    if s_line > e_line then
      s_line, e_line = e_line, s_line
    end

    local lines = vim.api.nvim_buf_get_lines(0, s_line - 1, e_line, false)
    if not lines or #lines == 0 then
      return
    end

    local out = {}
    for i = 1, #lines, n do
      local line = lines[i] or ""
      -- Substring from the visual start column
      local content = line:sub(start_col)

      if delim ~= "" then
        local found = content:find(delim, 1, true)
        if found then
          content = content:sub(1, found - 1)
        end
      end
      table.insert(out, content)
    end

    if #out > 0 then
      local result = table.concat(out, "\n")
      -- 3. Set the register.
      -- Using 'v' as the third argument ensures it's treated as character-wise or block
      vim.fn.setreg(reg, result, "v")

      -- OPTIONAL: Also sync to unnamed register so 'p' works immediately
      vim.fn.setreg('"', result, "v")

      vim.notify(string.format("Yanked %d items into '%s'", #out, reg), vim.log.levels.INFO)
    else
      vim.notify("No content to yank", vim.log.levels.WARN)
    end
  end)
end, { noremap = true, silent = true, desc = "Yank every n-th slice to clipboard" })

if not detect_int_type then
  function detect_int_type()
    local line = vim.api.nvim_get_current_line()
    local t = line:match("([iu]%d+)")
    if t and t ~= "" then
      return t
    end
    local cw = vim.fn.expand("<cword>")
    t = cw:match("([iu]%d+)")
    if t and t ~= "" then
      return t
    end
    return "i64"
  end
end

local function trim(s)
  return (s or ""):match("^%s*(.-)%s*$")
end

local function is_integer_type(t)
  if not t then
    return false
  end
  t = trim(t)
  if t:match("^[iu]%d+$") then
    return true
  end
  if t == "isize" or t == "usize" then
    return true
  end
  return false
end

local function generate_rust_setter()
  local line = vim.api.nvim_get_current_line()
  local cur = vim.api.nvim_win_get_cursor(0)
  local row = cur[1] - 1

  -- 1. Parse "name: type,"
  local name, raw_type = line:match("^%s*([%w_]+)%s*:%s*(.-)%s*,?%s*$")
  if not name or not raw_type or raw_type == "" then
    vim.notify("Could not parse a field declaration on this line.", vim.log.levels.WARN)
    return
  end
  raw_type = trim(raw_type)

  -- 2. Detect Option<Inner>
  local inner = raw_type:match("^Option%s*<%s*(.-)%s*>$")
  local is_option = inner ~= nil
  if is_option then
    inner = trim(inner)
  end

  local indent = line:match("^(%s*)") or ""
  local fn_indent = indent .. "    "
  local fn_name = "set_" .. name

  local param_type, body_line

  if is_option then
    -- For Option<T>, we usually want to pass the Option directly
    param_type = "Option<" .. inner .. ">"
    body_line = "self." .. name .. " = value;"
  else
    -- Handle plain types
    if is_integer_type(raw_type) or raw_type == "bool" then
      param_type = raw_type
      body_line = "self." .. name .. " = value;"
    elseif raw_type == "String" then
      -- Using String here for simplicity; you could use &str and .to_string() if preferred
      param_type = "String"
      body_line = "self." .. name .. " = value;"
    else
      -- Generic fallback for custom types/structs
      param_type = raw_type
      body_line = "self." .. name .. " = value;"
    end
  end

  -- 3. Assemble the lines
  local lines = {
    indent .. "pub fn " .. fn_name .. "(&mut self, value: " .. param_type .. ") -> &mut Self {",
    fn_indent .. body_line,
    fn_indent .. "self",
    indent .. "}",
  }

  -- 4. Replace line and move cursor
  vim.api.nvim_buf_set_lines(0, row, row + 1, false, lines)
  local target_row = row + #lines
  if target_row >= vim.api.nvim_buf_line_count(0) then
    vim.api.nvim_buf_set_lines(0, -1, -1, false, { "" })
  end
  vim.api.nvim_win_set_cursor(0, { target_row + 1, 0 })

  vim.notify("Generated setter '" .. fn_name .. "'", vim.log.levels.INFO)
end

-- Map it to <leader>rs

local function generate_rust_getter()
  local line = vim.api.nvim_get_current_line()
  local cur = vim.api.nvim_win_get_cursor(0) -- {row, col}
  local row = cur[1] - 1 -- 0-indexed for buffer ops

  -- parse "name: type," allowing underscores and whitespace
  local name, raw_type = line:match("^%s*([%w_]+)%s*:%s*(.-)%s*,?%s*$")
  if not name or not raw_type or raw_type == "" then
    vim.notify("Could not parse a field declaration on this line.", vim.log.levels.WARN)
    return
  end
  raw_type = trim(raw_type)

  -- detect Option<Inner> or plain type
  local inner = raw_type:match("^Option%s*<%s*(.-)%s*>$")
  local is_option = inner ~= nil
  if is_option then
    inner = trim(inner)
  end

  if is_option and (inner == "" or not inner) then
    inner = detect_int_type()
  end
  if not is_option and (raw_type == "" or not raw_type) then
    raw_type = detect_int_type()
  end

  local indent = line:match("^(%s*)") or ""
  local fn_indent = indent .. "    "

  local fn_name = "get_" .. name
  local ret_type, body_line

  if is_option then
    if is_integer_type(inner) then
      ret_type = "Option<" .. inner .. ">"
      body_line = "self." .. name
    elseif inner == "String" then
      ret_type = "Option<&String>"
      body_line = "self." .. name .. ".as_ref()"
    else
      ret_type = "Option<&" .. inner .. ">"
      body_line = "self." .. name .. ".as_ref()"
    end
  else
    local t = raw_type
    if is_integer_type(t) then
      ret_type = t
      body_line = "self." .. name
    elseif t == "String" then
      ret_type = "&str"
      body_line = "&self." .. name
    else
      ret_type = "&" .. t
      body_line = "&self." .. name
    end
  end

  -- assemble function (replace the original field line with these lines)
  local lines = {
    indent .. "pub fn " .. fn_name .. "(&self) -> " .. ret_type .. " {",
    fn_indent .. body_line,
    indent .. "}",
  }

  -- replace current line (row .. row+1) with function lines
  vim.api.nvim_buf_set_lines(0, row, row + 1, false, lines)

  -- compute target row (line immediately after final '}'), 0-indexed
  local target_row = row + #lines

  -- ensure there is at least one line after the inserted function; if not, append a blank line
  local line_count = vim.api.nvim_buf_line_count(0)
  if target_row >= line_count then
    vim.api.nvim_buf_set_lines(0, line_count, line_count, false, { "" })
    line_count = vim.api.nvim_buf_line_count(0)
  end

  -- put the cursor at the first column of the line after the function
  vim.api.nvim_win_set_cursor(0, { target_row + 1, 0 })

  vim.notify("Replaced field with getter '" .. fn_name .. "' -> " .. ret_type, vim.log.levels.INFO)
end

-- mapping (normal mode): <leader>rg to generate getter from current line
km({ "n" }, "<leader>rg", function()
  generate_rust_getter()
end, { noremap = true, silent = true, desc = "Generate Rust getter from field declaration (replace line)" })

km("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next Buffer" })

km("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Previous Buffer" })

km("n", "<leader>rs", generate_rust_setter, { noremap = true, silent = true, desc = "Generate Rust setter" })

-- vim.keymap.set("n", "<leader>pn", function()
-- 	local col = vim.fn.col(".")
-- 	local sw = vim.fn.shiftwidth()
-- 	vim.cmd("normal! " .. (col + sw) .. "|")
-- end, { desc = "Jump to next indent column" })
--
-- -- Jump backward one indent level horizontally
-- vim.keymap.set("n", "<leader>pp", function()
-- 	local col = vim.fn.col(".")
-- 	local sw = vim.fn.shiftwidth()
-- 	vim.cmd("normal! " .. math.max(1, col - sw) .. "|")
-- end, { desc = "Jump to prev indent column" })


vim.keymap.set("n","<leader>e", "<leader>fE", { desc = "Explorer Snacks (cwd)", remap = true})
vim.keymap.set("n","<leader>E", "<leader>fe", { desc = "Explorer Snacks (rwd)", remap = true})


vim.keymap.set("n", "<leader>tr", function()
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    client:stop()
  end

  vim.cmd("edit")
  vim.notify("LSP restarted for Typst")
end, { desc = "Typst/LSP Restart" })


vim.keymap.set("n", "<leader>re", function()
    local win = vim.api.nvim_get_current_win()
    local cword = vim.fn.expand("<cword>")
    -- 1. Grab the full WORD under cursor (e.g., 'client_contacts::Column,')
    local full_prefix = vim.fn.expand("<cWORD>")
    -- Strip any trailing punctuation (like commas or brackets) from the end
    full_prefix = full_prefix:gsub("[^%w_:]+$", "")

    local clients = vim.lsp.get_clients({ bufnr = 0, name = "rust-analyzer" })
    if #clients == 0 then clients = vim.lsp.get_clients({ bufnr = 0 }) end

    local encoding = clients[1] and clients[1].offset_encoding or "utf-16"
    -- 2. Ask rust-analyzer for the definition location
    local params = vim.lsp.util.make_position_params(win, encoding)
    local responses = vim.lsp.buf_request_sync(0, "textDocument/definition", params, 2000)
    if not responses or vim.tbl_isempty(responses) then
        vim.notify("No LSP definition found", vim.log.levels.WARN)
        return
    end

    local result
    for _, resp in pairs(responses) do
        if resp.result and not vim.tbl_isempty(resp.result) then
            result = resp.result[1] or resp.result
            break
        end
    end

    if not result then return end

    -- 3. Load the target buffer (entity file) in the background
    local uri = result.uri or result.targetUri
    local bufnr = vim.uri_to_bufnr(uri)
    vim.fn.bufload(bufnr)
    local start_line = (result.range or result.targetSelectionRange).start.line
    -- Read the next 50 lines from the entity file to parse the variants
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, start_line + 50, false)
    local variants = {}
    local inside_enum = false
    for _, l in ipairs(lines) do
        if l:match("enum%s+" .. cword) then
            inside_enum = true
        elseif inside_enum and l:match("^%s*}") then
            break
        elseif inside_enum then
            -- Match standard SeaORM enum variants (Capitalized, ignoring macros)
            local variant = l:match("^%s*([A-Z][%w_]*)%s*,?")
            if variant then
                -- Add variant without hardcoded spacing, formatting handles it later
                table.insert(variants, full_prefix .. "::" .. variant .. ",")
            end
        end
    end

    -- 4. Replace the current line and format
    if #variants > 0 then
        local r = vim.api.nvim_win_get_cursor(0)[1]
        -- Replace the current line (r - 1 to r) with the variants array
        vim.api.nvim_buf_set_lines(0, r - 1, r, false, variants)
        -- Move the cursor back into the inserted block and format inside the brackets
        vim.api.nvim_win_set_cursor(0, { r, 0 })
        vim.cmd("normal! vi[=")
        vim.notify("Filled " .. #variants .. " variants!", vim.log.levels.INFO)
    else
        vim.notify("Could not parse variants.", vim.log.levels.WARN)
    end
end, { desc = "Fill Enum Variants from LSP" })

vim.keymap.set("n", "<leader>rf", function()
    local win = vim.api.nvim_get_current_win()
    local cword = vim.fn.expand("<cword>")
    -- 1. Grab the full WORD under cursor (e.g., 'ArticleContent::Column,')
    local full_prefix = vim.fn.expand("<cWORD>")
    -- Strip any trailing punctuation (like commas or brackets) from the end
    full_prefix = full_prefix:gsub("[^%w_:]+$", "")

    -- Extract base module: "ArticleContent::Column" -> "ArticleContent::Entity"
    -- If no prefix is present (just "Column"), falls back to "Entity"
    local base_module = full_prefix:match("^(.*)::[^:]+$")
    local entity_prefix = base_module and (base_module .. "::Entity") or "Entity"

    local clients = vim.lsp.get_clients({ bufnr = 0, name = "rust-analyzer" })
    if #clients == 0 then clients = vim.lsp.get_clients({ bufnr = 0 }) end

    local encoding = clients[1] and clients[1].offset_encoding or "utf-16"
    -- 2. Ask rust-analyzer for the definition location
    local params = vim.lsp.util.make_position_params(win, encoding)
    local responses = vim.lsp.buf_request_sync(0, "textDocument/definition", params, 2000)
    if not responses or vim.tbl_isempty(responses) then
        vim.notify("No LSP definition found", vim.log.levels.WARN)
        return
    end

    local result
    for _, resp in pairs(responses) do
        if resp.result and not vim.tbl_isempty(resp.result) then
            result = resp.result[1] or resp.result
            break
        end
    end

    if not result then return end

    -- 3. Load the target buffer (entity file) in the background
    local uri = result.uri or result.targetUri
    local bufnr = vim.uri_to_bufnr(uri)
    vim.fn.bufload(bufnr)
    local start_line = (result.range or result.targetSelectionRange).start.line
    -- Read the next 50 lines from the entity file to parse the variants
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, start_line + 50, false)
    local variants = {}
    local inside_enum = false
    for _, l in ipairs(lines) do
        if l:match("enum%s+" .. cword) then
            inside_enum = true
        elseif inside_enum and l:match("^%s*}") then
            break
        elseif inside_enum then
            -- Match standard SeaORM enum variants (Capitalized, ignoring macros)
            local variant = l:match("^%s*([A-Z][%w_]*)%s*,?")
            if variant then
                -- Add variant formatted as: (ArticleContent::Entity, ArticleContent::Column::Variant),
                table.insert(variants, string.format("(%s, %s::%s),", entity_prefix, full_prefix, variant))
            end
        end
    end

-- 4. Replace the current line and format
    if #variants > 0 then
        local r = vim.api.nvim_win_get_cursor(0)[1]
        -- Replace the current line (r - 1 to r) with the variants array
        vim.api.nvim_buf_set_lines(0, r - 1, r, false, variants)
        -- Move the cursor back into the inserted block and format inside brackets
        vim.api.nvim_win_set_cursor(0, { r, 0 })
        pcall(function()
            vim.cmd("normal! vi[=")
        end)
        vim.notify("Filled " .. #variants .. " (Entity, Column) pairs!", vim.log.levels.INFO)
    else
        vim.notify("Could not parse variants.", vim.log.levels.WARN)
    end

end, { desc = "Fill (Entity, Column) pairs from LSP" })

vim.keymap.set("n", "<leader>se", "<cmd>Telescope lsp_document_symbols<cr>", { desc = "Document Symbols"})
vim.keymap.set("n", "<leader>sE", "<cmd>Telescope current_buffer_fuzzy_find<cr>", { desc = "Buffer Find"})
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], {desc = "Exit Terminal Mode"})

local is_windows = vim.fn.has("win32") == 1

local shell = is_windows and "powershell.exe" or "bash"
local desc = is_windows and "Open PowerShell Terminal" or "Open Bash Terminal"

vim.keymap.set("n", "<leader>tt", "<cmd>terminal " .. shell .. "<cr>", { desc = desc })


-- Shared helper to query LSP and parse a struct's fields
local function get_struct_fields()
    local win = vim.api.nvim_get_current_win()
    local cword = vim.fn.expand("<cword>")

    local clients = vim.lsp.get_clients({ bufnr = 0, name = "rust-analyzer" })
    if #clients == 0 then clients = vim.lsp.get_clients({ bufnr = 0 }) end

    local encoding = clients[1] and clients[1].offset_encoding or "utf-16"
    local params = vim.lsp.util.make_position_params(win, encoding)
    local responses = vim.lsp.buf_request_sync(0, "textDocument/definition", params, 2000)
    if not responses or vim.tbl_isempty(responses) then
        vim.notify("No LSP definition found", vim.log.levels.WARN)
        return nil, nil
    end

    local result
    for _, resp in pairs(responses) do
        if resp.result and not vim.tbl_isempty(resp.result) then
            result = resp.result[1] or resp.result
            break
        end
    end

    if not result then return nil, nil end

    local uri = result.uri or result.targetUri
    local bufnr = vim.uri_to_bufnr(uri)
    vim.fn.bufload(bufnr)
    local start_line = (result.range or result.targetSelectionRange).start.line
    -- Read 50 lines down from the struct definition
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, start_line + 50, false)
    
    local fields = {}
    local inside_struct = false
    for _, l in ipairs(lines) do
        if l:match("struct%s+" .. cword) then
            inside_struct = true
        elseif inside_struct and l:match("^%s*}") then
            break
        elseif inside_struct then
            local line_clean = l:gsub("^%s*", ""):gsub("%s*//.*$", "") -- Trim and remove comments
            if not line_clean:match("^#") and line_clean ~= "" then
                -- Strip out visibility modifiers like pub, pub(crate), pub(in self)
                local standard_line = line_clean:gsub("^pub%s*%b()%s*", ""):gsub("^pub%s*", "")
                local f_name, f_type = standard_line:match("^([%w_]+)%s*:%s*(.+)$")
                if f_name then
                    f_type = f_type:gsub(",%s*$", "") -- Strip trailing comma
                    local is_option = f_type:match("Option%s*<") ~= nil
                    table.insert(fields, { name = f_name, is_option = is_option })
                end
            end
        end
    end
    return cword, fields
end

-- 1. Builder Generation (<leader>rb)
vim.keymap.set("n", "<leader>rb", function()
    local cword, fields = get_struct_fields()
    if not fields or #fields == 0 then
        vim.notify("Could not parse struct fields.", vim.log.levels.WARN)
        return
    end

    -- bon uses StructName::builder() for associated builders
    local lines_to_insert = { cword .. "::builder()" }
    for _, f in ipairs(fields) do
        if f.is_option then
            table.insert(lines_to_insert, "    ." .. f.name .. "(Some(" .. f.name .. "))")
        else
            table.insert(lines_to_insert, "    ." .. f.name .. "(" .. f.name .. ")")
        end
    end
    table.insert(lines_to_insert, "    .build()")

    local r = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, r - 1, r, false, lines_to_insert)
    
    -- Format the inserted block
    vim.api.nvim_win_set_cursor(0, { r, 0 })
    vim.cmd("normal! =" .. #lines_to_insert .. "_")
    vim.notify("Generated builder for " .. cword, vim.log.levels.INFO)
end, { desc = "Generate bon::Builder implementation" })


-- 2. Dissolve Generation (<leader>rd) [Updated for multi-line layout]
vim.keymap.set("n", "<leader>rd", function()
    local cword, fields = get_struct_fields()
    if not fields or #fields == 0 then
        vim.notify("Could not parse struct fields.", vim.log.levels.WARN)
        return
    end

    -- Intelligently guess the instance variable name by converting PascalCase to snake_case
    local instance_name = cword:gsub("([a-z0-9])([A-Z])", "%1_%2"):lower()
    
    -- Build the multi-line destructuring statement
    local lines_to_insert = { "let (" }
    for _, f in ipairs(fields) do
        table.insert(lines_to_insert, "    " .. f.name .. ",")
    end
    table.insert(lines_to_insert, ") = " .. instance_name .. ".dissolve();")

    local r = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, r - 1, r, false, lines_to_insert)
    
    -- Format the entire newly inserted block
    vim.api.nvim_win_set_cursor(0, { r, 0 })
    vim.cmd("normal! =" .. #lines_to_insert .. "_")
    vim.notify("Generated multi-line dissolve for " .. cword, vim.log.levels.INFO)
end, { desc = "Generate bon dissolve destructuring (multi-line)" })



local function trash_current_file()
  local file = vim.api.nvim_buf_get_name(0)

  if file == "" then
    vim.notify("No file name for current buffer", vim.log.levels.WARN)
    return
  end

  if vim.bo.modified then
    vim.notify("Buffer has unsaved changes. Save first.", vim.log.levels.WARN)
    return
  end

  local confirm = vim.fn.confirm(
    "Move this file to local trash?",
    "&Yes\n&No",
    2
  )

  if confirm ~= 1 then
    return
  end

  local trash_dir = vim.fn.stdpath("state") .. "/trash"
  vim.fn.mkdir(trash_dir, "p")

  local name = vim.fn.fnamemodify(file, ":t")
  local ts = os.date("%Y%m%d-%H%M%S")
  local dest = trash_dir .. "/" .. ts .. "-" .. name

  local ok, err = pcall(vim.fn.rename, file, dest)
  if not ok or err ~= 0 then
    vim.notify("Failed to move file to trash", vim.log.levels.ERROR)
    return
  end

  vim.cmd("bd!")
  vim.notify("Moved to trash: " .. dest, vim.log.levels.INFO)
end

vim.keymap.set("n", "<leader>qD", trash_current_file, { desc = "Trash current file and quit" })

vim.keymap.set("n", "<leader>fa", "<cmd>FlutterAttach --dart-define-from-file=env.dev.json<cr>", { desc = "Flutter Attach With Env"})


vim.keymap.set("n", "<leader>cA", "<cmd>RustOrganizeImports<cr>", {desc = "Source Code Action Rust Organize Imports", remap = true})


vim.keymap.set("n", "<leader>kv", function()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("No file in current buffer", vim.log.levels.WARN)
    return
  end

  local line = vim.api.nvim_win_get_cursor(0)[1]
  local cwd = vim.fn.getcwd()

  vim.system({
    "ghostty",
    "--working-directory=" .. cwd,
    "-e", "nvim",
    -- Notice we removed -M entirely here because your autocmd handles it better!
    "-R",
    "+" .. tostring(line),
    file
  }, {
    detach = true,
    env = { READONLY_MODE = "1" } -- This triggers your awesome autocmd!
  })
end, { desc = "Open current file in strict read-only Ghostty at cursor position" })


-- Command to delete all custom marks (a-z and A-Z) across all buffers
vim.api.nvim_create_user_command("ClearMarks", function()
  -- 1. Delete all global uppercase marks (A-Z)
  for i = string.byte("A"), string.byte("Z") do
    pcall(vim.api.nvim_del_mark, string.char(i))
  end

  -- 2. Delete all buffer-local lowercase marks (a-z) in active buffers
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      for i = string.byte("a"), string.byte("z") do
        pcall(vim.api.nvim_buf_del_mark, buf, string.char(i))
      end
    end
  end

  -- 3. Force overwrite the ShaDa file so marks don't return on next restart
pcall(function()
  vim.cmd("wshada!")
end)

  vim.notify("All custom marks (a-z, A-Z) cleared!", vim.log.levels.INFO)
end, { desc = "Clear all custom marks and update ShaDa" })

-- Optional: map it to a shortcut
vim.keymap.set("n", "<leader>mD", "<cmd>ClearMarks<CR>", { desc = "Delete all custom marks" })


vim.keymap.set("n", "<leader>ra", function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]
  local line = vim.api.nvim_get_current_line()

  -- 1. Get active rust-analyzer LSP client
  local get_clients = vim.lsp.get_clients
  local clients = get_clients({ bufnr = 0, name = "rust-analyzer" })
  local client = clients[1] or get_clients({ bufnr = 0 })[1]
  if not client then
    vim.notify("No active LSP client found for buffer", vim.log.levels.WARN)
    return
  end
  local encoding = client.offset_encoding or "utf-16"

  local function extract_location(res)
    if not res then return nil end
    if vim.islist(res) then
      for _, item in ipairs(res) do
        if item.uri or item.targetUri then return item end
      end
      return nil
    end
    if type(res) == "table" and (res.uri or res.targetUri) then
      return res
    end
    return nil
  end

  local function query_lsp(method, p)
    local results = vim.lsp.buf_request_sync(0, method, p, 2000)
    if not results then return nil end
    for _, client_res in pairs(results) do
      local loc = extract_location(client_res.result)
      if loc then return loc end
    end
    return nil
  end

  local location = nil

  -- 2. Priority: Scan the statement for Turbofish ::<CustomType> or : CustomType
  local cur_row = row + 1
  local max_row = math.min(vim.api.nvim_buf_line_count(0), cur_row + 15)
  local ignored_types = { Result = true, Option = true, Some = true, Ok = true, Err = true, Vec = true, HashMap = true, Arc = true, Box = true }

  for r = cur_row, max_row do
    local l = vim.api.nvim_buf_get_lines(0, r - 1, r, false)[1] or ""
    -- Matches ::<ArticleStatsCacheMap or <ArticleStatsCacheMap or : ArticleStatsCacheMap
    local type_name = l:match("::%s*<%s*([A-Z][%w_]*)")
      or l:match("<%s*([A-Z][%w_]*)")
      or l:match(":%s*([A-Z][%w_]*)")

    if type_name and not ignored_types[type_name] then
      local match_col = l:find(type_name, 1, true)
      if match_col then
        local type_params = vim.lsp.util.make_position_params(0, encoding)
        type_params.position.line = r - 1
        type_params.position.character = match_col - 1
        location = query_lsp("textDocument/definition", type_params)
        if location then break end
      end
    end
    if l:find(";") then break end
  end

  -- 3. If no turbofish was found, query typeDefinition directly on the variable at cursor
  if not location then
    local params = vim.lsp.util.make_position_params(0, encoding)
    location = query_lsp("textDocument/typeDefinition", params)
  end

  -- 4. If still nothing and .dissolve() is present, query right before .dissolve()
  if not location then
    for r = cur_row, max_row do
      local l = vim.api.nvim_buf_get_lines(0, r - 1, r, false)[1] or ""
      local dis_pos = l:find("%.dissolve%s*%(")
      if dis_pos and dis_pos > 1 then
        local prev_idx = l:sub(1, dis_pos - 1):match(".*()%S")
        if prev_idx then
          local dis_params = vim.lsp.util.make_position_params(0, encoding)
          dis_params.position.line = r - 1
          dis_params.position.character = prev_idx - 1
          location = query_lsp("textDocument/typeDefinition", dis_params)
          if location then break end
        end
      end
      if l:find(";") then break end
    end
  end

  if not location then
    vim.notify("Could not find struct definition", vim.log.levels.WARN)
    return
  end

  -- 5. Read struct definition
  local uri = location.targetUri or location.uri
  local range = location.targetSelectionRange or location.targetRange or location.range
  if not uri or not range then
    vim.notify("Location missing URI or range", vim.log.levels.WARN)
    return
  end

  local fname = vim.uri_to_fname(uri)
  local bufnr = vim.fn.bufadd(fname)
  vim.fn.bufload(bufnr)
  local all_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- 6. Parse fields
  local start_line = range.start.line
  local fields = {}
  local inside_struct = false
  local depth = 0

  for i = start_line + 1, #all_lines do
    local l = all_lines[i]
    if not inside_struct then
      if l:find("{") then
        inside_struct = true
        depth = depth + select(2, l:gsub("{", "")) - select(2, l:gsub("}", ""))
      end
    else
      depth = depth + select(2, l:gsub("{", "")) - select(2, l:gsub("}", ""))
      if depth <= 0 then break end

      local clean = l:gsub("^%s*pub%b()%s*", ""):gsub("^%s*pub%s*", ""):gsub("^%s*", "")
      local field = clean:match("^([%w_]+)%s*:")
      if field and field ~= "pub" then
        table.insert(fields, field)
      end
    end
  end

  if #fields == 0 then
    vim.notify("No fields found in struct definition", vim.log.levels.WARN)
    return
  end

  -- 7. Format replacement with indentation
  local indent_len = vim.fn.indent(row + 1)
  local base_indent = string.rep(" ", indent_len)
  local shift = vim.bo.shiftwidth > 0 and vim.bo.shiftwidth or 4
  local field_indent = base_indent .. string.rep(" ", shift)

  -- Replace whatever is between "let " and "="
  local before, after
  local let_start, let_end = line:find("let%s+")
  local eq_pos = line:find("=", (let_end or 0) + 1)

  if let_end and eq_pos then
    before = line:sub(1, let_end)
    after = line:sub(eq_pos)
  else
    local left = line:sub(1, col + 1)
    local start_idx = left:match(".*()[%s%p]")
    start_idx = start_idx and (start_idx + 1) or 1
    local right = line:sub(start_idx)
    local word = right:match("^([%w_]+)") or ""
    local end_idx = start_idx + #word - 1
    before = line:sub(1, start_idx - 1)
    after = line:sub(end_idx + 1)
  end

  local new_lines = {}
  table.insert(new_lines, before .. "(")
  for _, f in ipairs(fields) do
    table.insert(new_lines, field_indent .. f .. ",")
  end
  table.insert(new_lines, base_indent .. ") " .. after)

  vim.api.nvim_buf_set_lines(0, row, row + 1, false, new_lines)
end, { desc = "Destructure variable to multiline tuple (.dissolve)" })







-- ====================================================================
-- Interactive Global Macro (:Gconfirm & <leader>gq)
-- ====================================================================

local function run_interactive_macro(line1, line2, pattern, reg)
  reg = (reg and reg ~= "") and reg or "q"
  local cmd = string.format(
    "%d,%dg/%s/redraw | if confirm(getline('.'), \"&Yes\\n&No\") == 1 | exe \"norm @%s\" | endif",
    line1,
    line2,
    pattern,
    reg
  )
  vim.cmd(cmd)
end

-- 1. Custom Command: :'<,'>Gconfirm <pattern> [register]
vim.api.nvim_create_user_command("Gconfirm", function(opts)
  local raw_args = vim.trim(opts.args)
  if raw_args == "" then
    vim.notify("Usage: :Gconfirm <pattern> [register]", vim.log.levels.ERROR)
    return
  end

  -- Checks if the last word is a single-letter register (e.g. :Gconfirm pattern a)
  local pattern, reg = raw_args:match("^(.-)%s+(%a)$")
  if not pattern then
    pattern = raw_args
    reg = "q"
  end

  run_interactive_macro(opts.line1, opts.line2, pattern, reg)
end, {
  range = "%", -- Defaults to whole file if no visual range selected
  nargs = "+",
  desc = "Run macro globally with confirmation",
})

-- 2. Visual / Normal Mode Keymap: <leader>gq (Uses LazyVim floating prompts)
vim.keymap.set({ "n", "v" }, "<leader>rh", function()
  local is_visual = vim.fn.mode():match("[vV\22]")
  local line1, line2

  if is_visual then
    line1 = vim.fn.line("v")
    line2 = vim.fn.line(".")
    if line1 > line2 then line1, line2 = line2, line1 end
    -- Exit visual mode
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
  else
    line1 = 1
    line2 = vim.fn.line("$")
  end

  -- Prompt 1: Pattern (pre-fills word under cursor)
  vim.ui.input({
    prompt = "Pattern to match: ",
    default = vim.fn.expand("<cword>"),
  }, function(pattern)
    if not pattern or pattern == "" then return end

    -- Prompt 2: Macro register (defaults to 'q')
    vim.ui.input({
      prompt = "Macro register (default 'q'): ",
      default = "q",
    }, function(reg)
      run_interactive_macro(line1, line2, pattern, reg)
    end)
  end)
end, { desc = "Interactive Global Macro" })
