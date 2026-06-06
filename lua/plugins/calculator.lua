return {
	{
		"necrom4/calcium.nvim",
		cmd = { "Calcium" },
		opts = {
			-- default configuration
			notifications = true,                 -- notify result
			default_mode = "append",              -- or `replace` the expression
			scratchpad = {
				border = "rounded",               -- floating window border style (:help 'winborder')
				virtual_text = {
					format = "= %s",              -- virtual text format
					highlight_group = "Comment",  -- virtual text highlight group
				},
				result_variable = "ans"           -- name of the variable for the last computation result
			},
		},
		keys = {
			-- example keymap
			{
				"<leader>k",
				":Calcium<CR>",
				desc = "Calculate",
				mode = { "n", "v" },
				silent = true,
			},
		}
	},
	{
		"necrom4/convy.nvim",
		cmd = { "Convy", "ConvySeparator" },
		opts = {
			-- default configuration
			notifications = true,
			separator = " ",
			window = {
				position = "left", -- "left" or "right"
				width = 36,
			},
		},
		keys = {
			-- example keymaps
			{
				"<leader>kc",
				":Convy<CR>",
				desc = "Convert (interactive selection)",
				mode = { "n", "v" },
				silent = true,
			},
			{
				"<leader>kd",
				":Convy auto dec<CR>",
				desc = "Convert to decimal",
				mode = { "n", "v" },
				silent = true,
			},
			{
				"<leader>ks",
				":ConvySeparator<CR>",
				desc = "Set conversion separator (visual selection)",
				mode = { "v" },
				silent = true,
			},
		}
	}
}
