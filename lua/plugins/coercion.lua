local M = {}

-- Splits a string into lowercase tokens based on caps, dashes, underscores, and dots
local function tokenize(str)
  local s = str:gsub("([^%u%s%-_%.])(%u)", "%1 %2")
               :gsub("(%u)(%u%l)", "%1 %2")
               :gsub("[%-_%.]", " ")
  local tokens = {}
  for word in s:gmatch("%S+") do
    table.insert(tokens, word:lower())
  end
  return tokens
end

-- Case formatters
local formatters = {
  s = function(tokens) return table.concat(tokens, "_") end,
  l = function(_, cword) return cword:lower() end,
  u = function(tokens) return table.concat(tokens, "_"):upper() end,
  ["-"] = function(tokens) return table.concat(tokens, "-") end,
  ["."] = function(tokens) return table.concat(tokens, ".") end,
  c = function(tokens)
    if #tokens == 0 then return "" end
    local res = tokens[1]
    for i = 2, #tokens do
      res = res .. tokens[i]:gsub("^%l", string.upper)
    end
    return res
  end,
  m = function(tokens)
    local res = ""
    for i = 1, #tokens do
      res = res .. tokens[i]:gsub("^%l", string.upper)
    end
    return res
  end,
}

function M.coerce(case_mode)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local cursor_byte = col + 1

  local start_idx, end_idx
  local start_search = 1
  while true do
    local s, e = line:find("[%w_%.%-]+", start_search)
    if not s then break end
    if cursor_byte >= s and cursor_byte <= e then
      start_idx, end_idx = s, e
      break
    end
    start_search = e + 1
  end

  if not start_idx then return end

  local cword = line:sub(start_idx, end_idx)
  local tokens = tokenize(cword)
  if #tokens == 0 then return end

  local formatter = formatters[case_mode]
  if not formatter then return end

  local new_word = formatter(tokens, cword)
  if new_word == cword then return end

  vim.api.nvim_buf_set_text(0, row - 1, start_idx - 1, row - 1, end_idx, { new_word })

  local relative_offset = cursor_byte - start_idx
  local new_col = start_idx - 1 + math.min(relative_offset, math.max(0, #new_word - 1))
  vim.api.nvim_win_set_cursor(0, { row, new_col })
end

-- Return a valid lazy.nvim plugin specTest
return {
  "custom-coercion",
  dir = vim.fn.stdpath("config"),
  
  -- 1. Defining 'keys' tells lazy.nvim to lazy-load this plugin module
  keys = {
    { "crs", function() M.coerce("s") end, desc = "Snake Case" },
    { "crc", function() M.coerce("c") end, desc = "Camel Case" },
    { "crm", function() M.coerce("m") end, desc = "Pascal Case" },
    { "cru", function() M.coerce("u") end, desc = "Upper Case" },
    { "crl", function() M.coerce("l") end, desc = "Lower Case" },
    { "cr-", function() M.coerce("-") end, desc = "Kebab Case" },
    { "cr.", function() M.coerce(".") end, desc = "Dot Case" },
  },

  -- 2. 'init' runs on startup. We use it to label the prefix group in which-key
  -- without triggering the actual plugin to load.
  init = function()
    pcall(function()
      require("which-key").add({
        { "cr", group = "Coerce Case", mode = "n" },
      })
    end)
  end,

  -- 3. We no longer need a 'config' function because lazy.nvim handles 
  -- binding the keys automatically when the plugin loads.
}
