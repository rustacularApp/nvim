return {
	{
		'saghen/blink.cmp',
		opts = {
			completion = {
				ghost_text = { enabled = false }, -- This stops the "out of range" extmark crashes
				trigger = {
					prefetch_on_insert = true,
					show_delay_ms = 60
				},
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
