-- Helper functions to fetch edited lines from the Vim changelist success?
local function get_local_changes()
	local bufnr = vim.api.nvim_get_current_buf()
	local changelist = vim.fn.getchangelist(bufnr)[1]
	if not changelist or #changelist == 0 then return {} end

	local items = {}
	local seen_lines = {}
	local line_count = vim.api.nvim_buf_line_count(bufnr)

	-- Traverse backwards to show the most recent edits first
	for i = #changelist, 1, -1 do
		local change = changelist[i]
		local lnum = change.lnum
		local col = change.col + 1

		if lnum <= line_count and lnum > 0 then
			local line_text = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
			line_text = vim.trim(line_text)

			-- Group sequential edits on the same line together
			if not seen_lines[lnum] and line_text ~= "" then
				seen_lines[lnum] = true
				table.insert(items, {
					text = string.format("%4d │ %s", lnum, line_text),
					file = vim.api.nvim_buf_get_name(bufnr),
					pos = { lnum, col },
				})
			end
		end
	end
	return items
end

local function get_global_changes()
	local items = {}
	local bufs = vim.api.nvim_list_bufs()

	for _, bufnr in ipairs(bufs) do
		if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buftype == "" then
			local file_name = vim.api.nvim_buf_get_name(bufnr)
			local changelist = vim.fn.getchangelist(bufnr)[1]

			if file_name ~= "" and changelist and #changelist > 0 then
				local line_count = vim.api.nvim_buf_line_count(bufnr)
				local seen_lines = {}
				local short_name = vim.fn.fnamemodify(file_name, ":t")

				for i = #changelist, 1, -1 do
					local change = changelist[i]
					local lnum = change.lnum
					local col = change.col + 1

					if lnum <= line_count and lnum > 0 then
						local line_text = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
						line_text = vim.trim(line_text)

						if not seen_lines[lnum] and line_text ~= "" then
							seen_lines[lnum] = true
							table.insert(items, {
								-- Prepends the file name so you know where you're jumping
								text = string.format("%-15s │ %4d │ %s", short_name, lnum, line_text),
								file = file_name,
								pos = { lnum, col },
							})
						end
					end
				end
			end
		end
	end
	return items
end

return {
	{
		"snacks.nvim",
		-- Registering keymaps directly inside the lazy spec block
		keys = {
			{
				"<leader>ch",
				function()
					local items = get_local_changes()
					if #items == 0 then return vim.notify("No recent edits in this file", vim.log.levels.WARN) end
					Snacks.picker.pick({
						title = "Local Buffer Edits",
						items = items,
						format = "text",
					})
				end,
				desc = "Picker: Local Edits (Small variant)",
			},
			{
				"<leader>ff", LazyVim.pick("files", { root = false }), desc = "Find Files (cwd)"
			},
			{
				"<leader>fF", LazyVim.pick("files"), desc = "Find Files (Root Dir)"
			},
			{
				"<leader>cH",
				function()
					local items = get_global_changes()
					if #items == 0 then return vim.notify("No recent edits found across buffers", vim.log.levels.WARN) end
					Snacks.picker.pick({
						title = "Global Project Edits",
						items = items,
						format = "text",
					})
				end,
				desc = "Picker: Global Edits (Capital variant)",
			},
		},
		opts = {
			picker = {
				layout = {
					preset = "telescope",
				},
				layouts = {
					telescope = {
						reverse = true,
					},
				},
				sources = {
					files = {
						hidden = true,
					},
					explorer = {
						win = {
							list = {
								keys = {
									["Y"] = "yank_relative_cwd"
								}
							}
						},
						actions = {
							yank_relative_cwd = function (_, item)
								local rel = vim.fn.fnamemodify(item.file, ":.")
								vim.fn.setreg('"', rel)
								vim.fn.setreg("+", rel)
								vim.notify("Copied relative path: " .. rel)
							end
						},
						auto_close = true,
						jump = { close = true },
						layout = {
							preview = true,
							layout = {
								box = "horizontal",
								width = 0.8,
								height = 0.8,
								{
									box = "vertical",
									border = "rounded",
									title = "{source} {live} {flags}",
									width = 0.5,
									title_pos = "center",
									{ win = "input", height = 1, border = "bottom" },
									{ win = "list", border = "none" },
								},
								{
									win = "preview",
									border = "rounded",
									width = 0.5,
									title = "{preview}",
								},
							},
						},
					},
				},
			},
		},
	},
}
