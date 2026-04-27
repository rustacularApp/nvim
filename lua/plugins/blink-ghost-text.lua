return {
	{
		'saghen/blink.cmp',
		opts = {
			completion = {
				ghost_text = { enabled = false },
				list = {
					max_items = 15,
					selection = {
						preselect = true,
						auto_insert = true
					}
				},
				menu = {
					draw = {
						columns = {
							{
								"label", "label_description", gap = 1
							},
							{
								"kind_icon", "kind"
							}
						}
					}
				},
			},
			sources = {
				per_filetype = {
					rust = { "lsp", "path", "snippets" }
				}
			}
		}
	}
}
