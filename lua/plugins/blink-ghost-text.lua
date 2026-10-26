return {
	{
		"saghen/blink.cmp",
		opts = {
			keymap = {
				preset = "super-tab",
				["<Tab>"] = { "select_and_accept", "fallback" },
				["<S-Tab>"] = { "select_prev", "fallback" },
				["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
			},
			completion = {
				ghost_text = { enabled = false },
				list = {
					max_items = 20,
					selection = {
						preselect = true,
						auto_insert = true,
					},
				},
				menu = {
					draw = {
						columns = {
							{ "label", "label_description", gap = 1 },
							{ "kind_icon", "kind" },
						},
					},
				},
			},
			sources = {
				per_filetype = {
					rust = { "lsp", "path", "snippets" },
				},
			},
		},
	},
}
