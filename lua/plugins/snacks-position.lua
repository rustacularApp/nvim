return {
	{
		"snacks.nvim",
		opts = {
			picker = {
				layout = {
					preset = "telescope"
				},
				layouts = {
					telescope = {
						reverse = true
					}
				},
				sources = {
					files = {
						hidden = true
					},
					explorer = {
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
