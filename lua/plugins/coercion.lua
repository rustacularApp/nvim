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
	l = function (_, cword)
		return cword:lower()
	end,
	u = function(tokens) return table.concat(tokens, "_"):upper() end,
	["-"] = function(tokens) return table.concat(tokens, "-") end,
	["."] = function (tokens)
		return table.concat(tokens, ".")
	end,
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
  local row, col = unpack(vim.api.nvim_win_get_cursor(0)) -- row is 1-indexed, col is 0-indexed
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

-- This is some exaple-time
-- Return a valid lazy.nvim plugin spec
return {
	"custom-coercion",
	dir = vim.fn.stdpath("config"),
	config = function()
		local maps = {
			crs = { mode = "s", label = "snake" },
			crc = { mode = "c", label = "camel" },
			crm = { mode = "m", label = "pascal" },
			cru = { mode = "u", label = "UPPER" },
			crl = { mode = "l", label = "lower" },
			["cr-"] = { mode = "-", label = "kebab" },
			["cr."] = { mode = ".", label = "dot"}
		}

		-- 1. Bind native Neovim keymaps
		for key, info in pairs(maps) do
			vim.keymap.set("n", key, function() M.coerce(info.mode) end, {
				desc = "Coerce to " .. info.label .. "_case",
				silent = true,
			})
		end

		-- 2. Force which-key to display the menu immediately over the native 'c' operator
		pcall(function()
			require("which-key").add({
				{ "cr", group = "Coerce Case" , mode = "n" },
				{ "crs", desc = "Snake Case" , mode = "n" },
				{ "crc", desc = "Camel Case" , mode = "n" },
				{ "crm", desc = "Pascal Case" , mode = "n" },
				{ "cru", desc = "Upper Case" , mode = "n" },
				{ "crl", desc = "Lower Case" , mode = "n" },
				{ "cr-", desc = "Kebab Case" , mode = "n" },
				{ "cr.", desc = "Dot Case", mode = "n" },
				-- Operator-pending layout
				{ "r", group = "Coerce Case" , mode = "o" },
				{ "rs", desc = "Snake Case" , mode = "o" },
				{ "rc", desc = "Camel Case" , mode = "o" },
				{ "rm", desc = "Pascal Case" , mode = "o" },
				{ "ru", desc = "Upper Case" , mode = "o" },
				{ "rl", desc = "Lower Case" , mode = "o" },
				{ "r-", desc = "Kebab Case" , mode = "o" },
				{ "r.", desc = "Dot Case", mode = "o" },
			})
		end)
	end,
}
