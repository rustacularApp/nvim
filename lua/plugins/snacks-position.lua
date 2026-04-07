return {
	{
		"snacks.nvim",
		opts = {
			picker = {
				sources = {
					explorer = {
						auto_close = true,
						jump = { close = true },
						layout = {
							preview = true, -- enable preview
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
						keys = {
							{
								"<leader>e",
								function() require("snacks").explorer() end,
								desc = "Snacks: Explorer",
							},
						},
					},
				},
			},
		},
	},
}
